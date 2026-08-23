import 'package:flutter/material.dart';

import '../../theme/chat_theme.dart';

/// Animated three-dot "typing..." bubble, styled like a receiver bubble
/// so it sits naturally at the bottom of the message list. Wire it to
/// [ChatState.isTyping] / [ChatState.typingUsers] — [MessageList]'s
/// `typingIndicator` slot expects exactly this shape.
class TypingIndicatorBubble extends StatefulWidget {
  final ChatTheme theme;

  const TypingIndicatorBubble({super.key, required this.theme});

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.theme.colors;
    final spacing = widget.theme.spacing;

    return Padding(
      padding: EdgeInsets.only(
        left: spacing.listPaddingHorizontal,
        bottom: 6,
        top: 2,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.receiverBubble,
            borderRadius: BorderRadius.circular(widget.theme.dimensions.messageBubbleRadius),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) => _dot(i, colors.hintText)),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _dot(int index, Color color) {
    // Each dot's phase is offset by a third of the cycle so they pulse in
    // a wave rather than all together.
    final t = (_controller.value + (index * 0.33)) % 1.0;
    final scale = 0.6 + 0.4 * (1 - (2 * t - 1).abs());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
