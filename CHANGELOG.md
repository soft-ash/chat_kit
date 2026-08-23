# Changelog

## 0.1.0

Initial release.

### Core
- `ChatController` — framework-agnostic message store, O(1) indexed
  lookup/update/delete, `Stream<ChatState>` contract.
- Full model layer: `ChatMessage`, `ChatUser`, `ChatAttachment`,
  `ChatReaction`, `ChatReply`, `ForwardedMessage`, `ChatLinkPreview` —
  all with defensive (`SafeJson`-backed) `fromJson`.
- Complete theming system: `ChatTheme`, `ChatColors`, `ChatTypography`,
  `ChatDimensions`, `ChatSpacing`, `ChatLinkTextStyle`.

### Messaging
- Message bubbles with consecutive-message grouping.
- Reply (with media thumbnails), forward (picker UI), reactions
  (grouped chips), long-press action menu.
- Custom message widget registry (`ChatWidgetRegistry`) with a worked
  date-invitation-card example.
- Link detection, tap-to-open (http/https only), OpenGraph-style
  preview cards.
- Lightweight, dependency-free Markdown renderer.
- Location and contact message cards.
- AI response streaming (token-by-token) with a blinking cursor.

### Media
- Image rendering with pinch-zoom full-screen viewer.
- Video rendering with a lazily-initialized full-screen player.
- Inline voice-message / audio player with seek.
- Document attachment tiles.
- Multi-attachment sending: staged pending-attachments bar +
  preview-before-send review screen, with or without a caption.

### Input
- Fully extensible input bar: inline + expandable actions,
  press-and-hold voice recording with slide-to-cancel, typing debounce.

### Layout
- `ChatView` — full assembly of message list, input bar, background,
  and every `ChatLayers` extension slot.
- `ChatBackground` (color/gradient/image/custom).
- `TypingIndicatorBubble`.

### Calls
- `ChatCallButtons` / `CallStatusBanner` — UI hooks only, no
  WebRTC/calling-SDK dependency.

### Docs & tooling
- Full `/doc` reference (12 documents).
- `/example` — no-socket, with-socket, and GetX/Riverpod/Bloc binding
  examples.
- `/test` — model, controller, and widget test coverage.
- `SETUP.md` — Android/iOS platform configuration guide.
