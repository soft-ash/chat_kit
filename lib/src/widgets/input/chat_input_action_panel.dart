import 'package:flutter/material.dart';

import '../../theme/chat_colors.dart';
import '../../theme/chat_theme.dart';
import 'chat_input_action.dart';

/// The expandable action row beneath the text field — "Games / Photo /
/// Voice / Date" in the reference design, fully driven by whatever
/// [actions] the host app passes in. Horizontally scrollable, so it never
/// overflows regardless of screen width or action count — the same row
/// works unmodified on a small phone, a tablet, or desktop (doc section 29).
class ChatInputActionPanel extends StatelessWidget {
  final List<ChatInputAction> actions;
  final ChatTheme theme;

  const ChatInputActionPanel({
    super.key,
    required this.actions,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    final colors = theme.colors;

    return Container(
      height: 88,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: theme.spacing.inputPadding),
      decoration: BoxDecoration(
        color: colors.inputBackground,
        border: Border(top: BorderSide(color: colors.inputBorder)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) => _ActionButton(action: actions[index], theme: theme),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final ChatInputAction action;
  final ChatTheme theme;

  const _ActionButton({required this.action, required this.theme});

  @override
  Widget build(BuildContext context) {
    final ChatColors colors = theme.colors;
    final tint = action.color ?? colors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: action.onPressed,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: tint, size: theme.dimensions.actionIconSize),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.timestamp.copyWith(color: colors.receiverText),
            ),
          ],
        ),
      ),
    );
  }
}
