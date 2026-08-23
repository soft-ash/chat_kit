import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/enums/chat_enums.dart';
import '../../model/chat_attachment.dart';
import '../../theme/chat_theme.dart';
import 'image_viewer_screen.dart';
import 'media_upload_overlay.dart';

/// Renders an image attachment as a fixed-size thumbnail inside the
/// bubble. Tapping an uploaded image opens [ImageViewerScreen] for a
/// full-resolution, pinch-to-zoom view — the thumbnail is all that's ever
/// decoded into the message list itself (doc section 21).
///
/// While a message is still `sending`, this renders straight from
/// [ChatAttachment.localPath] instead of waiting for the host app's
/// upload to finish — but only outside web, where `dart:io File` isn't
/// meaningful (Flutter's web SDK stubs `dart:io` at runtime rather than
/// failing to compile, so this guard has to be explicit).
class ChatImageMessage extends StatelessWidget {
  final ChatAttachment attachment;
  final ChatMessageStatus status;
  final ChatTheme theme;
  final VoidCallback? onRetry;

  static const double _dimension = 220;

  const ChatImageMessage({
    super.key,
    required this.attachment,
    required this.status,
    required this.theme,
    this.onRetry,
  });

  ImageProvider? _provider() {
    final remote = attachment.thumbnailUrl ?? attachment.url;
    if (remote != null && remote.isNotEmpty) {
      return NetworkImage(remote);
    }
    if (!kIsWeb && attachment.localPath != null && attachment.localPath!.isNotEmpty) {
      return FileImage(File(attachment.localPath!));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider();
    final radius = BorderRadius.circular(theme.dimensions.messageBubbleRadius - 6);
    final busy = status == ChatMessageStatus.sending || status == ChatMessageStatus.failed;

    return GestureDetector(
      onTap: attachment.isUploaded
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ImageViewerScreen(imageUrl: attachment.url!, heroTag: attachment.id),
                ),
              )
          : null,
      child: ClipRRect(
        borderRadius: radius,
        child: Hero(
          tag: attachment.id,
          child: SizedBox(
            width: _dimension,
            height: _dimension,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (provider != null)
                  Image(
                    image: provider,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image_outlined),
                  )
                else
                  _placeholder(Icons.image_outlined),
                if (busy)
                  Center(
                    child: MediaUploadOverlay(
                      status: status,
                      progress: attachment.uploadProgress,
                      onRetry: onRetry,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(IconData icon) {
    return Container(
      color: theme.colors.inputBackground,
      child: Icon(icon, color: theme.colors.hintText, size: 32),
    );
  }
}
