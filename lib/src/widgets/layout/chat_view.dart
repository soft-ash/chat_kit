import 'package:flutter/material.dart';

import '../../controller/chat_controller.dart';
import '../../controller/chat_state.dart';
import '../../model/chat_attachment.dart';
import '../../model/chat_link_preview.dart';
import '../../model/chat_reply.dart';
import '../../theme/chat_theme.dart';
import '../actions/chat_message_action.dart';
import '../actions/reaction_bar.dart';
import '../input/chat_input_action.dart';
import '../input/chat_input_bar.dart';
import '../message/message_bubble.dart';
import '../message/message_list.dart';
import '../message/typing_indicator_bubble.dart';
import 'chat_background.dart';
import 'chat_background_view.dart';
import 'chat_layers.dart';

/// Assembles [MessageList], [ChatInputBar], [ChatBackgroundView], and
/// every [ChatLayers] slot into one ready-to-drop-in chat screen body —
/// everything the earlier phases built, wired together the way a typical
/// chat screen actually uses them.
///
/// [ChatView] is intentionally *not* the only way to use this package:
/// every widget it composes ([MessageList], [ChatInputBar], the media
/// widgets, ...) is exported and fully usable standalone if you want a
/// different layout or need something [ChatView] doesn't expose. This is
/// the "batteries included" assembly for the common case — a `Scaffold`
/// body, typically:
///
/// ```dart
/// Scaffold(
///   appBar: MyChatHeader(user: otherUser),
///   body: ChatView(
///     controller: chatController,
///     theme: ChatTheme.light(),
///     onSendText: (text) {
///       final message = ChatMessage(...);
///       chatController.addOutgoingMessage(message);
///       socket.emit('send_message', message.toJson());
///     },
///   ),
/// )
/// ```
///
/// State management stays exactly as agnostic as [ChatController] itself:
/// [ChatView] subscribes to `controller.stream` internally via a
/// [StreamBuilder], so it drops into a GetX `Obx`, a Riverpod `Consumer`,
/// a Bloc `BlocBuilder`, or a plain widget tree identically — nothing
/// about state management propagates outward from here.
class ChatView extends StatelessWidget {
  final ChatController controller;
  final ChatTheme theme;
  final ChatBackground? background;
  final ChatLayers layers;

  // --- Message list pass-through ---
  final ChatUserResolver? userResolver;
  final ChatMessageBuilder? customMessageBuilder;
  final ChatMessageTap? onMessageTap;
  final ChatMessageTap? onMessageLongPress;
  final ChatReplyTap? onReplyPreviewTap;
  final ChatMessageTap? onRetryAttachment;
  final ChatMessageTap? onOpenDocument;
  final ChatMessageTap? onLocationTap;
  final ChatMessageTap? onContactTap;
  final List<ChatMessageAction>? messageActions;
  final List<String> reactionEmojis;
  final ChatReactionToggle? onToggleReaction;
  final VoidCallback? onMoreReactions;
  final bool enableMarkdown;
  final ValueChanged<String>? onLinkTap;
  final Widget? emptyState;
  final bool showTypingIndicator;

  // --- Input bar pass-through ---
  final ValueChanged<String> onSendText;
  final ValueChanged<bool>? onTypingChanged;
  final ChatReply? replyingTo;
  final VoidCallback? onCancelReply;
  final List<ChatInputAction> inlineActions;
  final List<ChatInputAction> expandableActions;
  final bool enableVoice;
  final VoidCallback? onVoiceRecordStart;
  final VoidCallback? onVoiceRecordCancel;
  final ValueChanged<Duration>? onVoiceRecordStop;
  final List<ChatAttachment> pendingAttachments;
  final ValueChanged<ChatAttachment>? onRemovePendingAttachment;
  final ValueChanged<ChatAttachment>? onTapPendingAttachment;
  final ChatSendMedia? onSendMedia;
  final ChatLinkPreview? composerLinkPreview;
  final VoidCallback? onDismissLinkPreview;
  final String inputHintText;

  const ChatView({
    super.key,
    required this.controller,
    required this.theme,
    required this.onSendText,
    this.background,
    this.layers = const ChatLayers(),
    this.userResolver,
    this.customMessageBuilder,
    this.onMessageTap,
    this.onMessageLongPress,
    this.onReplyPreviewTap,
    this.onRetryAttachment,
    this.onOpenDocument,
    this.onLocationTap,
    this.onContactTap,
    this.messageActions,
    this.reactionEmojis = ReactionBar.defaultEmojis,
    this.onToggleReaction,
    this.onMoreReactions,
    this.enableMarkdown = false,
    this.onLinkTap,
    this.emptyState,
    this.showTypingIndicator = true,
    this.onTypingChanged,
    this.replyingTo,
    this.onCancelReply,
    this.inlineActions = const [],
    this.expandableActions = const [],
    this.enableVoice = true,
    this.onVoiceRecordStart,
    this.onVoiceRecordCancel,
    this.onVoiceRecordStop,
    this.pendingAttachments = const [],
    this.onRemovePendingAttachment,
    this.onTapPendingAttachment,
    this.onSendMedia,
    this.composerLinkPreview,
    this.onDismissLinkPreview,
    this.inputHintText = 'Message...',
  });

  @override
  Widget build(BuildContext context) {
    return ChatBackgroundView(
      background: background,
      child: StreamBuilder<ChatState>(
        stream: controller.stream,
        initialData: controller.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data ?? const ChatState();

          return Column(
            children: [
              if (layers.header != null) layers.header!,
              if (layers.belowHeader != null) layers.belowHeader!,
              if (layers.aboveMessages != null) layers.aboveMessages!,
              Expanded(
                child: Stack(
                  children: [
                    MessageList(
                      state: state,
                      currentUserId: controller.currentUserId,
                      theme: theme,
                      userResolver: userResolver,
                      customMessageBuilder: customMessageBuilder,
                      onMessageTap: onMessageTap,
                      onMessageLongPress: onMessageLongPress,
                      onReplyPreviewTap: onReplyPreviewTap,
                      onRetryAttachment: onRetryAttachment,
                      onOpenDocument: onOpenDocument,
                      onLocationTap: onLocationTap,
                      onContactTap: onContactTap,
                      messageActions: messageActions,
                      reactionEmojis: reactionEmojis,
                      onToggleReaction: onToggleReaction,
                      onMoreReactions: onMoreReactions,
                      enableMarkdown: enableMarkdown,
                      onLinkTap: onLinkTap,
                      onLoadMore: controller.loadMore,
                      emptyState: emptyState,
                      typingIndicator:
                          showTypingIndicator && state.isTyping ? TypingIndicatorBubble(theme: theme) : null,
                    ),
                    if (layers.overlay != null) layers.overlay!,
                  ],
                ),
              ),
              if (layers.belowMessages != null) layers.belowMessages!,
              if (layers.aboveInput != null) layers.aboveInput!,
              ChatInputBar(
                theme: theme,
                onSendText: onSendText,
                onTypingChanged: onTypingChanged,
                replyingTo: replyingTo,
                onCancelReply: onCancelReply,
                inlineActions: inlineActions,
                expandableActions: expandableActions,
                enableVoice: enableVoice,
                onVoiceRecordStart: onVoiceRecordStart,
                onVoiceRecordCancel: onVoiceRecordCancel,
                onVoiceRecordStop: onVoiceRecordStop,
                pendingAttachments: pendingAttachments,
                onRemovePendingAttachment: onRemovePendingAttachment,
                onTapPendingAttachment: onTapPendingAttachment,
                onSendMedia: onSendMedia,
                composerLinkPreview: composerLinkPreview,
                onDismissLinkPreview: onDismissLinkPreview,
                hintText: inputHintText,
              ),
              if (layers.belowInput != null) layers.belowInput!,
            ],
          );
        },
      ),
    );
  }
}
