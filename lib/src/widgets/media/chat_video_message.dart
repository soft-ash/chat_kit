import 'package:flutter/material.dart';

import '../../core/enums/chat_enums.dart';
import '../../core/utils/duration_format.dart';
import '../../model/chat_attachment.dart';
import '../../theme/chat_theme.dart';
import 'media_upload_overlay.dart';
import 'video_player_screen.dart';

/// Renders a video attachment as a static thumbnail with a play button
/// and duration badge. No [VideoPlayerController] exists until the user
/// taps into [VideoPlayerScreen] — scrolling past a hundred video
/// messages never initializes a hundred players (doc section 21).
class ChatVideoMessage extends StatelessWidget {
  final ChatAttachment attachment;
  final ChatMessageStatus status;
  final ChatTheme theme;
  final VoidCallback? onRetry;

  static const double _dimension = 220;

  const ChatVideoMessage({
    super.key,
    required this.attachment,
    required this.status,
    required this.theme,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(theme.dimensions.messageBubbleRadius - 6);
    final thumbnail = attachment.thumbnailUrl;
    final busy = status == ChatMessageStatus.sending || status == ChatMessageStatus.failed;

    return GestureDetector(
      onTap: attachment.isUploaded
          ? () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoUrl: attachment.url!)),
              )
          : null,
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: _dimension,
          height: _dimension,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnail != null && thumbnail.isNotEmpty)
                Image.network(
                  thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              else
                _placeholder(),
              Container(color: Colors.black26),
              const Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
              ),
              if (attachment.duration != null)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      formatDuration(attachment.duration!),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              if (busy)
                Center(
                  child: MediaUploadOverlay(status: status, progress: attachment.uploadProgress, onRetry: onRetry),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: theme.colors.inputBackground,
      child: Icon(Icons.videocam_outlined, color: theme.colors.hintText, size: 32),
    );
  }
}
