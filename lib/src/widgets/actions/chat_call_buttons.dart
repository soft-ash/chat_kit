import 'package:flutter/material.dart';

import '../../core/enums/chat_enums.dart';
import '../../theme/chat_theme.dart';

/// Ready-made audio/video call icon buttons for a chat header. The
/// package has no WebRTC/Agora/Zego/Stream dependency of its own —
/// tapping either button only fires [onCall] with the requested
/// [ChatCallType]. Actually starting the call (navigating to a call
/// screen, dialing through whatever calling SDK the host app uses) is
/// entirely the host app's job (see doc section 18: "don't implement
/// WebRTC directly inside the chat UI — expose `onAudioCall`/
/// `onVideoCall` and let the application decide").
///
/// ```dart
/// ChatCallButtons(
///   theme: theme,
///   onCall: (type) => type == ChatCallType.video
///       ? Navigator.push(context, MaterialPageRoute(builder: (_) => VideoCallScreen(user: otherUser)))
///       : myCallingSdk.startAudioCall(otherUser.id),
/// )
/// ```
class ChatCallButtons extends StatelessWidget {
  final ChatTheme theme;
  final ValueChanged<ChatCallType>? onCall;
  final bool enableAudio;
  final bool enableVideo;

  const ChatCallButtons({
    super.key,
    required this.theme,
    this.onCall,
    this.enableAudio = true,
    this.enableVideo = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (enableAudio)
          IconButton(
            icon: Icon(Icons.call_outlined, color: colors.receiverText),
            onPressed: onCall == null ? null : () => onCall!(ChatCallType.audio),
            tooltip: 'Audio call',
          ),
        if (enableVideo)
          IconButton(
            icon: Icon(Icons.videocam_outlined, color: colors.receiverText),
            onPressed: onCall == null ? null : () => onCall!(ChatCallType.video),
            tooltip: 'Video call',
          ),
      ],
    );
  }
}
