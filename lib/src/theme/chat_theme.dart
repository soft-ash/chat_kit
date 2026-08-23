import 'package:flutter/material.dart';

import 'chat_colors.dart';
import 'chat_dimensions.dart';
import 'chat_link_text_style.dart';

/// The single object the host app passes to configure every visual aspect
/// of the chat UI. Compose only the pieces you want to override — anything
/// omitted falls back to sensible defaults via [ChatTheme.light]/[dark].
class ChatTheme {
  final ChatColors colors;
  final ChatTypography typography;
  final ChatDimensions dimensions;
  final ChatSpacing spacing;

  /// Styling for tappable links, kept separate so it can be swapped
  /// without touching [colors] or [typography] (see [ChatLinkTextStyle]).
  final ChatLinkTextStyle linkStyle;

  const ChatTheme({
    required this.colors,
    required this.typography,
    required this.dimensions,
    required this.spacing,
    this.linkStyle = const ChatLinkTextStyle(),
  });

  factory ChatTheme.light() {
    return ChatTheme(
      colors: ChatColors.light(),
      typography: const ChatTypography(),
      dimensions: const ChatDimensions(),
      spacing: const ChatSpacing(),
      linkStyle: const ChatLinkTextStyle(),
    );
  }

  factory ChatTheme.dark() {
    return ChatTheme(
      colors: ChatColors.dark(),
      typography: const ChatTypography(),
      dimensions: const ChatDimensions(),
      spacing: const ChatSpacing(),
      linkStyle: const ChatLinkTextStyle(color: Color(0xFF60A5FA)),
    );
  }

  ChatTheme copyWith({
    ChatColors? colors,
    ChatTypography? typography,
    ChatDimensions? dimensions,
    ChatSpacing? spacing,
    ChatLinkTextStyle? linkStyle,
  }) {
    return ChatTheme(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      dimensions: dimensions ?? this.dimensions,
      spacing: spacing ?? this.spacing,
      linkStyle: linkStyle ?? this.linkStyle,
    );
  }
}
