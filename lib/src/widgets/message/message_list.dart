import 'package:flutter/material.dart';

import '../../controller/chat_state.dart';
import '../../model/chat_user.dart';
import '../../theme/chat_theme.dart';
import '../actions/chat_message_action.dart';
import '../actions/reaction_bar.dart';
import 'message_bubble.dart';
import 'message_group_utils.dart';

/// Resolves a [ChatUser] for a `senderId` so the list can show avatars and
/// names — usually backed by whatever user cache the host app already
/// maintains (a `Map<String, ChatUser>`, a Riverpod provider, etc.).
typedef ChatUserResolver = ChatUser? Function(String senderId);

/// Renders [ChatState.messages] as grouped, auto-scrolling bubbles.
///
/// Rebuild granularity: each [MessageBubble] gets `key: ValueKey(id)`, so a
/// single message update (e.g. a reaction on message #382) only rebuilds
/// that one Element — Flutter's own list diffing keeps the other 9,999
/// bubbles untouched (see SDK doc section 19/23, "avoid full list rebuilds").
class MessageList extends StatefulWidget {
  final ChatState state;
  final String currentUserId;
  final ChatTheme theme;
  final ChatUserResolver? userResolver;
  final ChatMessageBuilder? customMessageBuilder;
  final ChatMessageTap? onMessageTap;
  final ChatMessageTap? onMessageLongPress;
  final ChatReplyTap? onReplyPreviewTap;
  final ChatMessageTap? onRetryAttachment;
  final ChatMessageTap? onOpenDocument;

  /// Long-press action list (Reply/Forward/Copy/Delete/...). When
  /// provided, [MessageBubble] opens the action sheet automatically
  /// instead of just firing [onMessageLongPress].
  final List<ChatMessageAction>? messageActions;
  final List<String> reactionEmojis;
  final ChatReactionToggle? onToggleReaction;
  final VoidCallback? onMoreReactions;
  final bool enableMarkdown;
  final ValueChanged<String>? onLinkTap;
  final ChatMessageTap? onLocationTap;
  final ChatMessageTap? onContactTap;

  /// Called when the user scrolls near the top — wire this to
  /// `chatController.loadMore()`.
  final VoidCallback? onLoadMore;

  final Widget? emptyState;
  final Widget? typingIndicator;

  const MessageList({
    super.key,
    required this.state,
    required this.currentUserId,
    required this.theme,
    this.userResolver,
    this.customMessageBuilder,
    this.onMessageTap,
    this.onMessageLongPress,
    this.onReplyPreviewTap,
    this.onRetryAttachment,
    this.onOpenDocument,
    this.messageActions,
    this.reactionEmojis = ReactionBar.defaultEmojis,
    this.onToggleReaction,
    this.onMoreReactions,
    this.enableMarkdown = false,
    this.onLinkTap,
    this.onLocationTap,
    this.onContactTap,
    this.onLoadMore,
    this.emptyState,
    this.typingIndicator,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();
  bool _stickToBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animated: false));
  }

  @override
  void didUpdateWidget(covariant MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final grew = widget.state.messages.length > oldWidget.state.messages.length;
    if (grew && _stickToBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;

    _stickToBottom = position.pixels >= position.maxScrollExtent - 80;

    if (position.pixels <= 120 && !widget.state.isLoadingMore && widget.state.hasMoreMessages) {
      widget.onLoadMore?.call();
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(target, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    } else {
      _scrollController.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.state.messages;

    if (messages.isEmpty) {
      return widget.emptyState ?? const SizedBox.shrink();
    }

    return Column(
      children: [
        if (widget.state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(vertical: widget.theme.spacing.listPaddingVertical),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMe = message.senderId == widget.currentUserId;
              final group = resolveGroupInfo(messages, index);
              final sender = widget.userResolver?.call(message.senderId);

              return MessageBubble(
                key: ValueKey(message.id),
                message: message,
                isMe: isMe,
                sender: sender,
                theme: widget.theme,
                isFirstInGroup: group.isFirstInGroup,
                isLastInGroup: group.isLastInGroup,
                customMessageBuilder: widget.customMessageBuilder,
                onTap: widget.onMessageTap,
                onLongPress: widget.onMessageLongPress,
                onReplyPreviewTap: widget.onReplyPreviewTap,
                onRetryAttachment: widget.onRetryAttachment,
                onOpenDocument: widget.onOpenDocument,
                actions: widget.messageActions,
                reactionEmojis: widget.reactionEmojis,
                currentUserId: widget.currentUserId,
                onToggleReaction: widget.onToggleReaction,
                onMoreReactions: widget.onMoreReactions,
                enableMarkdown: widget.enableMarkdown,
                onLinkTap: widget.onLinkTap,
                onLocationTap: widget.onLocationTap,
                onContactTap: widget.onContactTap,
              );
            },
          ),
        ),
        if (widget.state.isTyping && widget.typingIndicator != null) widget.typingIndicator!,
      ],
    );
  }
}
