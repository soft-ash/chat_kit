import 'package:flutter/material.dart';

import '../../theme/chat_theme.dart';

/// A thin banner for surfacing call state inside the chat screen —
/// "Calling GoldenHour...", "In call · 02:14", etc. Drop it into
/// [ChatLayers.aboveMessages] or [ChatLayers.overlay] while a call is
/// active; the package tracks none of this state itself, [label] and the
/// visibility of the banner are entirely host-driven.
class CallStatusBanner extends StatelessWidget {
  final ChatTheme theme;
  final String label;
  final VoidCallback onEndCall;
  final IconData icon;

  const CallStatusBanner({
    super.key,
    required this.theme,
    required this.label,
    required this.onEndCall,
    this.icon = Icons.call,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Material(
      color: colors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: colors.onPrimary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.typography.messageText.copyWith(color: colors.onPrimary, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.call_end, color: colors.onPrimary),
                onPressed: onEndCall,
                splashRadius: 18,
                tooltip: 'End call',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
