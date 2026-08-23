import 'dart:async';

import 'package:advanced_chat_kit/advanced_chat_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../common/demo_data.dart';

/// How to bind [ChatController]'s `Stream<ChatState>` to Bloc/Cubit.
///
/// A [Cubit] is really just "hold a value, emit new ones" — which is
/// exactly what [ChatController]'s stream already does. This Cubit's
/// only job is subscribing and re-emitting.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit({required this.chatController}) : super(chatController.currentState) {
    _subscription = chatController.stream.listen(emit);
  }

  final ChatController chatController;
  late final StreamSubscription<ChatState> _subscription;

  void sendText(String text) {
    chatController.addOutgoingMessage(
      ChatMessage(
        id: 'bloc_${DateTime.now().microsecondsSinceEpoch}',
        senderId: chatController.currentUserId,
        type: ChatMessageType.text,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> close() {
    // Cubit.close() is the Bloc-side lifecycle hook — cancel the bridge
    // subscription and dispose the underlying controller together (doc
    // section 27, lifecycle safety), same pairing as the GetX/Riverpod
    // examples' onClose/onDispose.
    _subscription.cancel();
    chatController.dispose();
    return super.close();
  }
}

class BlocChatScreen extends StatelessWidget {
  const BlocChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatCubit(
        chatController: ChatController(currentUserId: DemoData.currentUserId)
          ..addIncomingMessage(DemoData.seedMessages().first),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(DemoData.otherUser.name)),
        // `BlocBuilder` here mirrors `Obx`/`ConsumerWidget.watch` in the
        // other two examples — again, not strictly required to render
        // `ChatView` (it manages its own stream subscription), but this
        // is the idiomatic place to react to `ChatState` for any other
        // Bloc-driven widget on the same screen.
        body: BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            final cubit = context.read<ChatCubit>();
            return ChatView(
              controller: cubit.chatController,
              theme: DemoData.theme(),
              userResolver: DemoData.resolveUser,
              onSendText: cubit.sendText,
            );
          },
        ),
      ),
    );
  }
}
