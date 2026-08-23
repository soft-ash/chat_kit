import '../core/constants/chat_constants.dart';

/// Every widget size in the package reads from here instead of hardcoding
/// numbers, so the host app can change height/width/radius/icon sizes
/// globally without touching widget source.
class ChatDimensions {
  final double avatarSize;
  final double avatarSizeSmall;
  final double sendButtonSize;
  final double inputMinHeight;
  final double inputMaxHeight;
  final double maxMessageWidthFactor;
  final double messageBubbleRadius;
  final double actionIconSize;

  const ChatDimensions({
    this.avatarSize = ChatDefaults.avatarSize,
    this.avatarSizeSmall = ChatDefaults.avatarSizeSmall,
    this.sendButtonSize = ChatDefaults.sendButtonSize,
    this.inputMinHeight = ChatDefaults.inputMinHeight,
    this.inputMaxHeight = ChatDefaults.inputMaxHeight,
    this.maxMessageWidthFactor = ChatDefaults.maxMessageWidthFactor,
    this.messageBubbleRadius = ChatDefaults.messageBubbleRadius,
    this.actionIconSize = ChatDefaults.actionIconSize,
  });

  ChatDimensions copyWith({
    double? avatarSize,
    double? avatarSizeSmall,
    double? sendButtonSize,
    double? inputMinHeight,
    double? inputMaxHeight,
    double? maxMessageWidthFactor,
    double? messageBubbleRadius,
    double? actionIconSize,
  }) {
    return ChatDimensions(
      avatarSize: avatarSize ?? this.avatarSize,
      avatarSizeSmall: avatarSizeSmall ?? this.avatarSizeSmall,
      sendButtonSize: sendButtonSize ?? this.sendButtonSize,
      inputMinHeight: inputMinHeight ?? this.inputMinHeight,
      inputMaxHeight: inputMaxHeight ?? this.inputMaxHeight,
      maxMessageWidthFactor: maxMessageWidthFactor ?? this.maxMessageWidthFactor,
      messageBubbleRadius: messageBubbleRadius ?? this.messageBubbleRadius,
      actionIconSize: actionIconSize ?? this.actionIconSize,
    );
  }
}

/// All spacing/padding values used by the package's default widgets.
class ChatSpacing {
  final double messagePadding;
  final double inputPadding;
  final double sectionSpacing;
  final double attachmentSpacing;

  /// Horizontal/vertical padding around the whole message list.
  final double listPaddingHorizontal;
  final double listPaddingVertical;

  /// Gap between two consecutive bubbles from the same sender vs.
  /// a different sender — lets the UI visually "group" consecutive
  /// messages the way WhatsApp/Telegram do.
  final double sameSenderGap;
  final double differentSenderGap;

  const ChatSpacing({
    this.messagePadding = ChatDefaults.messagePadding,
    this.inputPadding = ChatDefaults.inputPadding,
    this.sectionSpacing = ChatDefaults.sectionSpacing,
    this.attachmentSpacing = ChatDefaults.attachmentSpacing,
    this.listPaddingHorizontal = 12,
    this.listPaddingVertical = 8,
    this.sameSenderGap = 2,
    this.differentSenderGap = 12,
  });

  ChatSpacing copyWith({
    double? messagePadding,
    double? inputPadding,
    double? sectionSpacing,
    double? attachmentSpacing,
    double? listPaddingHorizontal,
    double? listPaddingVertical,
    double? sameSenderGap,
    double? differentSenderGap,
  }) {
    return ChatSpacing(
      messagePadding: messagePadding ?? this.messagePadding,
      inputPadding: inputPadding ?? this.inputPadding,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      attachmentSpacing: attachmentSpacing ?? this.attachmentSpacing,
      listPaddingHorizontal: listPaddingHorizontal ?? this.listPaddingHorizontal,
      listPaddingVertical: listPaddingVertical ?? this.listPaddingVertical,
      sameSenderGap: sameSenderGap ?? this.sameSenderGap,
      differentSenderGap: differentSenderGap ?? this.differentSenderGap,
    );
  }
}
