import 'package:flutter/material.dart';

import '../../model/chat_reply.dart';
import '../../theme/chat_theme.dart';

/// Shown directly above the input field while the user is composing a
/// reply — mirrors the quoted-message look already used inside the
/// bubble itself, so the two read as the same feature (see doc section 2).
class ReplyPreviewBar extends StatelessWidget {
  final ChatReply reply;
  final ChatTheme theme;
  final VoidCallback onCancel;

  const ReplyPreviewBar({
    super.key,
    required this.reply,
    required this.theme,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.spacing.inputPadding, vertical: 8),
      decoration: BoxDecoration(
        color: colors.inputBackground,
        border: Border(top: BorderSide(color: colors.inputBorder)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 34, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${reply.senderName}',
                  style: theme.typography.senderName.copyWith(color: colors.primary),
                ),
                if (reply.preview != null)
                  Text(
                    reply.preview!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.messageText.copyWith(fontSize: 13, color: colors.hintText),
                  ),
              ],
            ),
          ),
          if (reply.thumbnailUrl != null && reply.thumbnailUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                reply.thumbnailUrl!,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: Icon(Icons.close, size: 18, color: colors.hintText),
            onPressed: onCancel,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}
