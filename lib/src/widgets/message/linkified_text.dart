import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/utils/safe_url_launcher.dart';
import '../../core/utils/url_detector.dart';
import '../../theme/chat_link_text_style.dart';

/// Renders [text] as plain runs, except any `http(s)` URL substring
/// becomes a tappable span styled by [linkStyle], opening via
/// [launchSafeUrl] — or [onLinkTap] if the host app wants to intercept it
/// (e.g. to open an in-app browser, log analytics, or show a
/// confirmation dialog before leaving the app).
///
/// A [StatefulWidget] rather than a stateless helper on purpose: each
/// tappable span needs its own [TapGestureRecognizer], and recognizers
/// must be explicitly disposed or they leak — same "no memory leaks"
/// principle the rest of the SDK follows (doc section 28).
class LinkifiedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final ChatLinkTextStyle linkStyle;
  final ValueChanged<String>? onLinkTap;

  const LinkifiedText({
    super.key,
    required this.text,
    required this.style,
    this.linkStyle = const ChatLinkTextStyle(),
    this.onLinkTap,
  });

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _clearRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clearRecognizers();

    final urls = extractAllUrls(widget.text);
    if (urls.isEmpty) {
      return Text(widget.text, style: widget.style);
    }

    final spans = <InlineSpan>[];
    var remaining = widget.text;

    for (final url in urls) {
      final index = remaining.indexOf(url);
      if (index < 0) continue;

      if (index > 0) {
        spans.add(TextSpan(text: remaining.substring(0, index), style: widget.style));
      }

      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onLinkTap != null ? widget.onLinkTap!(url) : launchSafeUrl(url);
      _recognizers.add(recognizer);

      spans.add(TextSpan(
        text: url,
        style: widget.linkStyle.apply(widget.style),
        recognizer: recognizer,
      ));

      remaining = remaining.substring(index + url.length);
    }

    if (remaining.isNotEmpty) {
      spans.add(TextSpan(text: remaining, style: widget.style));
    }

    return Text.rich(TextSpan(children: spans));
  }
}
