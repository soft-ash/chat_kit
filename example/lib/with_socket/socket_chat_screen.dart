import 'package:advanced_chat_kit/advanced_chat_kit.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../common/demo_data.dart';

/// Same [ChatView], same [ChatController] shape as
/// `no_socket/local_preview_screen.dart` — the only thing that changes is
/// *where messages come from*. This is the point: the package never knew
/// or cared whether messages arrived from a fake `Future.delayed` or a
/// real socket. Swap the transport, keep the UI.
///
/// The package itself has zero networking dependency (see doc section 16
/// — "Socket: host application"). `socket_io_client` here belongs to
/// this *example app*, not to `advanced_chat_kit`.
class SocketChatScreen extends StatefulWidget {
  final String serverUrl;

  const SocketChatScreen({super.key, required this.serverUrl});

  @override
  State<SocketChatScreen> createState() => _SocketChatScreenState();
}

class _SocketChatScreenState extends State<SocketChatScreen> {
  late final ChatController _controller = ChatController(
    currentUserId: DemoData.currentUserId,
    conversationId: 'socket_demo_room',
    // Cursor-based pagination — the package calls this, you fetch a page
    // of older messages however your backend paginates.
    onLoadMoreMessages: _fetchOlderMessages,
  );

  late final io.Socket _socket;
  ChatConnectionState _connection = ChatConnectionState.connecting;

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  void _connectSocket() {
    _socket = io.io(
      widget.serverUrl,
      io.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );

    _socket.onConnect((_) {
      _setConnectionState(ChatConnectionState.online);
      _socket.emit('join_room', {'conversationId': _controller.conversationId});
    });

    _socket.onDisconnect((_) => _setConnectionState(ChatConnectionState.offline));
    _socket.onConnectError((_) => _setConnectionState(ChatConnectionState.offline));

    // Server pushes a new message → hand it straight to the controller.
    // Nothing else on screen needs to know this happened.
    _socket.on('message:new', (data) {
      final json = Map<String, dynamic>.from(data as Map);
      _controller.addIncomingMessage(ChatMessage.fromJson(json));
    });

    // Server confirms a message we sent was persisted — flip its status
    // from `sending` to `sent` using the id we generated locally.
    _socket.on('message:ack', (data) {
      final json = Map<String, dynamic>.from(data as Map);
      final localId = json['localId'] as String?;
      if (localId != null) {
        _controller.updateMessageStatus(localId, ChatMessageStatus.sent);
      }
    });

    _socket.on('typing', (data) {
      final json = Map<String, dynamic>.from(data as Map);
      final userId = json['userId'] as String?;
      if (userId != null && userId != DemoData.currentUserId) {
        final user = DemoData.resolveUser(userId);
        if (user != null) _controller.setUserTyping(user);
      }
    });

    _socket.connect();
  }

  void _setConnectionState(ChatConnectionState state) {
    if (!mounted) return;
    setState(() => _connection = state);
    _controller.setConnectionState(state);
  }

  /// Cursor-based pagination — replace with your actual REST call
  /// (`GET /conversations/:id/messages?cursor=...`). Returning fewer
  /// than a full page (or an empty list) tells the controller there's
  /// nothing older left to load.
  Future<List<ChatMessage>> _fetchOlderMessages(String? cursor) async {
    // Illustrative only — wire this to your real HTTP client.
    await Future.delayed(const Duration(milliseconds: 300));
    return const [];
  }

  void _handleSendText(String text) {
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final message = ChatMessage(
      id: localId,
      senderId: DemoData.currentUserId,
      type: ChatMessageType.text,
      text: text,
      createdAt: DateTime.now(),
      status: ChatMessageStatus.sending,
    );

    // Optimistic UI: show it immediately as `sending`...
    _controller.addOutgoingMessage(message);

    // ...then hand the same payload to the server. `message:ack` above
    // is what flips it to `sent` once the server confirms.
    _socket.emit('message:send', {
      ...message.toJson(),
      'localId': localId,
    });
  }

  void _handleTypingChanged(bool isTyping) {
    _socket.emit('typing', {
      'userId': DemoData.currentUserId,
      'conversationId': _controller.conversationId,
      'isTyping': isTyping,
    });
  }

  @override
  void dispose() {
    _socket.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DemoData.otherUser.name),
        bottom: _connection == ChatConnectionState.online
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Container(
                  color: Colors.orange,
                  height: 24,
                  alignment: Alignment.center,
                  child: Text(
                    _connection == ChatConnectionState.connecting ? 'Connecting…' : 'Offline — reconnecting…',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
      ),
      body: ChatView(
        controller: _controller,
        theme: DemoData.theme(),
        userResolver: DemoData.resolveUser,
        onSendText: _handleSendText,
        onTypingChanged: _handleTypingChanged,
      ),
    );
  }
}
