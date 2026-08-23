# 8. Features

A complete checklist against the original production requirements. Three
categories:

- ✅ **Built** — fully implemented in the package, works out of the box.
- 🔌 **UI hook only** — the package provides the widget/interaction and
  fires a callback; the underlying capability (network call, native SDK,
  file system) is the host app's responsibility by design.
- 🧩 **Host app** — intentionally not in the package at all; see
  [`01_OVERVIEW.md`](01_OVERVIEW.md#what-it-deliberately-does-not-include)
  for why.

| Feature | Status | Notes |
|---|---|---|
| OOP / SOLID architecture | ✅ | See [`03_ARCHITECTURE.md`](03_ARCHITECTURE.md) |
| State-management agnostic | ✅ | `Stream<ChatState>` contract — see [`11_STATE_MANAGEMENT.md`](11_STATE_MANAGEMENT.md) |
| Dependency-light | ✅ | Exactly 3 plugin dependencies — see [`03_ARCHITECTURE.md`](03_ARCHITECTURE.md#dependency-policy) |
| Android / iOS / Web | ✅ | See `SETUP.md` for platform-specific config |
| Responsive layout | ✅ | Constraint-based sizing throughout; `ChatInputActionPanel`/`ChatWidgetActionGroup` adapt to width |
| Secure by default | ✅ | `SafeJson` everywhere, `launchSafeUrl` restricts to http/https, declarative (not executable) custom messages |
| Memory safe | ✅ | Every `AnimationController`/`StreamSubscription`/`AudioPlayer` disposed; `ChatController.dispose()` |
| Error isolated | ✅ | Broken thumbnail/link-preview/playback never breaks the rest of the screen |
| Lifecycle safe | ✅ | `dispose()` pattern documented for every state-management binding |
| Fast message lookup | ✅ | `List` + `Map<String,int>` index, O(1) average |
| Lazy rendering | ✅ | `ListView.builder` + `ValueKey`-scoped rebuilds |
| Pagination | ✅ | Cursor-based, `ChatController.loadMore()` |
| Media caching | ✅ (images) | `Image.network` + Flutter's built-in `ImageCache`; no extra dependency |
| Voice recording (UI/gesture) | ✅ | Press-and-hold, slide-to-cancel in `ChatInputBar` |
| Voice recording (actual capture) | 🧩 | Package has no mic-recording implementation — wire `onVoiceRecordStart/Stop/Cancel` to your own recorder |
| Audio playback | ✅ | `ChatAudioMessage`, via `just_audio` |
| Video playback | ✅ | `ChatVideoMessage` + `VideoPlayerScreen`, via `video_player` |
| Image viewing | ✅ | Pinch-zoom `ImageViewerScreen`, Hero animation |
| Reply | ✅ | Text + media thumbnail, both in-bubble and in the composer |
| Forward | ✅ (picker UI) | `showForwardPickerSheet` — actual forwarding/persistence is 🧩 host app |
| Reactions | ✅ | Add/remove/toggle, grouped chip rendering |
| Markdown | ✅ | Custom lightweight renderer, not CommonMark-complete by design |
| Link previews | ✅ (rendering) | Card rendering is ✅; *resolving* OpenGraph metadata is 🧩 host app |
| AI chat / streaming | ✅ | `startStreamingMessage`/`appendStreamingChunk`/`completeStreamingMessage` + blinking cursor |
| Single chat | ✅ | `ChatType.single` |
| Group chat | ✅ | `ChatType.group` — sender names/avatars in `MessageBubble` are group-chat-ready |
| Custom message widgets | ✅ | `ChatWidgetRegistry` — see [`09_CUSTOM_MESSAGES.md`](09_CUSTOM_MESSAGES.md) |
| Custom input actions | ✅ | `ChatInputAction` / `ChatActionGroup` |
| Multiple action buttons (in-message) | ✅ | `ChatWidgetActionGroup` — Row↔Wrap responsive |
| Custom chat layers | ✅ | `ChatLayers` — 7 independently-optional slots |
| Custom backgrounds | ✅ | `ChatBackground.color/gradient/image/custom` |
| Custom animations | 🔌 partial | Built-in: typing dots, streaming cursor, Hero transitions. Anything beyond that is a `ChatLayers.custom` / `ChatBackground.custom` slot |
| Custom themes | ✅ | See [`06_THEMING.md`](06_THEMING.md) |
| Custom message types | ✅ | Same as "custom message widgets" above |
| Custom business widgets | ✅ | `DateInvitationCard` is the worked example; same pattern for payment/product/poll/booking cards |
| Offline-ready architecture | 🔌 | `ChatMessageStatus.sending/failed` + retry callbacks exist; actual offline queue/persistence is 🧩 host app |
| Retry mechanism (UI) | ✅ | `MediaUploadOverlay` retry icon, `onRetryAttachment` callback |
| Accessibility | 🔌 partial | Standard Flutter semantics apply to all widgets (Text, IconButton, etc.); no custom `Semantics` labels added beyond what Flutter's own widgets provide by default |
| Unit tests | ✅ | `/test/model/`, `/test/controller/` |
| Widget tests | ✅ | `/test/widget/` |
| Integration tests | 🧩 | Not included — would need a full example app + `integration_test` package; see `/example` as the closest thing |
| Example application | ✅ | `/example` — 5 worked screens |
| CI/CD | ✅ | `.github/workflows/ci.yml` — format check, analyze, test, and a separate example-app analyze job |
| Production documentation | ✅ | This `/doc` folder |
| Location messages | ✅ (rendering) | `LocationPreviewCard` renders a real static-map image *you* supply, or a placeholder — no maps SDK dependency |
| Contact messages | ✅ (rendering) | `ChatContactMessage` — no contacts API dependency |
| Calls (audio/video) | 🔌 | `ChatCallButtons`/`CallStatusBanner` fire intent only — no WebRTC/Agora/Zego dependency |
| Multi-attachment sending | ✅ | `PendingAttachmentsBar` + `AttachmentReviewScreen` + `ChatInputBar.onSendMedia`, with or without a caption |
| Typing indicator | ✅ | `ChatController.setUserTyping`/`clearUserTyping` + `TypingIndicatorBubble` |
| Online/read status | 🔌 partial | `ChatUser.isOnline`/`lastSeen` fields exist; rendering an online dot/last-seen line in a header is left to the host app's own header widget (a natural `ChatLayers.header` use case) |
| Authentication | 🧩 | Out of scope entirely |
| Backend / REST / sockets | 🧩 | Out of scope entirely — see [`10_API_INTEGRATION.md`](10_API_INTEGRATION.md) |
