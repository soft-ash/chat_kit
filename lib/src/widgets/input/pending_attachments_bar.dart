import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/enums/chat_enums.dart';
import '../../model/chat_attachment.dart';
import '../../theme/chat_theme.dart';

/// Shown above [ChatInputBar] when the person has picked (but not yet
/// sent) one or more attachments — the WhatsApp/Telegram "selected media"
/// strip. Each thumbnail has its own remove button, and the whole row
/// scrolls horizontally so any number of attachments fits on any screen
/// width (same responsive pattern as [ChatInputActionPanel]).
///
/// The package never picks files itself — the host app uses `image_picker`,
/// `file_picker`, the camera, etc. and hands the resulting local files to
/// this widget as a `List<ChatAttachment>` with [ChatAttachment.localPath]
/// set (see doc section 18, media system: "the package should not upload
/// files itself by default").
class PendingAttachmentsBar extends StatelessWidget {
  final List<ChatAttachment> attachments;
  final ChatTheme theme;
  final ValueChanged<ChatAttachment>? onRemove;
  final ValueChanged<ChatAttachment>? onTapPreview;

  const PendingAttachmentsBar({
    super.key,
    required this.attachments,
    required this.theme,
    this.onRemove,
    this.onTapPreview,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    final colors = theme.colors;

    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.inputBackground,
        border: Border(top: BorderSide(color: colors.inputBorder)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return _PendingThumb(
            attachment: attachment,
            theme: theme,
            onTap: onTapPreview == null ? null : () => onTapPreview!(attachment),
            onRemove: onRemove == null ? null : () => onRemove!(attachment),
          );
        },
      ),
    );
  }
}

class _PendingThumb extends StatelessWidget {
  final ChatAttachment attachment;
  final ChatTheme theme;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _PendingThumb({
    required this.attachment,
    required this.theme,
    this.onTap,
    this.onRemove,
  });

  ImageProvider? _imageProvider() {
    final remote = attachment.thumbnailUrl ?? attachment.url;
    if (remote != null && remote.isNotEmpty) return NetworkImage(remote);
    if (!kIsWeb && attachment.localPath != null && attachment.localPath!.isNotEmpty) {
      return FileImage(File(attachment.localPath!));
    }
    return null;
  }

  IconData _fallbackIcon() {
    switch (attachment.type) {
      case ChatMessageType.video:
        return Icons.videocam_outlined;
      case ChatMessageType.audio:
        return Icons.mic_none;
      case ChatMessageType.document:
        return Icons.insert_drive_file_outlined;
      default:
        return Icons.image_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    final provider = attachment.type == ChatMessageType.image || attachment.type == ChatMessageType.video ? _imageProvider() : null;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 64,
              height: 64,
              color: colors.background,
              child: provider != null
                  ? Image(image: provider, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(_fallbackIcon(), color: colors.hintText))
                  : Icon(_fallbackIcon(), color: colors.hintText),
            ),
          ),
          if (attachment.type == ChatMessageType.video)
            const Positioned.fill(
              child: Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 22)),
            ),
          if (onRemove != null)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
