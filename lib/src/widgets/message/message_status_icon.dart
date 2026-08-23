import 'package:flutter/material.dart';

import '../../core/enums/chat_enums.dart';
import '../../theme/chat_colors.dart';

/// Renders the small status glyph next to an outgoing message's timestamp.
/// Only meaningful for `isMe` bubbles — incoming messages never show this.
class MessageStatusIcon extends StatelessWidget {
  final ChatMessageStatus status;
  final ChatColors colors;
  final double size;

  const MessageStatusIcon({
    super.key,
    required this.status,
    required this.colors,
    this.size = 13,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ChatMessageStatus.sending:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation(colors.timestamp),
          ),
        );
      case ChatMessageStatus.sent:
        return Icon(Icons.check, size: size, color: colors.timestamp);
      case ChatMessageStatus.delivered:
        return Icon(Icons.done_all, size: size, color: colors.timestamp);
      case ChatMessageStatus.read:
        return Icon(Icons.done_all, size: size, color: colors.primary);
      case ChatMessageStatus.failed:
        return Icon(Icons.error_outline, size: size, color: colors.danger);
    }
  }
}
