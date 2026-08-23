import 'package:flutter/material.dart';

import '../../core/enums/chat_enums.dart';

/// Small circular progress ring drawn over a media thumbnail while it's
/// uploading, or a retry icon when the attachment failed to send. Shared
/// across image/video/audio/document widgets so upload UX stays
/// consistent everywhere (see doc section 25, offline/retry).
class MediaUploadOverlay extends StatelessWidget {
  final ChatMessageStatus status;
  final double progress; // 0.0–1.0
  final VoidCallback? onRetry;

  const MediaUploadOverlay({
    super.key,
    required this.status,
    this.progress = 0,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (status == ChatMessageStatus.failed) {
      return _badge(
        child: GestureDetector(
          onTap: onRetry,
          child: const Icon(Icons.refresh, color: Colors.white, size: 20),
        ),
      );
    }
    if (status == ChatMessageStatus.sending) {
      return _badge(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: progress > 0 && progress < 1 ? progress : null,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _badge({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
      padding: const EdgeInsets.all(6),
      child: child,
    );
  }
}
