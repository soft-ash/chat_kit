import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen video player. The [VideoPlayerController] is created when
/// this screen opens and disposed when it closes — nothing about
/// playback leaks back into the message list (see doc sections 21 and 26,
/// lazy init + memory management). Only network URLs are handled here;
/// a locally-recorded/picked video not yet uploaded simply can't be
/// opened until the host app's upload completes and sets [ChatAttachment.url].
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _initialized = true);
      _controller.play();
    }).catchError((Object e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    });
    _controller.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return const Text("Couldn't play this video", style: TextStyle(color: Colors.white54));
    }
    if (!_initialized) {
      return const CircularProgressIndicator(color: Colors.white54);
    }

    final aspectRatio = _controller.value.aspectRatio == 0 ? 16 / 9 : _controller.value.aspectRatio;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: GestureDetector(
        onTap: _togglePlay,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(_controller),
            if (!_controller.value.isPlaying)
              const Icon(Icons.play_arrow, color: Colors.white70, size: 64),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                colors: const VideoProgressColors(
                  playedColor: Colors.redAccent,
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
