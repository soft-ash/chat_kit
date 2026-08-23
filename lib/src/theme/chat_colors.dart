import 'package:flutter/material.dart';

/// Color palette for the default chat widgets. Every field can be
/// overridden; [ChatColors.light]/[ChatColors.dark] are just sensible
/// starting points, not the only option — pass a fully custom instance,
/// or build one from your app's existing design tokens.
class ChatColors {
  final Color senderBubble;
  final Color senderText;
  final Color receiverBubble;
  final Color receiverText;

  final Color background;
  final Color inputBackground;
  final Color inputBorder;
  final Color hintText;

  final Color primary;
  final Color onPrimary;

  final Color timestamp;
  final Color linkText;
  final Color danger;
  final Color success;

  /// Optional gradient for the sender bubble; when set, it takes
  /// precedence over [senderBubble] in the default bubble widget.
  final Gradient? senderBubbleGradient;

  /// Optional gradient/color for the whole chat background layer.
  final Gradient? backgroundGradient;

  const ChatColors({
    required this.senderBubble,
    required this.senderText,
    required this.receiverBubble,
    required this.receiverText,
    required this.background,
    required this.inputBackground,
    required this.inputBorder,
    required this.hintText,
    required this.primary,
    required this.onPrimary,
    required this.timestamp,
    required this.linkText,
    required this.danger,
    required this.success,
    this.senderBubbleGradient,
    this.backgroundGradient,
  });

  factory ChatColors.light() {
    return const ChatColors(
      senderBubble: Color(0xFF4F46E5),
      senderText: Colors.white,
      receiverBubble: Color(0xFFF1F2F6),
      receiverText: Color(0xFF1A1A2E),
      background: Colors.white,
      inputBackground: Color(0xFFF5F5F7),
      inputBorder: Color(0xFFE0E0E6),
      hintText: Color(0xFF9A9AA5),
      primary: Color(0xFF4F46E5),
      onPrimary: Colors.white,
      timestamp: Color(0xFF9A9AA5),
      linkText: Color(0xFF3B82F6),
      danger: Color(0xFFE5484D),
      success: Color(0xFF2FB344),
    );
  }

  factory ChatColors.dark() {
    return const ChatColors(
      senderBubble: Color(0xFF6366F1),
      senderText: Colors.white,
      receiverBubble: Color(0xFF23232B),
      receiverText: Color(0xFFECECF1),
      background: Color(0xFF121218),
      inputBackground: Color(0xFF1C1C24),
      inputBorder: Color(0xFF2C2C36),
      hintText: Color(0xFF7A7A85),
      primary: Color(0xFF6366F1),
      onPrimary: Colors.white,
      timestamp: Color(0xFF7A7A85),
      linkText: Color(0xFF60A5FA),
      danger: Color(0xFFF87171),
      success: Color(0xFF4ADE80),
    );
  }

  ChatColors copyWith({
    Color? senderBubble,
    Color? senderText,
    Color? receiverBubble,
    Color? receiverText,
    Color? background,
    Color? inputBackground,
    Color? inputBorder,
    Color? hintText,
    Color? primary,
    Color? onPrimary,
    Color? timestamp,
    Color? linkText,
    Color? danger,
    Color? success,
    Gradient? senderBubbleGradient,
    Gradient? backgroundGradient,
  }) {
    return ChatColors(
      senderBubble: senderBubble ?? this.senderBubble,
      senderText: senderText ?? this.senderText,
      receiverBubble: receiverBubble ?? this.receiverBubble,
      receiverText: receiverText ?? this.receiverText,
      background: background ?? this.background,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      hintText: hintText ?? this.hintText,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      timestamp: timestamp ?? this.timestamp,
      linkText: linkText ?? this.linkText,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      senderBubbleGradient: senderBubbleGradient ?? this.senderBubbleGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    );
  }
}

/// Text styles for the default chat widgets.
class ChatTypography {
  final TextStyle messageText;
  final TextStyle senderName;
  final TextStyle timestamp;
  final TextStyle inputText;
  final TextStyle inputHint;
  final TextStyle systemMessage;

  const ChatTypography({
    this.messageText = const TextStyle(fontSize: 15, height: 1.35),
    this.senderName = const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    this.timestamp = const TextStyle(fontSize: 11),
    this.inputText = const TextStyle(fontSize: 15),
    this.inputHint = const TextStyle(fontSize: 15),
    this.systemMessage = const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
  });

  ChatTypography copyWith({
    TextStyle? messageText,
    TextStyle? senderName,
    TextStyle? timestamp,
    TextStyle? inputText,
    TextStyle? inputHint,
    TextStyle? systemMessage,
  }) {
    return ChatTypography(
      messageText: messageText ?? this.messageText,
      senderName: senderName ?? this.senderName,
      timestamp: timestamp ?? this.timestamp,
      inputText: inputText ?? this.inputText,
      inputHint: inputHint ?? this.inputHint,
      systemMessage: systemMessage ?? this.systemMessage,
    );
  }
}
