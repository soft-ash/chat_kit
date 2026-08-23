import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/enums/chat_enums.dart';
import '../../core/utils/duration_format.dart';
import '../../model/chat_attachment.dart';
import '../../theme/chat_colors.dart';
import '../../theme/chat_theme.dart';
import 'media_upload_overlay.dart';

/// Inline voice-message / audio-attachment player rendered directly
/// inside the bubble — play/pause, a scrub slider, and elapsed/total
/// duration.
///
/// Each bubble owns its own [AudioPlayer], created lazily on first tap
/// and torn down in [dispose]. Scrolling past hundreds of voice messages
/// never keeps hundreds of players alive in memory (doc sections 22 and
/// 26 — voice performance + memory management). Playback failures are
/// swallowed locally so one bad attachment never breaks the rest of the
/// conversation (doc section 24, error isolation).
class ChatAudioMessage extends StatefulWidget {
  final ChatAttachment attachment;
  final ChatMessageStatus status;
  final ChatTheme theme;
  final bool isMe;
  final VoidCallback? onRetry;

  const ChatAudioMessage({
    super.key,
    required this.attachment,
    required this.status,
    required this.theme,
    required this.isMe,
    this.onRetry,
  });

  @override
  State<ChatAudioMessage> createState() => _ChatAudioMessageState();
}

class _ChatAudioMessageState extends State<ChatAudioMessage> {
  AudioPlayer? _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  bool _isPlaying = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Safe to read `widget` here — field initializers run before the
    // framework binds `widget`, but initState() runs after (a classic
    // Flutter State gotcha worth guarding against explicitly).
    _total = widget.attachment.duration ?? Duration.zero;
  }

  Future<void> _togglePlay() async {
    final url = widget.attachment.url;
    if (url == null) return;

    if (_player == null) {
      setState(() => _loading = true);
      final player = AudioPlayer();

      _positionSub = player.positionStream.listen((position) {
        if (mounted) setState(() => _position = position);
      });
      _stateSub = player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() => _isPlaying = state.playing);
        if (state.processingState == ProcessingState.completed) {
          player.seek(Duration.zero);
          player.pause();
        }
      });

      try {
        final duration = await player.setUrl(url);
        if (duration != null && duration > Duration.zero) _total = duration;
        _player = player;
        await player.play();
      } catch (_) {
        // Isolated failure — bubble stays visible, just non-playable.
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    if (_isPlaying) {
      await _player!.pause();
    } else {
      await _player!.play();
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ChatColors colors = widget.theme.colors;
    final textColor = widget.isMe ? colors.senderText : colors.receiverText;
    final busy = widget.status == ChatMessageStatus.sending || widget.status == ChatMessageStatus.failed;
    final progress = _total.inMilliseconds == 0 ? 0.0 : _position.inMilliseconds / _total.inMilliseconds;
    final displayedTime = (_isPlaying || _position > Duration.zero) ? _position : _total;

    return SizedBox(
      width: 220,
      child: Row(
        children: [
          GestureDetector(
            onTap: (_loading || busy) ? null : _togglePlay,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: textColor.withValues(alpha: 0.15),
              child: _loading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
                    )
                  : Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: textColor, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: textColor,
                    inactiveTrackColor: textColor.withValues(alpha: 0.25),
                    thumbColor: textColor,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (_player == null || _total.inMilliseconds == 0)
                        ? null
                        : (value) {
                            final target = Duration(milliseconds: (value * _total.inMilliseconds).round());
                            _player!.seek(target);
                          },
                  ),
                ),
                Text(
                  formatDuration(displayedTime),
                  style: widget.theme.typography.timestamp.copyWith(color: textColor.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          if (busy) ...[
            const SizedBox(width: 4),
            MediaUploadOverlay(status: widget.status, progress: widget.attachment.uploadProgress, onRetry: widget.onRetry),
          ],
        ],
      ),
    );
  }
}
