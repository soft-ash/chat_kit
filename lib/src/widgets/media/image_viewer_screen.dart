import 'package:flutter/material.dart';

/// Full-resolution, pinch-to-zoom image viewer. Only ever loads the
/// full-size image when the user explicitly opens it from a bubble — the
/// message list itself never decodes anything beyond the thumbnail (see
/// doc section 21, media performance).
class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Hero(
            tag: heroTag ?? imageUrl,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 48,
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const CircularProgressIndicator(color: Colors.white54);
              },
            ),
          ),
        ),
      ),
    );
  }
}
