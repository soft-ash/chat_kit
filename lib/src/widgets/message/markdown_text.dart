import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/utils/safe_url_launcher.dart';
import '../../theme/chat_link_text_style.dart';

enum _MdBlockType { heading, code, quote, listItem, paragraph }

class _MdBlock {
  final _MdBlockType type;
  final String text;
  final int level;
  const _MdBlock(this.type, this.text, {this.level = 0});
}

/// A deliberately small Markdown renderer tuned for chat/AI messages —
/// headings, `**bold**`, `*italic*`, `` `inline code` ``, fenced code
/// blocks, blockquotes, unordered lists, and `[text](url)` links.
///
/// This is **not** a CommonMark/GFM implementation (see doc section 10 —
/// "don't attempt the full spec initially"), but it's enough for typical
/// AI responses and formatted chat text without pulling in a heavy
/// Markdown dependency. Swap this widget out later for something more
/// complete if you outgrow it — nothing else in the package depends on
/// its internals.
class MarkdownText extends StatefulWidget {
  final String data;
  final TextStyle baseStyle;
  final ChatLinkTextStyle linkStyle;
  final Color codeBackground;
  final ValueChanged<String>? onLinkTap;

  const MarkdownText({
    super.key,
    required this.data,
    required this.baseStyle,
    required this.codeBackground,
    this.linkStyle = const ChatLinkTextStyle(),
    this.onLinkTap,
  });

  @override
  State<MarkdownText> createState() => _MarkdownTextState();
}

class _MarkdownTextState extends State<MarkdownText> {
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
    final blocks = _parseBlocks(widget.data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks.map(_buildBlock).toList(),
    );
  }

  List<_MdBlock> _parseBlocks(String data) {
    final lines = data.split('\n');
    final blocks = <_MdBlock>[];
    final buffer = StringBuffer();
    var i = 0;

    void flushParagraph() {
      final text = buffer.toString().trim();
      if (text.isNotEmpty) blocks.add(_MdBlock(_MdBlockType.paragraph, text));
      buffer.clear();
    }

    while (i < lines.length) {
      final line = lines[i];

      if (line.trimLeft().startsWith('```')) {
        flushParagraph();
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trimLeft().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        blocks.add(_MdBlock(_MdBlockType.code, codeLines.join('\n')));
        i++;
        continue;
      }

      final headingMatch = RegExp(r'^(#{1,3})\s+(.*)').firstMatch(line);
      if (headingMatch != null) {
        flushParagraph();
        blocks.add(_MdBlock(
          _MdBlockType.heading,
          headingMatch.group(2)!.trim(),
          level: headingMatch.group(1)!.length,
        ));
        i++;
        continue;
      }

      if (line.trimLeft().startsWith('> ')) {
        flushParagraph();
        blocks.add(_MdBlock(_MdBlockType.quote, line.trimLeft().substring(2)));
        i++;
        continue;
      }

      if (RegExp(r'^\s*[-*]\s+').hasMatch(line)) {
        flushParagraph();
        blocks.add(_MdBlock(_MdBlockType.listItem, line.replaceFirst(RegExp(r'^\s*[-*]\s+'), '')));
        i++;
        continue;
      }

      if (line.trim().isEmpty) {
        flushParagraph();
        i++;
        continue;
      }

      buffer.writeln(line);
      i++;
    }
    flushParagraph();
    return blocks;
  }

  Widget _buildBlock(_MdBlock block) {
    final baseSize = widget.baseStyle.fontSize ?? 15;

    switch (block.type) {
      case _MdBlockType.heading:
        final boost = block.level == 1 ? 6.0 : (block.level == 2 ? 4.0 : 2.0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _inlineSpan(
            block.text,
            widget.baseStyle.copyWith(fontSize: baseSize + boost, fontWeight: FontWeight.w700),
          ),
        );

      case _MdBlockType.code:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: widget.codeBackground, borderRadius: BorderRadius.circular(8)),
          child: Text(
            block.text,
            style: widget.baseStyle.copyWith(fontFamily: 'monospace', fontSize: baseSize - 1),
          ),
        );

      case _MdBlockType.quote:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: widget.linkStyle.color, width: 3))),
          child: _inlineSpan(block.text, widget.baseStyle.copyWith(fontStyle: FontStyle.italic)),
        );

      case _MdBlockType.listItem:
        return Padding(
          padding: const EdgeInsets.only(left: 4, top: 1, bottom: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: widget.baseStyle),
              Expanded(child: _inlineSpan(block.text, widget.baseStyle)),
            ],
          ),
        );

      case _MdBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: _inlineSpan(block.text, widget.baseStyle),
        );
    }
  }

  /// Applies `**bold**`, `*italic*`, `` `code` ``, and `[label](url)`
  /// within a single block of already-block-parsed text.
  Widget _inlineSpan(String text, TextStyle style) {
    final pattern = RegExp(r'(\*\*.+?\*\*)|(\*.+?\*)|(`.+?`)|(\[.+?\]\(.+?\))');
    final spans = <InlineSpan>[];
    var last = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start), style: style));
      }
      final token = match.group(0)!;

      if (token.startsWith('**')) {
        spans.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: style.copyWith(fontWeight: FontWeight.w700),
        ));
      } else if (token.startsWith('`')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: style.copyWith(
            fontFamily: 'monospace',
            backgroundColor: widget.codeBackground,
            fontSize: (style.fontSize ?? 15) - 1,
          ),
        ));
      } else if (token.startsWith('[')) {
        final linkMatch = RegExp(r'\[(.+?)\]\((.+?)\)').firstMatch(token)!;
        final label = linkMatch.group(1)!;
        final url = linkMatch.group(2)!;
        final recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onLinkTap != null ? widget.onLinkTap!(url) : launchSafeUrl(url);
        _recognizers.add(recognizer);
        spans.add(TextSpan(
          text: label,
          style: widget.linkStyle.apply(style),
          recognizer: recognizer,
        ));
      } else {
        // *italic*
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: style.copyWith(fontStyle: FontStyle.italic),
        ));
      }
      last = match.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: style));
    }

    return Text.rich(TextSpan(children: spans));
  }
}
