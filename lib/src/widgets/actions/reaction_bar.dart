import 'package:flutter/material.dart';

import '../../theme/chat_theme.dart';

/// Quick-tap emoji strip shown at the top of the long-press action
/// sheet — the fast path for the most common reactions, mirroring
/// WhatsApp/Telegram/iMessage. [emojis] is fully configurable (see doc
/// section 10, `ReactionConfig`).
class ReactionBar extends StatelessWidget {
  final List<String> emojis;
  final ChatTheme theme;
  final ValueChanged<String> onSelected;
  final VoidCallback? onMorePressed;

  const ReactionBar({
    super.key,
    required this.emojis,
    required this.theme,
    required this.onSelected,
    this.onMorePressed,
  });

  static const List<String> defaultEmojis = ['❤️', '😂', '👍', '😢', '😡', '🙏'];

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final emoji in emojis) _EmojiButton(emoji: emoji, onTap: () => onSelected(emoji)),
          if (onMorePressed != null)
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: colors.hintText),
              onPressed: onMorePressed,
              splashRadius: 18,
            ),
        ],
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiButton({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
