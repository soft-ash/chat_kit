import 'package:advanced_chat_kit/advanced_chat_kit.dart';
import 'package:flutter/material.dart';

import '../common/demo_data.dart';

/// The simplest possible way to preview the package: no socket, no REST
/// API, no state-management library — a [ChatController] living entirely
/// in memory inside this screen's [State]. Good for quickly sanity
/// checking a theme, a custom message widget, or a layout change without
/// standing up a backend first.
///
/// `onSendText` just echoes the message straight back into the same
/// controller — swap that one callback out for a real socket/API call
/// (see `with_socket/socket_chat_screen.dart`) and everything else on
/// this screen stays identical.
class LocalPreviewScreen extends StatefulWidget {
  const LocalPreviewScreen({super.key});

  @override
  State<LocalPreviewScreen> createState() => _LocalPreviewScreenState();
}

class _LocalPreviewScreenState extends State<LocalPreviewScreen> {
  late final ChatController _controller = ChatController(
    currentUserId: DemoData.currentUserId,
    conversationId: 'local_preview',
  );

  @override
  void initState() {
    super.initState();
    for (final message in DemoData.seedMessages()) {
      _controller.addIncomingMessage(message);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSendText(String text) {
    final message = ChatMessage(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      senderId: DemoData.currentUserId,
      type: ChatMessageType.text,
      text: text,
      createdAt: DateTime.now(),
      status: ChatMessageStatus.sent,
    );
    _controller.addOutgoingMessage(message);

    // Fake a reply so the screen feels alive without any backend.
    Future.delayed(const Duration(milliseconds: 600), () {
      _controller.addIncomingMessage(
        ChatMessage(
          id: 'local_reply_${DateTime.now().microsecondsSinceEpoch}',
          senderId: DemoData.otherUser.id,
          type: ChatMessageType.text,
          text: 'Got it — "$text"',
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(DemoData.otherUser.name)),
      body: ChatView(
        controller: _controller,
        theme: DemoData.theme(),
        userResolver: DemoData.resolveUser,
        onSendText: _handleSendText,
      ),
    );
  }
}
