import 'package:flutter/material.dart';

import '../../core/enums/chat_enums.dart';
import '../../core/utils/file_size_format.dart';
import '../../model/chat_attachment.dart';
import '../../theme/chat_colors.dart';
import '../../theme/chat_theme.dart';
import 'media_upload_overlay.dart';

/// Document/file attachment: type icon, filename, size, and upload/retry
/// state. Actually opening the file — via a native viewer, a share sheet,
/// or a browser download — is the host app's decision; this widget only
/// surfaces the tap through [onOpen] (doc section 18, host app owns
/// business logic).
class ChatDocumentMessage extends StatelessWidget {
  final ChatAttachment attachment;
  final ChatMessageStatus status;
  final ChatTheme theme;
  final bool isMe;
  final VoidCallback? onOpen;
  final VoidCallback? onRetry;

  const ChatDocumentMessage({
    super.key,
    required this.attachment,
    required this.status,
    required this.theme,
    required this.isMe,
    this.onOpen,
    this.onRetry,
  });

  IconData _iconFor(String? fileName) {
    final ext = (fileName ?? '').split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChatColors colors = theme.colors;
    final textColor = isMe ? colors.senderText : colors.receiverText;
    final busy = status == ChatMessageStatus.sending || status == ChatMessageStatus.failed;

    return GestureDetector(
      onTap: attachment.isUploaded ? onOpen : null,
      child: SizedBox(
        width: 220,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: busy
                  ? MediaUploadOverlay(status: status, progress: attachment.uploadProgress, onRetry: onRetry)
                  : Icon(_iconFor(attachment.fileName), color: textColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attachment.fileName ?? 'Document',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.messageText.copyWith(color: textColor, fontSize: 14),
                  ),
                  if (attachment.fileSizeBytes != null)
                    Text(
                      formatFileSize(attachment.fileSizeBytes),
                      style: theme.typography.timestamp.copyWith(color: textColor.withValues(alpha: 0.7)),
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
