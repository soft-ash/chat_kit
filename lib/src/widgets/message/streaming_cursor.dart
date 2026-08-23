import 'package:flutter/material.dart';

/// Small blinking cursor appended after in-progress AI streaming text —
/// signals "still generating" without a separate loading spinner eating
/// space in the bubble. Disposes its own [AnimationController], same
/// no-leaks discipline as [TypingIndicatorBubble].
class StreamingCursor extends StatefulWidget {
  final Color color;
  final double height;

  const StreamingCursor({super.key, required this.color, this.height = 16});

  @override
  State<StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<StreamingCursor> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: widget.height,
        margin: const EdgeInsets.only(left: 2),
        color: widget.color,
      ),
    );
  }
}
