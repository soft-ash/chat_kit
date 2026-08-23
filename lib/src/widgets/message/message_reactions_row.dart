import 'package:flutter/material.dart';

import '../../model/chat_reaction.dart';
import '../../theme/chat_theme.dart';

/// Groups raw per-user [ChatReaction]s into emoji → count chips, rendered
/// just under a bubble. Tapping a chip toggles the current user's own
/// reaction for that emoji via [onToggle] — the host app decides whether
/// that means add, remove, or replace (typically:
/// `chatController.addReaction(...)` / `removeReaction(...)`).
class MessageReactionsRow extends StatelessWidget {
  final List<ChatReaction> reactions;
  final String currentUserId;
  final ChatTheme theme;
  final ValueChanged<String> onToggle;

  const MessageReactionsRow({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.theme,
    required this.onToggle,
  });

  Map<String, List<ChatReaction>> _grouped() {
    final map = <String, List<ChatReaction>>{};
    for (final reaction in reactions) {
      map.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    final colors = theme.colors;
    final grouped = _grouped();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: grouped.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          final isMine = users.any((r) => r.userId == currentUserId);

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onToggle(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isMine ? colors.primary.withValues(alpha: 0.15) : colors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: isMine ? Border.all(color: colors.primary, width: 1) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  if (users.length > 1) ...[
                    const SizedBox(width: 3),
                    Text(
                      '${users.length}',
                      style: theme.typography.timestamp.copyWith(color: colors.hintText),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
