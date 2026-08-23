import 'package:advanced_chat_kit/advanced_chat_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/demo_data.dart';

/// How to bind [ChatController]'s `Stream<ChatState>` to Riverpod.
///
/// [ChatController] itself is framework-agnostic plain Dart, so it's
/// exposed through a plain `Provider` — only its *stream of state* needs
/// a Riverpod wrapper, via `StreamProvider`.
final chatControllerProvider = Provider.autoDispose<ChatController>((ref) {
  final controller = ChatController(currentUserId: DemoData.currentUserId)
    ..addIncomingMessage(DemoData.seedMessages().first);

  // autoDispose + ref.onDispose is Riverpod's lifecycle hook — this is
  // where ChatController.dispose() belongs (doc section 27, lifecycle
  // safety), mirroring GetxController.onClose in the GetX example.
  ref.onDispose(controller.dispose);
  return controller;
});

final chatStateProvider = StreamProvider.autoDispose<ChatState>((ref) {
  final controller = ref.watch(chatControllerProvider);
  return controller.stream;
});

class RiverpodChatScreen extends ConsumerWidget {
  const RiverpodChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `ChatView` manages its own subscription to `controller.stream`
    // internally, so this screen doesn't actually need to `watch`
    // `chatStateProvider` just to render `ChatView` — the provider above
    // is there for any *other* Riverpod-driven widget on the same screen
    // (an unread-count badge, a custom header) that wants the same
    // `ChatState` without re-deriving it.
    final controller = ref.watch(chatControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(DemoData.otherUser.name)),
      body: ChatView(
        controller: controller,
        theme: DemoData.theme(),
        userResolver: DemoData.resolveUser,
        onSendText: (text) => controller.addOutgoingMessage(
          ChatMessage(
            id: 'riverpod_${DateTime.now().microsecondsSinceEpoch}',
            senderId: controller.currentUserId,
            type: ChatMessageType.text,
            text: text,
            createdAt: DateTime.now(),
          ),
        ),
      ),
    );
  }
}
