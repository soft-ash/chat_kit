import 'package:flutter/material.dart';

import '../../core/enums/chat_enums.dart';
import '../../core/utils/date_format.dart';
import '../../model/chat_message.dart';
import '../../model/chat_user.dart';
import '../../theme/chat_colors.dart';
import '../../theme/chat_theme.dart';
import '../chat_avatar.dart';
import '../actions/chat_message_action.dart';
import '../actions/message_action_sheet.dart';
import '../actions/reaction_bar.dart';
import '../media/chat_audio_message.dart';
import '../media/chat_contact_message.dart';
import '../media/chat_document_message.dart';
import '../media/chat_image_message.dart';
import '../media/chat_video_message.dart';
import 'link_preview_card.dart';
import 'linkified_text.dart';
import 'location_preview_card.dart';
import 'markdown_text.dart';
import 'message_reactions_row.dart';
import 'message_status_icon.dart';
import 'streaming_cursor.dart';

/// Escape hatch for application-defined rendering. Return `null` to fall
/// back to the package's default bubble for this message (e.g. you only
/// want to override `custom` messages and let text/image/etc. render
/// normally). See SDK doc section 6 — the package never needs to know
/// what a given `customType` means.
typedef ChatMessageBuilder = Widget? Function(BuildContext context, ChatMessage message, bool isMe);

typedef ChatMessageTap = void Function(ChatMessage message);
typedef ChatReplyTap = void Function(String messageId);

/// Toggling a reaction needs to know *which* message it's for — a plain
/// `ValueChanged<String>` (just the emoji) can't carry that, since one
/// callback is shared across every bubble in the list.
typedef ChatReactionToggle = void Function(ChatMessage message, String emoji);

/// Default message bubble: text/media placeholder content, reply/forward
/// labels, sender name + avatar for group chats, timestamp + delivery
/// status. Every color/size comes from [theme] — nothing here is
/// hardcoded, so the host app can restyle globally via [ChatTheme].
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final ChatUser? sender;
  final ChatTheme theme;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool showSenderName;
  final ChatMessageBuilder? customMessageBuilder;
  final ChatMessageTap? onTap;
  final ChatMessageTap? onLongPress;
  final ChatReplyTap? onReplyPreviewTap;

  /// Called when an image/video/audio/document attachment failed to
  /// upload and the person taps the retry icon. Wire this to whatever
  /// re-triggers your `onUploadAttachment` callback.
  final ChatMessageTap? onRetryAttachment;

  /// Called when a document attachment is tapped (opening/downloading a
  /// file is host-app business logic — see doc section 18).
  final ChatMessageTap? onOpenDocument;

  /// If provided, long-pressing the bubble opens [showMessageActionSheet]
  /// automatically with these actions instead of just firing [onLongPress].
  /// Leave `null` to handle long-press entirely yourself.
  final List<ChatMessageAction>? actions;
  final List<String> reactionEmojis;

  /// The signed-in user's id — needed to tell "my reaction" apart from
  /// everyone else's when rendering [MessageReactionsRow]. Reactions are
  /// hidden entirely if this is `null`.
  final String? currentUserId;
  final ChatReactionToggle? onToggleReaction;
  final VoidCallback? onMoreReactions;

  /// Whether to render text-message content as Markdown (bold/italic/
  /// code/links/headings/lists) via [MarkdownText] instead of plain
  /// linkified text. Typically `true` for AI chat, `false` for normal
  /// human chat (see doc section 11 — Markdown is usually only needed
  /// for AI responses).
  final bool enableMarkdown;

  /// Called when the person taps a URL inside message text or a
  /// [LinkPreviewCard]. Leave `null` to use the default system browser
  /// via [launchSafeUrl].
  final ValueChanged<String>? onLinkTap;

  /// Called when a [LocationPreviewCard] is tapped — typically opens the
  /// native maps app with the coordinates from `message.metadata`.
  final ChatMessageTap? onLocationTap;

  /// Called when a [ChatContactMessage] is tapped.
  final ChatMessageTap? onContactTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.theme,
    this.sender,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.showSenderName = true,
    this.customMessageBuilder,
    this.onTap,
    this.onLongPress,
    this.onReplyPreviewTap,
    this.onRetryAttachment,
    this.onOpenDocument,
    this.actions,
    this.reactionEmojis = ReactionBar.defaultEmojis,
    this.currentUserId,
    this.onToggleReaction,
    this.onMoreReactions,
    this.enableMarkdown = false,
    this.onLinkTap,
    this.onLocationTap,
    this.onContactTap,
  });

  BorderRadius _bubbleRadius() {
    final r = Radius.circular(theme.dimensions.messageBubbleRadius);
    const tight = Radius.circular(4);
    if (isMe) {
      return BorderRadius.only(
        topLeft: r,
        bottomLeft: r,
        topRight: isFirstInGroup ? r : tight,
        bottomRight: isLastInGroup ? r : tight,
      );
    }
    return BorderRadius.only(
      topRight: r,
      bottomRight: r,
      topLeft: isFirstInGroup ? r : tight,
      bottomLeft: isLastInGroup ? r : tight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    final spacing = theme.spacing;
    final dims = theme.dimensions;

    if (message.isDeleted) {
      return _wrapRow(context, _deletedBubble(colors));
    }

    final custom = customMessageBuilder?.call(context, message, isMe);
    if (custom != null) return _wrapRow(context, custom);

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * dims.maxMessageWidthFactor,
      ),
      padding: EdgeInsets.all(spacing.messagePadding),
      decoration: BoxDecoration(
        color: isMe
            ? (message.status == ChatMessageStatus.failed ? colors.danger.withValues(alpha: 0.15) : colors.senderBubble)
            : colors.receiverBubble,
        gradient: isMe ? colors.senderBubbleGradient : null,
        borderRadius: _bubbleRadius(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMe && isFirstInGroup && showSenderName && sender != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                sender!.name,
                style: theme.typography.senderName.copyWith(color: colors.primary),
              ),
            ),
          if (message.forwardedFrom != null) _forwardedLabel(colors),
          if (message.replyTo != null) _replyPreview(colors),
          _content(colors),
          const SizedBox(height: 4),
          _footer(colors),
          if (currentUserId != null)
            MessageReactionsRow(
              reactions: message.reactions,
              currentUserId: currentUserId!,
              theme: theme,
              onToggle: (emoji) => onToggleReaction?.call(message, emoji),
            ),
        ],
      ),
    );

    return _wrapRow(context, bubble);
  }

  Widget _wrapRow(BuildContext context, Widget bubble) {
    final spacing = theme.spacing;
    final dims = theme.dimensions;

    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? spacing.differentSenderGap : spacing.sameSenderGap,
        left: spacing.listPaddingHorizontal,
        right: spacing.listPaddingHorizontal,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: dims.avatarSizeSmall,
                height: dims.avatarSizeSmall,
                child: isLastInGroup ? ChatAvatar(user: sender, size: dims.avatarSizeSmall, colors: theme.colors) : null,
              ),
            ),
          Flexible(
            child: GestureDetector(
              onTap: () => onTap?.call(message),
              onLongPress: () {
                if (actions != null && actions!.isNotEmpty) {
                  showMessageActionSheet(
                    context,
                    message: message,
                    theme: theme,
                    actions: actions!,
                    reactionEmojis: reactionEmojis,
                    onReactionSelected: onToggleReaction == null ? null : (emoji) => onToggleReaction!(message, emoji),
                    onMoreReactions: onMoreReactions,
                  );
                } else {
                  onLongPress?.call(message);
                }
              },
              child: bubble,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deletedBubble(ChatColors colors) {
    return Container(
      padding: EdgeInsets.all(theme.spacing.messagePadding),
      decoration: BoxDecoration(
        color: (isMe ? colors.senderBubble : colors.receiverBubble).withValues(alpha: 0.5),
        borderRadius: _bubbleRadius(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 14, color: colors.hintText),
          const SizedBox(width: 6),
          Text('This message was deleted', style: theme.typography.systemMessage.copyWith(color: colors.hintText)),
        ],
      ),
    );
  }

  Widget _forwardedLabel(ChatColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forward, size: 12, color: isMe ? colors.senderText.withValues(alpha: 0.7) : colors.hintText),
          const SizedBox(width: 4),
          Text('Forwarded', style: theme.typography.timestamp.copyWith(color: isMe ? colors.senderText.withValues(alpha: 0.7) : colors.hintText)),
        ],
      ),
    );
  }

  Widget _replyPreview(ChatColors colors) {
    final reply = message.replyTo!;
    return GestureDetector(
      onTap: () => onReplyPreviewTap?.call(reply.messageId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: (isMe ? colors.onPrimary : colors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: colors.primary, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(reply.senderName, style: theme.typography.senderName.copyWith(color: colors.primary)),
                  if (reply.preview != null)
                    Text(
                      reply.preview!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.messageText.copyWith(
                        fontSize: 13,
                        color: (isMe ? colors.senderText : colors.receiverText).withValues(alpha: 0.75),
                      ),
                    ),
                ],
              ),
            ),
            // Small thumbnail when replying to an image/video — mirrors
            // WhatsApp/Telegram's quoted-media preview.
            if (reply.thumbnailUrl != null && reply.thumbnailUrl!.isNotEmpty) ...[
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  reply.thumbnailUrl!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _content(ChatColors colors) {
    final textColor = isMe ? colors.senderText : colors.receiverText;
    final attachment = message.attachments.isNotEmpty ? message.attachments.first : null;

    switch (message.type) {
      case ChatMessageType.text:
        final textContent = message.text ?? '';
        final textWidget = enableMarkdown
            ? MarkdownText(
                data: textContent,
                baseStyle: theme.typography.messageText.copyWith(color: textColor),
                linkStyle: theme.linkStyle,
                codeBackground: colors.inputBackground,
                onLinkTap: onLinkTap,
              )
            : LinkifiedText(
                text: textContent,
                style: theme.typography.messageText.copyWith(color: textColor),
                linkStyle: theme.linkStyle,
                onLinkTap: onLinkTap,
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            message.isStreaming
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(child: textWidget),
                      StreamingCursor(color: textColor),
                    ],
                  )
                : textWidget,
            if (message.linkPreview != null)
              LinkPreviewCard(preview: message.linkPreview!, theme: theme, onTap: onLinkTap),
          ],
        );

      case ChatMessageType.image:
        if (attachment == null) return _mediaPlaceholder(textColor, Icons.image_outlined, 'Photo');
        return _mediaWithCaption(
          ChatImageMessage(
            attachment: attachment,
            status: message.status,
            theme: theme,
            onRetry: onRetryAttachment == null ? null : () => onRetryAttachment!(message),
          ),
          textColor,
        );

      case ChatMessageType.video:
        if (attachment == null) return _mediaPlaceholder(textColor, Icons.videocam_outlined, 'Video');
        return _mediaWithCaption(
          ChatVideoMessage(
            attachment: attachment,
            status: message.status,
            theme: theme,
            onRetry: onRetryAttachment == null ? null : () => onRetryAttachment!(message),
          ),
          textColor,
        );

      case ChatMessageType.audio:
        if (attachment == null) return _mediaPlaceholder(textColor, Icons.mic_none, 'Voice message');
        return ChatAudioMessage(
          attachment: attachment,
          status: message.status,
          theme: theme,
          isMe: isMe,
          onRetry: onRetryAttachment == null ? null : () => onRetryAttachment!(message),
        );

      case ChatMessageType.document:
        if (attachment == null) return _mediaPlaceholder(textColor, Icons.insert_drive_file_outlined, 'Document');
        return ChatDocumentMessage(
          attachment: attachment,
          status: message.status,
          theme: theme,
          isMe: isMe,
          onOpen: onOpenDocument == null ? null : () => onOpenDocument!(message),
          onRetry: onRetryAttachment == null ? null : () => onRetryAttachment!(message),
        );

      case ChatMessageType.location:
        final data = message.metadata ?? const <String, dynamic>{};
        final address = data['address'] is String ? data['address'] as String : null;
        final staticMapUrl = data['staticMapImageUrl'] is String ? data['staticMapImageUrl'] as String : null;
        final locationLabel = data['label'] is String ? data['label'] as String : 'Pinned location';
        if (address == null) return _mediaPlaceholder(textColor, Icons.location_on_outlined, 'Location');
        return LocationPreviewCard(
          address: address,
          label: locationLabel,
          staticMapImageUrl: staticMapUrl,
          theme: theme,
          onTap: onLocationTap == null ? null : () => onLocationTap!(message),
        );

      case ChatMessageType.contact:
        final data = message.metadata ?? const <String, dynamic>{};
        final contactName = data['name'] is String ? data['name'] as String : null;
        final contactSubtitle = data['phone'] is String
            ? data['phone'] as String
            : (data['email'] is String ? data['email'] as String : null);
        final contactAvatar = data['avatarUrl'] is String ? data['avatarUrl'] as String : null;
        if (contactName == null) return _mediaPlaceholder(textColor, Icons.person_outline, 'Contact');
        return ChatContactMessage(
          name: contactName,
          subtitle: contactSubtitle,
          avatarUrl: contactAvatar,
          theme: theme,
          isMe: isMe,
          onTap: onContactTap == null ? null : () => onContactTap!(message),
        );

      case ChatMessageType.system:
        return Text(
          message.text ?? '',
          style: theme.typography.systemMessage.copyWith(color: colors.hintText),
        );

      case ChatMessageType.custom:
        return _mediaPlaceholder(textColor, Icons.widgets_outlined, 'Unsupported message — register a builder for "${message.customType}"');
    }
  }

  /// Media messages can carry an optional caption in [ChatMessage.text],
  /// shown beneath the thumbnail/player just like WhatsApp/Telegram.
  Widget _mediaWithCaption(Widget media, Color textColor) {
    if (message.text == null || message.text!.trim().isEmpty) return media;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        media,
        const SizedBox(height: 6),
        Text(message.text!, style: theme.typography.messageText.copyWith(color: textColor)),
      ],
    );
  }

  /// Fallback for message types with no attachment yet (e.g. a locally
  /// constructed message the host app hasn't populated), and for
  /// location/contact/custom types that don't have a dedicated media
  /// widget in this phase.
  Widget _mediaPlaceholder(Color textColor, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: textColor.withValues(alpha: 0.85)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: theme.typography.messageText.copyWith(color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _footer(ChatColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isEdited) ...[
          Text('edited', style: theme.typography.timestamp.copyWith(color: isMe ? colors.senderText.withValues(alpha: 0.7) : colors.timestamp)),
          const SizedBox(width: 4),
        ],
        Text(
          formatMessageTime(message.createdAt),
          style: theme.typography.timestamp.copyWith(color: isMe ? colors.senderText.withValues(alpha: 0.7) : colors.timestamp),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          MessageStatusIcon(status: message.status, colors: colors),
        ],
      ],
    );
  }
}
