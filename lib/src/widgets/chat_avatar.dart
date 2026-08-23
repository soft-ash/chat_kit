import 'package:flutter/material.dart';

import '../model/chat_user.dart';
import '../theme/chat_colors.dart';

/// Lets the host app fully replace avatar rendering (e.g. draw a
/// [CircadianAvatar]-style widget) without touching bubble/list code.
typedef ChatAvatarBuilder = Widget Function(BuildContext context, ChatUser? user, double size);

/// Default avatar: network image with graceful fallback to initials on a
/// tinted circle — never leaves a blank/broken-image hole if [ChatUser]
/// has no photo or the network image fails to load.
class ChatAvatar extends StatelessWidget {
  final ChatUser? user;
  final double size;
  final ChatColors colors;

  const ChatAvatar({
    super.key,
    required this.user,
    required this.size,
    required this.colors,
  });

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user?.avatarUrl;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Container(
          color: colors.primary.withValues(alpha: 0.15),
          child: (avatarUrl != null && avatarUrl.isNotEmpty)
              ? Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(),
                )
              : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Text(
        _initials(user?.name ?? ''),
        style: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
