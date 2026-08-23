import 'package:flutter/material.dart';

import '../../model/chat_message.dart';
import '../../theme/chat_theme.dart';
import 'chat_message_action.dart';
import 'reaction_bar.dart';

/// Opens the long-press action sheet: an optional quick-reaction row on
/// top, then the vertical list of [actions] below — the "Long press
/// message → Reply / Forward / Copy / React / Edit / Delete / More" flow
/// from doc section 2.
///
/// Pass `onReactionSelected: null` (the default) to omit the reaction
/// row entirely, e.g. for a message type reactions don't make sense on.
Future<void> showMessageActionSheet(
  BuildContext context, {
  required ChatMessage message,
  required ChatTheme theme,
  required List<ChatMessageAction> actions,
  List<String> reactionEmojis = ReactionBar.defaultEmojis,
  ValueChanged<String>? onReactionSelected,
  VoidCallback? onMoreReactions,
}) {
  final colors = theme.colors;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onReactionSelected != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ReactionBar(
                    emojis: reactionEmojis,
                    theme: theme,
                    onSelected: (emoji) {
                      Navigator.of(sheetContext).pop();
                      onReactionSelected(emoji);
                    },
                    onMorePressed: onMoreReactions == null
                        ? null
                        : () {
                            Navigator.of(sheetContext).pop();
                            onMoreReactions();
                          },
                  ),
                ),
              if (actions.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i != 0) Divider(height: 1, color: colors.inputBorder),
                        _ActionTile(action: actions[i], message: message, theme: theme),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  final ChatMessageAction action;
  final ChatMessage message;
  final ChatTheme theme;

  const _ActionTile({required this.action, required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    final color = action.isDestructive ? colors.danger : colors.receiverText;

    return ListTile(
      leading: Icon(action.icon, color: color),
      title: Text(action.label, style: theme.typography.messageText.copyWith(color: color)),
      onTap: () {
        Navigator.of(context).pop();
        action.onPressed(message);
      },
    );
  }
}
