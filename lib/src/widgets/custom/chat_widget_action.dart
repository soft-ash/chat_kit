import 'package:flutter/material.dart';

import '../../theme/chat_colors.dart';
import '../../theme/chat_theme.dart';

/// A single action button inside a custom message widget — "Accept
/// Invitation", "Cancel", "Details", etc. (see SDK doc section 5). Not to
/// be confused with [ChatInputAction], which lives on the input bar
/// instead of inside a message bubble.
class ChatWidgetAction {
  final String id;
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isPrimary;
  final Color? color;

  const ChatWidgetAction({
    required this.id,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
    this.color,
  });
}

/// Lays out any number of [ChatWidgetAction]s and adapts automatically:
/// an even [Row] of equal-width buttons when they fit, otherwise a
/// [Wrap] so buttons never get clipped or overflow off a narrow card
/// (see doc section 5 — "Horizontal / Wrapped" responsive behavior).
class ChatWidgetActionGroup extends StatelessWidget {
  final List<ChatWidgetAction> actions;
  final ChatTheme theme;

  /// Minimum width to reserve per button before falling back to [Wrap].
  final double minButtonWidth;

  const ChatWidgetActionGroup({
    super.key,
    required this.actions,
    required this.theme,
    this.minButtonWidth = 120,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final requiredWidth = actions.length * minButtonWidth + (actions.length - 1) * 8;
        final buttons = actions.map((a) => _ActionButton(action: a, theme: theme)).toList();

        if (requiredWidth > constraints.maxWidth && actions.length > 1) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: buttons,
          );
        }

        return Row(
          children: [
            for (var i = 0; i < buttons.length; i++) ...[
              Expanded(child: buttons[i]),
              if (i != buttons.length - 1) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final ChatWidgetAction action;
  final ChatTheme theme;

  const _ActionButton({required this.action, required this.theme});

  @override
  Widget build(BuildContext context) {
    final ChatColors colors = theme.colors;
    final tint = action.color ?? colors.primary;

    if (action.isPrimary) {
      return ElevatedButton(
        onPressed: action.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: tint,
          foregroundColor: colors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _label(colors.onPrimary),
      );
    }

    return OutlinedButton(
      onPressed: action.onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: tint,
        side: BorderSide(color: colors.inputBorder),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: _label(tint),
    );
  }

  Widget _label(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (action.icon != null) ...[
          Icon(action.icon, size: 16, color: color),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            action.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
