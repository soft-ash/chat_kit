import 'package:flutter/material.dart';

import '../../theme/chat_colors.dart';
import '../../theme/chat_theme.dart';

/// Renders a shared-contact message: avatar, name, phone/email — tapping
/// calls [onTap] so the host app can open its own contact detail view,
/// dial the number, or start an add-to-contacts flow.
///
/// Same philosophy as [LocationPreviewCard]: the package has no contacts
/// API of its own, it only draws whatever fields you give it.
class ChatContactMessage extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String? avatarUrl;
  final ChatTheme theme;
  final bool isMe;
  final VoidCallback? onTap;

  const ChatContactMessage({
    super.key,
    required this.name,
    required this.theme,
    required this.isMe,
    this.subtitle,
    this.avatarUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ChatColors colors = theme.colors;
    final textColor = isMe ? colors.senderText : colors.receiverText;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 220,
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: textColor.withValues(alpha: 0.15),
              backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty) ? NetworkImage(avatarUrl!) : null,
              child: (avatarUrl == null || avatarUrl!.isEmpty) ? Icon(Icons.person, color: textColor) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.messageText.copyWith(color: textColor, fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.timestamp.copyWith(color: textColor.withValues(alpha: 0.75)),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textColor.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}
