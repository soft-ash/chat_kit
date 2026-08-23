import 'package:flutter/material.dart';

enum ChatBackgroundType { color, gradient, image, custom }

/// Configures the chat screen's background — a solid [color], a
/// [gradient], a background [image], or a fully [custom] widget (an
/// animated pattern, a particle effect, whatever). Exactly one of these
/// is ever set per instance; use the named constructors rather than the
/// private default one.
class ChatBackground {
  final ChatBackgroundType type;
  final Color? color;
  final Gradient? gradient;
  final ImageProvider? image;
  final BoxFit imageFit;
  final Widget? custom;

  const ChatBackground._({
    required this.type,
    this.color,
    this.gradient,
    this.image,
    this.imageFit = BoxFit.cover,
    this.custom,
  });

  factory ChatBackground.color(Color color) => ChatBackground._(type: ChatBackgroundType.color, color: color);

  factory ChatBackground.gradient(Gradient gradient) =>
      ChatBackground._(type: ChatBackgroundType.gradient, gradient: gradient);

  factory ChatBackground.image(ImageProvider image, {BoxFit fit = BoxFit.cover}) =>
      ChatBackground._(type: ChatBackgroundType.image, image: image, imageFit: fit);

  factory ChatBackground.custom(Widget widget) => ChatBackground._(type: ChatBackgroundType.custom, custom: widget);
}
