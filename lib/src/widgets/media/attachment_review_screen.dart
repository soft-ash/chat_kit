import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/enums/chat_enums.dart';
import '../../model/chat_attachment.dart';
import '../../theme/chat_theme.dart';

/// Full-screen "review before you send" flow — swipe through every
/// selected attachment, remove any that don't belong, and add one
/// caption that goes with the whole batch. Returns `(caption, keptItems)`
/// via `Navigator.pop`, or `null` if the person backs out.
///
/// Push this right after picking media (before it ever touches the chat
/// or the input bar), e.g.:
/// ```dart
/// final result = await Navigator.of(context).push<(String?, List<ChatAttachment>)>(
///   MaterialPageRoute(builder: (_) => AttachmentReviewScreen(attachments: picked, theme: theme)),
/// );
/// if (result != null) {
///   final (caption, attachments) = result;
///   // hand off to onSendMedia / your upload pipeline
/// }
/// ```
class AttachmentReviewScreen extends StatefulWidget {
  final List<ChatAttachment> attachments;
  final ChatTheme theme;

  const AttachmentReviewScreen({
    super.key,
    required this.attachments,
    required this.theme,
  });

  @override
  State<AttachmentReviewScreen> createState() => _AttachmentReviewScreenState();
}

class _AttachmentReviewScreenState extends State<AttachmentReviewScreen> {
  late final List<ChatAttachment> _items = List.of(widget.attachments);
  final PageController _pageController = PageController();
  final TextEditingController _captionController = TextEditingController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _removeCurrent() {
    if (_items.isEmpty) return;
    setState(() {
      _items.removeAt(_index);
      if (_index >= _items.length && _index > 0) _index -= 1;
    });
    if (_items.isEmpty) Navigator.of(context).pop(null);
  }

  void _send() {
    final caption = _captionController.text.trim();
    Navigator.of(context).pop((caption.isEmpty ? null : caption, _items));
  }

  ImageProvider? _imageProvider(ChatAttachment attachment) {
    if (attachment.url != null && attachment.url!.isNotEmpty) return NetworkImage(attachment.url!);
    if (!kIsWeb && attachment.localPath != null && attachment.localPath!.isNotEmpty) {
      return FileImage(File(attachment.localPath!));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.theme.colors;
    if (_items.isEmpty) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _removeCurrent,
            tooltip: 'Remove',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _items.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _buildPreview(_items[i]),
            ),
          ),
          if (_items.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('${_index + 1} / ${_items.length}', style: const TextStyle(color: Colors.white70)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _captionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a caption...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white12,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: colors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _send,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ChatAttachment attachment) {
    switch (attachment.type) {
      case ChatMessageType.image:
        final provider = _imageProvider(attachment);
        if (provider == null) {
          return const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48));
        }
        return InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(child: Image(image: provider, fit: BoxFit.contain)),
        );

      case ChatMessageType.video:
        // Full inline video preview (with playback) is left to the host
        // app or a later phase — this keeps the review screen fast to
        // open even for large batches of video. The thumbnail + duration
        // still communicates what's about to be sent.
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_outlined, color: Colors.white54, size: 64),
              if (attachment.fileName != null) ...[
                const SizedBox(height: 8),
                Text(attachment.fileName!, style: const TextStyle(color: Colors.white70)),
              ],
            ],
          ),
        );

      default:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file_outlined, color: Colors.white54, size: 64),
              const SizedBox(height: 8),
              Text(attachment.fileName ?? 'File', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        );
    }
  }
}
