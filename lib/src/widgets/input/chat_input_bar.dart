import 'dart:async';

import 'package:flutter/material.dart';

import '../../model/chat_attachment.dart';
import '../../model/chat_link_preview.dart';
import '../../model/chat_reply.dart';
import '../../theme/chat_colors.dart';
import '../../theme/chat_dimensions.dart';
import '../../theme/chat_theme.dart';
import 'chat_input_action.dart';
import 'chat_input_action_panel.dart';
import 'link_preview_composer_bar.dart';
import 'pending_attachments_bar.dart';
import 'reply_preview_bar.dart';

enum _VoiceState { idle, recording, cancelling }

/// Fired when the person taps send while one or more attachments are
/// staged in [ChatInputBar.pendingAttachments] — `text` is `null` when
/// they sent media with no caption.
typedef ChatSendMedia = void Function(String? text, List<ChatAttachment> attachments);

/// The fully extensible chat input bar: text field, optional inline
/// action icons beside the field, an optional expandable action panel
/// (Games/Photo/Voice/Date-style row), a send/mic button that swaps based
/// on whether there's text, a press-and-hold-to-record slide-to-cancel
/// voice flow, and a staged-attachments strip for sending multiple media
/// with or without a caption.
///
/// This widget only emits *intent* — [onSendText], [onSendMedia],
/// [onVoiceRecordStop], each [ChatInputAction.onPressed]. Actually
/// sending over a socket, uploading a file, or capturing real audio bytes
/// belongs to the host app (see SDK doc section 16 — backend/socket/
/// business logic stay in the host application). Picking the files in the
/// first place — via `image_picker`, the camera, a document picker — is
/// also the host app's job; hand the results here as
/// [pendingAttachments] with [ChatAttachment.localPath] set.
class ChatInputBar extends StatefulWidget {
  final ChatTheme theme;
  final ValueChanged<String> onSendText;
  final ValueChanged<bool>? onTypingChanged;

  final ChatReply? replyingTo;
  final VoidCallback? onCancelReply;

  /// Small icon buttons shown directly beside the text field, e.g. a
  /// single attach icon, or camera + gallery.
  final List<ChatInputAction> inlineActions;

  /// The expandable row shown below the field when the "+" toggle is
  /// tapped (e.g. Games / Photo / Voice / Date).
  final List<ChatInputAction> expandableActions;

  final bool enableVoice;
  final VoidCallback? onVoiceRecordStart;
  final VoidCallback? onVoiceRecordCancel;
  final ValueChanged<Duration>? onVoiceRecordStop;

  /// Media the person has picked but hasn't sent yet — rendered as a
  /// [PendingAttachmentsBar] above the text field. While this is
  /// non-empty, the send button always fires [onSendMedia] with the
  /// current caption text instead of [onSendText]. Multiple attachments
  /// can be sent together, with or without a caption (see doc section 7,
  /// media system).
  final List<ChatAttachment> pendingAttachments;
  final ValueChanged<ChatAttachment>? onRemovePendingAttachment;
  final ValueChanged<ChatAttachment>? onTapPendingAttachment;
  final ChatSendMedia? onSendMedia;

  /// A resolved preview for a link detected in the text currently being
  /// typed — rendered as a dismissible [LinkPreviewComposerBar] above the
  /// field, mirroring how Facebook/WhatsApp show "you're about to share
  /// this" before you hit send. The package doesn't detect the URL or
  /// fetch metadata itself; pass `null` to show nothing.
  final ChatLinkPreview? composerLinkPreview;
  final VoidCallback? onDismissLinkPreview;

  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const ChatInputBar({
    super.key,
    required this.theme,
    required this.onSendText,
    this.onTypingChanged,
    this.replyingTo,
    this.onCancelReply,
    this.inlineActions = const [],
    this.expandableActions = const [],
    this.enableVoice = true,
    this.onVoiceRecordStart,
    this.onVoiceRecordCancel,
    this.onVoiceRecordStop,
    this.pendingAttachments = const [],
    this.onRemovePendingAttachment,
    this.onTapPendingAttachment,
    this.onSendMedia,
    this.composerLinkPreview,
    this.onDismissLinkPreview,
    this.hintText = 'Message...',
    this.controller,
    this.focusNode,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  late final TextEditingController _controller = widget.controller ?? TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();

  Timer? _typingDebounce;
  bool _isTyping = false;
  bool _showActionPanel = false;

  _VoiceState _voiceState = _VoiceState.idle;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  Offset? _dragStart;

  static const double _cancelDragThreshold = 80;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    _typingDebounce?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _handleTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      _isTyping = hasText;
      widget.onTypingChanged?.call(hasText);
    }
    // Debounce so a fast typist doesn't spam the host app's typing event
    // on every keystroke — only fires "stopped typing" after a pause.
    _typingDebounce?.cancel();
    if (hasText) {
      _typingDebounce = Timer(const Duration(seconds: 3), () {
        _isTyping = false;
        widget.onTypingChanged?.call(false);
      });
    }
    setState(() {}); // refresh send/mic button swap
  }

  void _send() {
    if (widget.pendingAttachments.isNotEmpty) {
      final caption = _controller.text.trim();
      widget.onSendMedia?.call(caption.isEmpty ? null : caption, widget.pendingAttachments);
      _controller.clear();
      _isTyping = false;
      _typingDebounce?.cancel();
      widget.onTypingChanged?.call(false);
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _controller.clear();
    _isTyping = false;
    _typingDebounce?.cancel();
    widget.onTypingChanged?.call(false);
  }

  void _toggleActionPanel() {
    setState(() => _showActionPanel = !_showActionPanel);
    if (_showActionPanel) _focusNode.unfocus();
  }

  void _startRecording(Offset globalPosition) {
    setState(() {
      _voiceState = _VoiceState.recording;
      _recordingDuration = Duration.zero;
      _dragStart = globalPosition;
    });
    widget.onVoiceRecordStart?.call();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingDuration += const Duration(seconds: 1));
    });
  }

  void _updateDrag(Offset globalPosition) {
    if (_voiceState == _VoiceState.idle || _dragStart == null) return;
    final dx = globalPosition.dx - _dragStart!.dx;
    final shouldCancel = dx < -_cancelDragThreshold;
    if (shouldCancel && _voiceState != _VoiceState.cancelling) {
      setState(() => _voiceState = _VoiceState.cancelling);
    } else if (!shouldCancel && _voiceState == _VoiceState.cancelling) {
      setState(() => _voiceState = _VoiceState.recording);
    }
  }

  void _endRecording() {
    if (_voiceState == _VoiceState.idle) return;
    _recordingTimer?.cancel();
    final cancelled = _voiceState == _VoiceState.cancelling;
    final duration = _recordingDuration;
    setState(() {
      _voiceState = _VoiceState.idle;
      _recordingDuration = Duration.zero;
      _dragStart = null;
    });
    if (cancelled) {
      widget.onVoiceRecordCancel?.call();
    } else {
      widget.onVoiceRecordStop?.call(duration);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.theme.colors;
    final hasText = _controller.text.trim().isNotEmpty;
    final hasPendingAttachments = widget.pendingAttachments.isNotEmpty;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyingTo != null)
            ReplyPreviewBar(
              reply: widget.replyingTo!,
              theme: widget.theme,
              onCancel: widget.onCancelReply ?? () {},
            ),
          if (widget.composerLinkPreview != null)
            LinkPreviewComposerBar(
              preview: widget.composerLinkPreview!,
              theme: widget.theme,
              onDismiss: widget.onDismissLinkPreview ?? () {},
            ),
          if (hasPendingAttachments)
            PendingAttachmentsBar(
              attachments: widget.pendingAttachments,
              theme: widget.theme,
              onRemove: widget.onRemovePendingAttachment,
              onTapPreview: widget.onTapPendingAttachment,
            ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: widget.theme.spacing.inputPadding, vertical: 8),
            color: colors.background,
            child: _voiceState != _VoiceState.idle
                ? _buildRecordingRow(colors)
                : _buildComposerRow(colors, widget.theme.dimensions, hasText || hasPendingAttachments),
          ),
          if (_showActionPanel)
            ChatInputActionPanel(actions: widget.expandableActions, theme: widget.theme),
        ],
      ),
    );
  }

  Widget _buildComposerRow(ChatColors colors, ChatDimensions dims, bool showSendButton) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.expandableActions.isNotEmpty)
          IconButton(
            icon: Icon(_showActionPanel ? Icons.close : Icons.add_circle_outline, color: colors.hintText),
            onPressed: _toggleActionPanel,
          ),
        ...widget.inlineActions.map(
          (action) => IconButton(
            icon: Icon(action.icon, color: action.color ?? colors.hintText),
            onPressed: action.onPressed,
            tooltip: action.label,
          ),
        ),
        Expanded(
          child: Container(
            constraints: BoxConstraints(minHeight: dims.inputMinHeight, maxHeight: dims.inputMaxHeight),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.inputBackground,
              borderRadius: BorderRadius.circular(dims.inputMinHeight / 2),
              border: Border.all(color: colors.inputBorder),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 6,
              style: widget.theme.typography.inputText.copyWith(color: colors.receiverText),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: widget.theme.typography.inputHint.copyWith(color: colors.hintText),
                border: InputBorder.none,
                isDense: true,
              ),
              onTap: () {
                if (_showActionPanel) setState(() => _showActionPanel = false);
              },
            ),
          ),
        ),
        const SizedBox(width: 6),
        _buildSendOrMicButton(colors, dims, showSendButton),
      ],
    );
  }

  Widget _buildSendOrMicButton(ChatColors colors, ChatDimensions dims, bool showSendButton) {
    if (showSendButton) {
      return _RoundIconButton(
        size: dims.sendButtonSize,
        color: colors.primary,
        icon: Icons.send_rounded,
        iconColor: colors.onPrimary,
        onTap: _send,
      );
    }
    if (!widget.enableVoice) {
      return _RoundIconButton(
        size: dims.sendButtonSize,
        color: colors.inputBorder,
        icon: Icons.send_rounded,
        iconColor: colors.hintText,
        onTap: null,
      );
    }
    return GestureDetector(
      onLongPressStart: (details) => _startRecording(details.globalPosition),
      onLongPressMoveUpdate: (details) => _updateDrag(details.globalPosition),
      onLongPressEnd: (_) => _endRecording(),
      onLongPressCancel: _endRecording,
      child: _RoundIconButton(
        size: dims.sendButtonSize,
        color: colors.primary,
        icon: Icons.mic_none_rounded,
        iconColor: colors.onPrimary,
        onTap: null,
      ),
    );
  }

  Widget _buildRecordingRow(ChatColors colors) {
    final cancelling = _voiceState == _VoiceState.cancelling;
    return Row(
      children: [
        Icon(Icons.fiber_manual_record, color: colors.danger, size: 14),
        const SizedBox(width: 8),
        Text(
          _formatDuration(_recordingDuration),
          style: widget.theme.typography.messageText.copyWith(color: colors.receiverText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            cancelling ? 'Release to cancel' : '◀  Slide to cancel',
            textAlign: TextAlign.end,
            style: widget.theme.typography.timestamp.copyWith(
              color: cancelling ? colors.danger : colors.hintText,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final double size;
  final Color color;
  final Color iconColor;
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconButton({
    required this.size,
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: iconColor, size: size * 0.5),
        ),
      ),
    );
  }
}
