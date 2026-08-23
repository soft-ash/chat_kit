import 'package:flutter/material.dart';

/// A single configurable input-bar action — "Games", "Photo", "Voice",
/// "Date" in the reference design, but it could just as easily be
/// Location, Poll, GIF, Payment, AI, or Calendar. No package modification
/// is required to add, remove, or reorder these (see SDK doc section 9).
class ChatInputAction {
  final String id;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const ChatInputAction({
    required this.id,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });
}

/// Groups related actions (e.g. a "media" group vs. a "business" group)
/// so the host app can organize primary/secondary/expandable sets without
/// the input widget needing to know the difference (see doc section 10).
class ChatActionGroup {
  final String id;
  final List<ChatInputAction> actions;

  const ChatActionGroup({
    required this.id,
    required this.actions,
  });
}
