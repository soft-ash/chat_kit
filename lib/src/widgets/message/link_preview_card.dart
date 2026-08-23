import 'package:flutter/material.dart';

import '../../core/utils/safe_url_launcher.dart';
import '../../model/chat_link_preview.dart';
import '../../theme/chat_theme.dart';

/// Renders resolved OpenGraph metadata for a link found in a text
/// message — image, title, description — shown under the bubble text,
/// like Facebook/WhatsApp/iMessage link cards.
///
/// Two layouts, both driven by constructor fields so nothing here is
/// hardcoded:
/// - [showRawUrl] `true` (default): the URL itself is shown as a
///   tappable line above the image — the Facebook-style "share" layout.
/// - [showRawUrl] `false`: a quieter domain line at the bottom instead —
///   the classic iMessage/WhatsApp layout.
///
/// Resolving [preview] is the host app's job: detect the URL (e.g. via
/// [extractFirstUrl]), fetch OpenGraph metadata however you like, and set
/// it on `ChatMessage.linkPreview`. This widget only draws what's already
/// there — a message with a link still renders instantly even before (or
/// if) the preview ever resolves (doc section 24, error isolation), and
/// YouTube/Facebook metadata specifically may be restricted or behave
/// differently depending on their servers (doc section 11's caveat).
class LinkPreviewCard extends StatelessWidget {
  final ChatLinkPreview preview;
  final ChatTheme theme;
  final ValueChanged<String>? onTap;
  final bool showRawUrl;

  const LinkPreviewCard({
    super.key,
    required this.preview,
    required this.theme,
    this.onTap,
    this.showRawUrl = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    final domain = preview.siteName ?? Uri.tryParse(preview.url)?.host ?? preview.url;

    return GestureDetector(
      onTap: () => onTap != null ? onTap!(preview.url) : launchSafeUrl(preview.url),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: colors.inputBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.inputBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showRawUrl)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                child: Text(
                  preview.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.linkStyle.apply(theme.typography.messageText.copyWith(fontSize: 12)),
                ),
              ),
            if (preview.imageUrl != null && preview.imageUrl!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  preview.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (preview.statsLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        preview.statsLabel!,
                        style: theme.typography.timestamp.copyWith(color: colors.hintText),
                      ),
                    ),
                  if (preview.title != null)
                    Text(
                      preview.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.messageText.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.receiverText,
                        fontSize: 13,
                      ),
                    ),
                  if (preview.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        preview.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.timestamp.copyWith(color: colors.hintText),
                      ),
                    ),
                  if (!showRawUrl)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(domain, style: theme.typography.timestamp.copyWith(color: theme.linkStyle.color)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
