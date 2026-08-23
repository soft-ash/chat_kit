import 'package:flutter/material.dart';

import 'chat_background.dart';

/// Paints [background] (if any) behind [child]. A `null` background just
/// returns [child] untouched — the message list sits on whatever
/// [Scaffold]/parent background is already there, matching plain default
/// behavior.
class ChatBackgroundView extends StatelessWidget {
  final ChatBackground? background;
  final Widget child;

  const ChatBackgroundView({
    super.key,
    required this.background,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background;
    if (bg == null) return child;

    switch (bg.type) {
      case ChatBackgroundType.color:
        return ColoredBox(color: bg.color!, child: child);

      case ChatBackgroundType.gradient:
        return DecoratedBox(decoration: BoxDecoration(gradient: bg.gradient), child: child);

      case ChatBackgroundType.image:
        return Stack(
          fit: StackFit.expand,
          children: [
            Image(image: bg.image!, fit: bg.imageFit),
            child,
          ],
        );

      case ChatBackgroundType.custom:
        return Stack(
          fit: StackFit.expand,
          children: [
            bg.custom!,
            child,
          ],
        );
    }
  }
}
