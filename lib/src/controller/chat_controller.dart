import 'dart:async';

import '../core/enums/chat_enums.dart';
import '../model/chat_message.dart';
import '../model/chat_reaction.dart';
import '../model/chat_user.dart';
import 'chat_state.dart';

/// Cursor-based pagination callback. Return the older page of messages for
/// the given [cursor] (null on first call), or an empty list when there's
/// nothing left to load.
typedef LoadMoreMessages = Future<List<ChatMessage>> Function(String? cursor);

/// The framework-agnostic brain of a single conversation.
///
/// This is plain Dart — no GetxController, no ChangeNotifier, no
/// StateNotifier. It owns an ordered [List<ChatMessage>] plus a
/// `Map<String, int>` index so that lookup/update/delete-by-id are O(1)
/// average instead of an O(n) `firstWhere` scan on every socket event
/// (see SDK performance/DSA requirements).
///
/// The host application binds [stream] to whatever state management it
/// uses:
///
/// ```dart
/// // GetX
/// final _state = ChatController(...).stream.obs; // via StreamController pattern
///
/// // Riverpod
/// final chatStateProvider = StreamProvider((ref) => controller.stream);
///
/// // Bloc/Cubit
/// _subscription = controller.stream.listen((s) => emit(s));
///
/// // setState
/// StreamBuilder<ChatState>(stream: controller.stream, builder: ...)
/// ```
class ChatController {
  ChatController({
    required this.currentUserId,
    this.conversationId,
    this.type = ChatType.single,
    this.onLoadMoreMessages,
    int pageSize = 30,
  }) : _pageSize = pageSize {
    _emit();
  }

  final String currentUserId;
  final String? conversationId;
  final ChatType type;
  final LoadMoreMessages? onLoadMoreMessages;
  final int _pageSize;

  final List<ChatMessage> _messages = [];
  final Map<String, int> _messageIndex = {};
  final Map<String, ChatUser> _typingUsers = {};

  ChatConnectionState _connectionState = ChatConnectionState.online;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  String? _loadError;
  String? _nextCursor;
  Timer? _typingClearTimer;

  final StreamController<ChatState> _controller = StreamController<ChatState>.broadcast();

  /// Emits a new [ChatState] every time anything about the conversation
  /// changes. This is the single integration point for any state
  /// management library.
  Stream<ChatState> get stream => _controller.stream;

  /// Convenience synchronous snapshot, useful for initial widget builds
  /// before the first stream event, or for GetX `.obs` seeding.
  ChatState get currentState => _buildState();

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  // ---------------------------------------------------------------------
  // Outgoing messages
  // ---------------------------------------------------------------------

  /// Appends a locally-created message (status: [ChatMessageStatus.sending])
  /// so the UI reflects it instantly, before the host app's socket/API
  /// round-trip completes. Call [updateMessageStatus] once the host app's
  /// `onSendMessage` callback confirms delivery.
  void addOutgoingMessage(ChatMessage message) {
    _insertMessage(message);
  }

  /// Pushes a message that arrived from the host app's socket/API layer
  /// (i.e. not authored locally) into the conversation.
  void addIncomingMessage(ChatMessage message) {
    _insertMessage(message);
  }

  void _insertMessage(ChatMessage message) {
    if (_messageIndex.containsKey(message.id)) {
      // Duplicate delivery (common with at-least-once socket semantics) —
      // update in place instead of creating a second bubble.
      updateMessage(message);
      return;
    }
    _messages.add(message);
    _messageIndex[message.id] = _messages.length - 1;
    _emit();
  }

  // ---------------------------------------------------------------------
  // O(1) average lookup / update / delete
  // ---------------------------------------------------------------------

  ChatMessage? messageById(String id) {
    final index = _messageIndex[id];
    if (index == null) return null;
    return _messages[index];
  }

  void updateMessage(ChatMessage updated) {
    final index = _messageIndex[updated.id];
    if (index == null) return;
    _messages[index] = updated;
    _emit();
  }

  void updateMessageStatus(String messageId, ChatMessageStatus status) {
    final index = _messageIndex[messageId];
    if (index == null) return;
    _messages[index] = _messages[index].copyWith(status: status);
    _emit();
  }

  void editMessage(String messageId, String newText) {
    final index = _messageIndex[messageId];
    if (index == null) return;
    _messages[index] = _messages[index].copyWith(
      text: newText,
      editedAt: DateTime.now(),
    );
    _emit();
  }

  /// Soft-deletes by default (keeps the tombstone so "message deleted" can
  /// render); pass [hard] to remove it from the list entirely.
  void deleteMessage(String messageId, {bool hard = false}) {
    final index = _messageIndex[messageId];
    if (index == null) return;
    if (hard) {
      _messages.removeAt(index);
      _rebuildIndex();
    } else {
      _messages[index] = _messages[index].copyWith(isDeleted: true, text: null, attachments: const []);
    }
    _emit();
  }

  void _rebuildIndex() {
    _messageIndex.clear();
    for (var i = 0; i < _messages.length; i++) {
      _messageIndex[_messages[i].id] = i;
    }
  }

  // ---------------------------------------------------------------------
  // AI streaming (see doc section 23) — token-by-token updates without
  // rebuilding the whole conversation. All three methods reuse the same
  // O(1) indexed update every other mutation in this controller uses, so
  // streaming a long AI response is exactly as cheap per-chunk as editing
  // any other single message.
  // ---------------------------------------------------------------------

  /// Inserts a new message with [ChatMessage.isStreaming] set to `true`
  /// and (typically) empty `text` — call this the moment an AI response
  /// starts, then feed tokens in via [appendStreamingChunk] as they
  /// arrive from your model/API.
  void startStreamingMessage(ChatMessage message) {
    addIncomingMessage(message.copyWith(isStreaming: true));
  }

  /// Appends [chunk] to the message's current text. Cheap enough to call
  /// once per token: only the single affected [ChatMessage] is replaced
  /// in the index, and only that bubble's Element rebuilds — the rest of
  /// the list is untouched (doc section 19, avoid full list rebuilds).
  void appendStreamingChunk(String messageId, String chunk) {
    final index = _messageIndex[messageId];
    if (index == null) return;
    final current = _messages[index];
    _messages[index] = current.copyWith(text: (current.text ?? '') + chunk, isStreaming: true);
    _emit();
  }

  /// Marks streaming finished — clears the blinking cursor and settles
  /// the message into a normal [status] (defaults to `sent`).
  void completeStreamingMessage(String messageId, {ChatMessageStatus status = ChatMessageStatus.sent}) {
    final index = _messageIndex[messageId];
    if (index == null) return;
    _messages[index] = _messages[index].copyWith(isStreaming: false, status: status);
    _emit();
  }

  // ---------------------------------------------------------------------
  // Reactions
  // ---------------------------------------------------------------------

  void addReaction(String messageId, ChatReaction reaction) {
    final index = _messageIndex[messageId];
    if (index == null) return;
    final existing = _messages[index].reactions.where((r) => r.userId != reaction.userId);
    _messages[index] = _messages[index].copyWith(
      reactions: [...existing, reaction],
    );
    _emit();
  }

  void removeReaction(String messageId, String userId) {
    final index = _messageIndex[messageId];
    if (index == null) return;
    _messages[index] = _messages[index].copyWith(
      reactions: _messages[index].reactions.where((r) => r.userId != userId).toList(),
    );
    _emit();
  }

  // ---------------------------------------------------------------------
  // Typing indicator
  // ---------------------------------------------------------------------

  void setUserTyping(ChatUser user, {Duration autoClearAfter = const Duration(seconds: 5)}) {
    _typingUsers[user.id] = user;
    _emit();
    _typingClearTimer?.cancel();
    _typingClearTimer = Timer(autoClearAfter, () {
      _typingUsers.remove(user.id);
      _emit();
    });
  }

  void clearUserTyping(String userId) {
    _typingUsers.remove(userId);
    _emit();
  }

  // ---------------------------------------------------------------------
  // Pagination (cursor-based, see SDK performance requirements)
  // ---------------------------------------------------------------------

  Future<void> loadInitial() => loadMore();

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMoreMessages || onLoadMoreMessages == null) return;
    _isLoadingMore = true;
    _loadError = null;
    _emit();

    try {
      final older = await onLoadMoreMessages!(_nextCursor);
      if (older.isEmpty) {
        _hasMoreMessages = false;
      } else {
        // Older messages are prepended; skip any we already have.
        for (final message in older.reversed) {
          if (!_messageIndex.containsKey(message.id)) {
            _messages.insert(0, message);
          }
        }
        _rebuildIndex();
        _nextCursor = older.length < _pageSize ? null : older.last.id;
        if (older.length < _pageSize) _hasMoreMessages = false;
      }
    } catch (e) {
      _loadError = e.toString();
    } finally {
      _isLoadingMore = false;
      _emit();
    }
  }

  // ---------------------------------------------------------------------
  // Connection state (host app pushes socket connectivity in)
  // ---------------------------------------------------------------------

  void setConnectionState(ChatConnectionState state) {
    _connectionState = state;
    _emit();
  }

  // ---------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------

  ChatState _buildState() {
    return ChatState(
      messages: List.unmodifiable(_messages),
      typingUsers: Map.unmodifiable(_typingUsers),
      connectionState: _connectionState,
      isLoadingMore: _isLoadingMore,
      hasMoreMessages: _hasMoreMessages,
      loadError: _loadError,
    );
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(_buildState());
  }

  /// Must be called when the conversation screen is disposed (e.g.
  /// `GetxController.onClose`, `State.dispose`, Bloc `close`). Prevents the
  /// classic "listeners from Chat B still active while viewing Chat A"
  /// leak described in the SDK lifecycle-safety requirements.
  void dispose() {
    _typingClearTimer?.cancel();
    _controller.close();
  }
}
