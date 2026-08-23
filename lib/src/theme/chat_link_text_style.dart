import 'package:flutter/material.dart';

/// Styling for tappable link spans — inside plain message text
/// ([LinkifiedText]), inside Markdown ([MarkdownText]), and the raw URL
/// line at the top of a [LinkPreviewCard].
///
/// Kept as its own small, constructor-injected value object rather than
/// folded into [ChatTypography] or [ChatColors]: changing how links look
/// should never mean touching unrelated text/color settings. Construct a
/// new [ChatLinkTextStyle] (or [copyWith] the default one) and pass it to
/// [ChatTheme] — nothing else has to change.
class ChatLinkTextStyle {
  final Color color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextDecoration decoration;

  const ChatLinkTextStyle({
    this.color = const Color(0xFF3B82F6),
    this.fontSize,
    this.fontWeight,
    this.decoration = TextDecoration.underline,
  });

  /// Applies this style on top of a [base] text style. `fontSize`/
  /// `fontWeight` only override when explicitly set on this style, so a
  /// link naturally inherits the surrounding text's size unless you
  /// deliberately want it to differ.
  TextStyle apply(TextStyle base) {
    return base.copyWith(
      color: color,
      decoration: decoration,
      fontSize: fontSize ?? base.fontSize,
      fontWeight: fontWeight ?? base.fontWeight,
    );
  }

  ChatLinkTextStyle copyWith({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    TextDecoration? decoration,
  }) {
    return ChatLinkTextStyle(
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      decoration: decoration ?? this.decoration,
    );
  }
}
