import '../core/enums/chat_enums.dart';
import '../model/chat_message.dart';
import '../model/chat_user.dart';

/// Immutable snapshot of everything the chat UI needs to render at a
/// point in time. [ChatController] emits a new [ChatState] on every
/// change via its `Stream<ChatState>` — this is the *only* contract the
/// UI layer depends on, which is what makes the package state-management
/// agnostic. GetX can wrap the stream in `.obs`, Riverpod in a
/// `StreamProvider`, Bloc in a `StreamSubscription` inside a Cubit, or a
/// plain `StreamBuilder` for `setState`-based apps — the package doesn't
/// care.
class ChatState {
  final List<ChatMessage> messages;
  final Map<String, ChatUser> typingUsers;
  final ChatConnectionState connectionState;
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final String? loadError;

  const ChatState({
    this.messages = const [],
    this.typingUsers = const {},
    this.connectionState = ChatConnectionState.online,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.loadError,
  });

  bool get isEmpty => messages.isEmpty;
  bool get isTyping => typingUsers.isNotEmpty;

  ChatState copyWith({
    List<ChatMessage>? messages,
    Map<String, ChatUser>? typingUsers,
    ChatConnectionState? connectionState,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    String? loadError,
    bool clearLoadError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      typingUsers: typingUsers ?? this.typingUsers,
      connectionState: connectionState ?? this.connectionState,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
    );
  }
}
