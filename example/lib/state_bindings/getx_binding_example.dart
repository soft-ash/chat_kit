import 'package:advanced_chat_kit/advanced_chat_kit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../common/demo_data.dart';

/// How to bind [ChatController]'s `Stream<ChatState>` to GetX.
///
/// The package doesn't know GetX exists — this `GetxController` is
/// entirely example-app code. All it does is listen to the stream and
/// push each new [ChatState] into an `.obs`, so the rest of your GetX app
/// can react the way it reacts to everything else: `Obx(() => ...)`.
class ChatGetxController extends GetxController {
  ChatGetxController({required this.chatController});

  final ChatController chatController;

  /// The reactive state everything in the UI reads from.
  late final Rx<ChatState> state = chatController.currentState.obs;

  @override
  void onInit() {
    super.onInit();
    // Every ChatController emission just becomes a new `.obs` value —
    // no translation layer needed because ChatState is already an
    // immutable value type.
    chatController.stream.listen((newState) => state.value = newState);
  }

  void sendText(String text) {
    chatController.addOutgoingMessage(
      ChatMessage(
        id: 'getx_${DateTime.now().microsecondsSinceEpoch}',
        senderId: chatController.currentUserId,
        type: ChatMessageType.text,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  void onClose() {
    // GetxController.onClose is the GetX-side lifecycle hook — this is
    // where the ChatController's own dispose() belongs (doc section 27,
    // lifecycle safety: no listeners should outlive the screen that
    // created them).
    chatController.dispose();
    super.onClose();
  }
}

/// The screen: notice it never touches `ChatController.stream` directly —
/// only the GetX controller above does. [MessageList]/[ChatInputBar]
/// could just as easily be swapped in here instead of [ChatView]; the
/// binding pattern is identical either way.
class GetxChatScreen extends StatelessWidget {
  const GetxChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ChatGetxController(
        chatController: ChatController(currentUserId: DemoData.currentUserId)
          ..addIncomingMessage(DemoData.seedMessages().first),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(DemoData.otherUser.name)),
      // Note: `ChatView` already subscribes to `controller.chatController.stream`
      // internally via its own `StreamBuilder`, so wrapping it in `Obx`
      // here isn't strictly required just to render messages. The `Obx`
      // matters once *other* widgets on this screen — a header showing
      // "3 unread", a custom typing indicator outside ChatView, etc. —
      // also need to react to `controller.state` reactively the GetX way.
      body: Obx(
        () => ChatView(
          controller: controller.chatController,
          theme: DemoData.theme(),
          userResolver: DemoData.resolveUser,
          onSendText: controller.sendText,
        ),
      ),
    );
  }
}
