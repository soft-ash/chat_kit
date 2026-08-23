/// Package-wide default values. Every one of these is overridable through
/// [ChatTheme] / [ChatDimensions] / [ChatSpacing] — nothing here should be
/// hardcoded into widgets directly.
abstract final class ChatDefaults {
  static const double avatarSize = 40;
  static const double avatarSizeSmall = 28;
  static const double sendButtonSize = 44;
  static const double inputMinHeight = 48;
  static const double inputMaxHeight = 140;
  static const double maxMessageWidthFactor = 0.78;
  static const double messageBubbleRadius = 18;
  static const double messagePadding = 12;
  static const double inputPadding = 10;
  static const double sectionSpacing = 8;
  static const double attachmentSpacing = 6;
  static const double actionIconSize = 24;

  static const int defaultPageSize = 30;

  static const Duration animationDuration = Duration(milliseconds: 250);
  static const Duration typingDebounce = Duration(milliseconds: 400);
}

/// Reserved metadata keys the package itself may read from a custom
/// message's `metadata` map. Applications are free to add any other keys —
/// these are simply the ones the core SDK understands without a builder.
abstract final class ChatMetadataKeys {
  static const String customType = 'customType';
}
