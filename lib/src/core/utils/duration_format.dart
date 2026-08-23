/// `m:ss` (or `h:mm:ss` past an hour) formatter for voice-message and
/// video durations — deliberately not using `intl`, same reasoning as
/// [formatMessageTime].
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
  }
  return '$minutes:$seconds';
}
