/// A state-management-agnostic, production-grade Flutter chat UI/UX SDK.
///
/// Phase 1: core enums, models, the framework-agnostic [ChatController] +
/// [ChatState], and the full theming system.
/// Phase 2: default message bubble + scrollable, grouped, auto-scrolling
/// message list with pagination hook.
/// Phase 3: fully extensible input bar — text field, inline/expandable
/// actions, send/mic swap, press-and-hold voice recording with
/// slide-to-cancel, reply preview strip.
/// Phase 4: custom message widget registry — [ChatWidgetRegistry] plugs
/// application-defined cards (date invitation, product, payment, polls,
/// ...) into [MessageBubble]/[MessageList] without touching package
/// source, plus a worked [DateInvitationCard] example.
/// Phase 5: real media rendering — image thumbnail + pinch-zoom viewer,
/// video thumbnail + lazily-initialized full-screen player, an inline
/// voice-message player with seek, and a document attachment tile.
/// Phase 6: long-press message actions (Reply/Forward/Copy/Edit/
/// Delete/...) via [showMessageActionSheet], a quick-tap [ReactionBar],
/// and [MessageReactionsRow] rendering grouped emoji+count chips under
/// each bubble.
/// Phase 7: link detection with tap-to-open (safe http/https only), a
/// lightweight [MarkdownText] renderer, staged multi-attachment sending
/// with a [PendingAttachmentsBar] + [AttachmentReviewScreen]
/// preview-before-send flow, media thumbnails on reply previews, and a
/// [showForwardPickerSheet] destination picker.
/// Phase 8: [ChatLinkTextStyle] as its own constructor-injected style
/// object (color/size/weight for every link surface — [LinkifiedText],
/// [MarkdownText], [LinkPreviewCard] — without touching [ChatColors] or
/// [ChatTypography]), a real [LocationPreviewCard] (map snapshot + pin +
/// address), and a dismissible [LinkPreviewComposerBar] shown above the
/// input bar while composing a message that contains a link.
/// Phase 9: [ChatContactMessage] replaces the last placeholder rendering
/// (shared-contact card — avatar, name, phone/email, tap-through).
/// Phase 10: full [ChatView] assembly — wires [MessageList],
/// [ChatInputBar], [ChatBackgroundView], and every [ChatLayers]
/// extension slot (header, above/below messages, above/below input,
/// overlay) into one drop-in chat screen body, plus [ChatBackground]
/// (color/gradient/image/custom) and an animated [TypingIndicatorBubble].
/// Every widget it composes remains exported and usable standalone for
/// custom layouts.
/// Phase 11 (this update): AI streaming — [ChatMessage.isStreaming] +
/// [ChatController.startStreamingMessage]/[appendStreamingChunk]/
/// [completeStreamingMessage] update one message per chunk (same O(1)
/// indexed path as every other mutation), with a blinking
/// [StreamingCursor] while a response is still arriving, plus
/// [ChatDefaultActions.regenerate]/[stopGenerating]. Also: audio/video
/// call UI hooks ([ChatCallButtons], [CallStatusBanner]) with zero
/// WebRTC/calling-SDK dependency — see `/example` for worked GetX/
/// Riverpod/Bloc bindings and no-socket/with-socket usage, `/test` for
/// unit + widget tests, and `SETUP.md` for Android/iOS platform setup.
library advanced_chat_kit;

// Core
export 'src/core/enums/chat_enums.dart';
export 'src/core/constants/chat_constants.dart';

// Models
export 'src/model/chat_user.dart';
export 'src/model/chat_attachment.dart';
export 'src/model/chat_reaction.dart';
export 'src/model/chat_reply.dart';
export 'src/model/chat_link_preview.dart';
export 'src/model/chat_message.dart';

// Controller
export 'src/controller/chat_state.dart';
export 'src/controller/chat_controller.dart';

// Theme
export 'src/theme/chat_colors.dart';
export 'src/theme/chat_dimensions.dart';
export 'src/theme/chat_link_text_style.dart';
export 'src/theme/chat_theme.dart';

// Widgets
export 'src/widgets/chat_avatar.dart';
export 'src/widgets/message/message_bubble.dart';
export 'src/widgets/message/message_status_icon.dart';
export 'src/widgets/message/message_group_utils.dart';
export 'src/widgets/message/message_list.dart';

// Input
export 'src/widgets/input/chat_input_action.dart';
export 'src/widgets/input/chat_input_action_panel.dart';
export 'src/widgets/input/reply_preview_bar.dart';
export 'src/widgets/input/chat_input_bar.dart';

// Custom message widgets
export 'src/widgets/custom/chat_widget_action.dart';
export 'src/widgets/custom/chat_widget_registry.dart';
export 'src/widgets/custom/examples/date_invitation_card.dart';

// Media
export 'src/widgets/media/media_upload_overlay.dart';
export 'src/widgets/media/chat_image_message.dart';
export 'src/widgets/media/image_viewer_screen.dart';
export 'src/widgets/media/chat_video_message.dart';
export 'src/widgets/media/video_player_screen.dart';
export 'src/widgets/media/chat_audio_message.dart';
export 'src/widgets/media/chat_document_message.dart';
export 'src/widgets/media/chat_contact_message.dart';

// Actions & reactions
export 'src/widgets/actions/chat_message_action.dart';
export 'src/widgets/actions/reaction_bar.dart';
export 'src/widgets/actions/message_action_sheet.dart';
export 'src/widgets/message/message_reactions_row.dart';

// Links & Markdown
export 'src/core/utils/url_detector.dart';
export 'src/core/utils/safe_url_launcher.dart';
export 'src/widgets/message/linkified_text.dart';
export 'src/widgets/message/link_preview_card.dart';
export 'src/widgets/message/markdown_text.dart';
export 'src/widgets/message/location_preview_card.dart';
export 'src/widgets/input/link_preview_composer_bar.dart';

// Multi-attachment sending
export 'src/widgets/input/pending_attachments_bar.dart';
export 'src/widgets/media/attachment_review_screen.dart';

// Forward
export 'src/widgets/actions/forward_target.dart';
export 'src/widgets/actions/forward_picker_sheet.dart';

// Layout & assembly
export 'src/widgets/message/typing_indicator_bubble.dart';
export 'src/widgets/message/streaming_cursor.dart';
export 'src/widgets/layout/chat_background.dart';
export 'src/widgets/layout/chat_background_view.dart';
export 'src/widgets/layout/chat_layers.dart';
export 'src/widgets/layout/chat_view.dart';

// Calls (UI hooks only — no WebRTC/calling SDK dependency)
export 'src/widgets/actions/chat_call_buttons.dart';
export 'src/widgets/actions/call_status_banner.dart';
