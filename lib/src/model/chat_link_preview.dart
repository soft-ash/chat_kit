import '../core/utils/safe_json.dart';

/// Resolved OpenGraph-style metadata for a URL detected inside a text
/// message. Resolution can fail independently of message delivery — a
/// message with a link always renders even if [ChatLinkPreview] never
/// arrives (see error-isolation requirements).
class ChatLinkPreview {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;

  /// Optional small metrics line shown above the title, e.g.
  /// `"32K views · 4.2K reactions"` — the kind of engagement summary
  /// Facebook/YouTube share cards include. Purely cosmetic; leave `null`
  /// for sources that don't have this data.
  final String? statsLabel;

  const ChatLinkPreview({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    this.statsLabel,
  });

  factory ChatLinkPreview.fromJson(Map<String, dynamic> json) {
    return ChatLinkPreview(
      url: SafeJson.string(json, 'url'),
      title: SafeJson.stringOrNull(json, 'title'),
      description: SafeJson.stringOrNull(json, 'description'),
      imageUrl: SafeJson.stringOrNull(json, 'imageUrl'),
      siteName: SafeJson.stringOrNull(json, 'siteName'),
      statsLabel: SafeJson.stringOrNull(json, 'statsLabel'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (siteName != null) 'siteName': siteName,
      if (statsLabel != null) 'statsLabel': statsLabel,
    };
  }
}
