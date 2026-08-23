import 'package:flutter/material.dart';

import '../../model/chat_link_preview.dart';
import '../../theme/chat_colors.dart';
import '../../theme/chat_theme.dart';

/// Shown above [ChatInputBar] when the host app has detected a URL in
/// the text currently being typed and resolved a preview for it — the
/// "you're about to share this link" card, dismissible before sending.
///
/// The package doesn't watch the text field or fetch metadata itself:
/// detect the URL (e.g. via [extractFirstUrl] with your own debounce),
/// resolve it however you like, and pass the result in as [preview].
/// Leave it `null` and this widget simply doesn't render — same
/// error-isolation stance as the sent-message [LinkPreviewCard].
class LinkPreviewComposerBar extends StatelessWidget {
  final ChatLinkPreview preview;
  final ChatTheme theme;
  final VoidCallback onDismiss;

  const LinkPreviewComposerBar({
    super.key,
    required this.preview,
    required this.theme,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    final domain = preview.siteName ?? Uri.tryParse(preview.url)?.host ?? preview.url;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.spacing.inputPadding, vertical: 8),
      decoration: BoxDecoration(
        color: colors.inputBackground,
        border: Border(top: BorderSide(color: colors.inputBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: preview.imageUrl != null && preview.imageUrl!.isNotEmpty
                  ? Image.network(
                      preview.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(colors),
                    )
                  : _imageFallback(colors),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  preview.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.linkStyle.apply(theme.typography.messageText.copyWith(fontSize: 13)),
                ),
                if (preview.title != null)
                  Text(
                    preview.title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.messageText.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.receiverText,
                    ),
                  )
                else
                  Text(domain, style: theme.typography.timestamp.copyWith(color: colors.hintText)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: colors.hintText),
            onPressed: onDismiss,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _imageFallback(ChatColors colors) {
    return Container(
      color: colors.background,
      child: Icon(Icons.link, color: colors.hintText, size: 20),
    );
  }
}
