import 'package:url_launcher/url_launcher.dart';

/// Only ever launches `http`/`https`. `javascript:`, `data:`, `file:`,
/// and any other scheme are refused outright — even if they somehow end
/// up in message text or resolved link-preview metadata (see doc
/// section 17, URL security: "avoid blindly supporting unsafe schemes").
Future<bool> launchSafeUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
