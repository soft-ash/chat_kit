import 'package:flutter/material.dart';

import '../../model/chat_message.dart';

/// A single row in the long-press message action menu — "Reply",
/// "Forward", "Copy", "Edit", "Delete", "Pin", "Save", "Share", "Report",
/// "Translate", or literally anything the host app wants ("Create task",
/// "Generate AI summary", "Pay", ...). No package modification is
/// required to add, remove, or reorder these (see SDK doc section 4).
class ChatMessageAction {
  final String id;
  final String label;
  final IconData icon;
  final void Function(ChatMessage message) onPressed;
  final bool isDestructive;

  const ChatMessageAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });
}

/// Ready-made builders for the common actions listed in doc section 4.
/// Purely a convenience — each one is a plain [ChatMessageAction] you
/// could just as easily construct yourself, mix with your own actions,
/// or omit entirely.
abstract final class ChatDefaultActions {
  static ChatMessageAction reply(void Function(ChatMessage) onPressed) => ChatMessageAction(
        id: 'reply',
        label: 'Reply',
        icon: Icons.reply,
        onPressed: onPressed,
      );

  static ChatMessageAction forward(void Function(ChatMessage) onPressed) => ChatMessageAction(
        id: 'forward',
        label: 'Forward',
        icon: Icons.forward,
        onPressed: onPressed,
      );

  static ChatMessageAction copy(void Function(ChatMessage) onPressed) => ChatMessageAction(
        id: 'copy',
        label: 'Copy',
        icon: Icons.copy_outlined,
        onPressed: onPressed,
      );

  static ChatMessageAction edit(void Function(ChatMessage) onPressed) => ChatMessageAction(
        id: 'edit',
        label: 'Edit',
        icon: Icons.edit_outlined,
        onPressed: onPressed,
      );

  static ChatMessageAction pin(void Function(ChatMessage) onPressed) => ChatMessageAction(
        id: 'pin',
        label: 'Pin',
        icon: Icons.push_pin_outlined,
        onPressed: onPressed,
      );

  static ChatMessageAction save(void Function(ChatMessage) onPressed) => ChatMessageAction(
        id: 'save',
        label: 'Save',
        icon: Icons.bookmark_border,
        onPressed: onPressed,
      );

  static ChatMessageAction share(void Function(ChatMessage) onPressed) => ChatMessageAction(
        id: 'share',
        label: 'Share',
        icon: Icons.share_outlined,
        onPressed: onPressed,
      );

  static ChatMessageAction translate(void Function(ChatMessage) onPressed) => ChatMessageAction(
        id: 'translate',
        label: 'Translate',
        icon: Icons.translate_outlined,
        onPressed: onPressed,
      );

  static ChatMessageAction report(void Function(ChatMessage) onPressed) => ChatMessageAction(
        id: 'report',
        label: 'Report',
        icon: Icons.flag_outlined,
        onPressed: onPressed,
        isDestructive: true,
      );

  static ChatMessageAction delete(void Function(ChatMessage) onPressed) => ChatMessageAction(
        id: 'delete',
        label: 'Delete',
        icon: Icons.delete_outline,
        onPressed: onPressed,
        isDestructive: true,
      );

  /// Regenerates an AI response — wire to your model/API call, then
  /// `chatController.startStreamingMessage(...)` for the new answer.
  static ChatMessageAction regenerate(void Function(ChatMessage) onPressed) => ChatMessageAction(
        id: 'regenerate',
        label: 'Regenerate',
        icon: Icons.refresh,
        onPressed: onPressed,
      );

  /// Stops an in-progress AI stream — wire to cancelling your model/API
  /// request, then `chatController.completeStreamingMessage(...)`.
  static ChatMessageAction stopGenerating(void Function(ChatMessage) onPressed) => ChatMessageAction(
        id: 'stop_generating',
        label: 'Stop generating',
        icon: Icons.stop_circle_outlined,
        onPressed: onPressed,
        isDestructive: true,
      );
}
