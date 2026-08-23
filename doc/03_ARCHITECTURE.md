# 3. Architecture

## Folder structure

```
lib/
├── advanced_chat_kit.dart        # single barrel export — everything public
└── src/
    ├── core/
    │   ├── constants/             # ChatDefaults, ChatMetadataKeys
    │   ├── enums/                 # ChatType, ChatMessageType, ChatMessageStatus, ...
    │   └── utils/                 # SafeJson, formatters, url detection/launching
    ├── model/                     # pure Dart, JSON-serializable data classes
    ├── controller/                # ChatController + ChatState — the only stateful core
    ├── theme/                     # ChatTheme, ChatColors, ChatDimensions, ...
    └── widgets/
        ├── message/                # bubble, list, markdown, link preview, reactions
        ├── input/                  # input bar, action panel, pending attachments
        ├── media/                  # image/video/audio/document/contact rendering
        ├── actions/                 # long-press menu, call buttons, forward picker
        ├── custom/                  # ChatWidgetRegistry + worked example
        └── layout/                  # ChatView, ChatBackground, ChatLayers
```

Nothing outside `src/` is importable by a host app — `advanced_chat_kit.dart`
is the entire public surface. This is deliberate: it means the *real*
API is exactly what's exported, and internal file moves never break a
host app's imports.

## The layers, bottom to top

```
┌─────────────────────────────────────────┐
│              widgets/                    │  Flutter, stateless where possible
│  (message, input, media, actions, ...)   │
├─────────────────────────────────────────┤
│              theme/                      │  Pure config objects, no logic
├─────────────────────────────────────────┤
│              controller/                 │  Plain Dart, Stream<ChatState> only
├─────────────────────────────────────────┤
│              model/                      │  Pure Dart, JSON in/out, no Flutter import
├─────────────────────────────────────────┤
│              core/                       │  No dependencies on anything above
└─────────────────────────────────────────┘
```

Each layer only depends on layers below it — `core` never imports from
`model`, `model` never imports from `controller`, and so on. This is
what makes it safe to, say, replace `MarkdownText`'s parser internals
without touching `ChatController`, or add a new model field without
touching any widget.

### `core/` — no dependencies on anything above it

- **`enums/`** — every fixed vocabulary the rest of the package uses
  (`ChatType`, `ChatMessageType`, `ChatMessageStatus`, `ChatLayerPosition`,
  `ChatCallType`, `ChatConnectionState`).
- **`constants/`** — `ChatDefaults` (every default size/spacing/duration
  value, so `theme/` has something concrete to default *from*) and
  `ChatMetadataKeys`.
- **`utils/`** — `SafeJson` (defensive JSON parsing used by every
  `fromJson`), text formatters (`formatMessageTime`, `formatDuration`,
  `formatFileSize`), and URL handling (`extractAllUrls`,
  `launchSafeUrl`). All pure functions — no state, no Flutter widgets.

### `model/` — pure Dart, no Flutter import

Every class here (`ChatMessage`, `ChatUser`, `ChatAttachment`,
`ChatReaction`, `ChatReply`, `ForwardedMessage`, `ChatLinkPreview`) is
immutable, has `fromJson`/`toJson`/`copyWith`, and imports nothing from
`package:flutter`. You could theoretically reuse these models in a
non-Flutter Dart context (a CLI tool, a server) without pulling in the
Flutter SDK at all — a natural consequence of keeping business data
separate from rendering.

### `controller/` — the only genuinely stateful core

`ChatController` is plain Dart: a `List<ChatMessage>` +
`Map<String, int>` index for O(1) lookup, and a broadcast
`StreamController<ChatState>`. It has no `Widget` in its dependency
graph — you could unit test it (see `/test/controller/`) without ever
touching `flutter_test`'s widget-pumping machinery, only plain
`package:test`-style assertions. See
[`05_CONTROLLER.md`](05_CONTROLLER.md) for the full API.

### `theme/` — pure configuration, no logic

`ChatTheme` composes `ChatColors`, `ChatTypography`, `ChatDimensions`,
`ChatSpacing`, and `ChatLinkTextStyle`. None of these classes do
anything besides hold values and `copyWith` — every number a widget
draws with comes from here (or a widget's own constructor parameter),
never a hardcoded literal buried in a `build()` method. See
[`06_THEMING.md`](06_THEMING.md).

### `widgets/` — where Flutter actually shows up

Six sub-areas, each independently usable:

| Folder | Owns |
|---|---|
| `message/` | Bubble rendering, the scrollable list, Markdown, link previews, reactions |
| `input/` | The input bar and everything attached to it |
| `media/` | Image/video/audio/document/contact/location rendering |
| `actions/` | Long-press menu, reaction bar, call buttons, forward picker |
| `custom/` | The extension point for application-defined message types |
| `layout/` | `ChatView` and its background/layer configuration |

Every widget in every one of these folders is independently exported
and independently usable — `ChatView` is a convenience assembly, not a
gate you have to go through. See
[`07_WIDGETS_REFERENCE.md`](07_WIDGETS_REFERENCE.md).

## Dependency policy

The package has exactly three non-Flutter-SDK dependencies:

| Package | Why it's there | Why it's not hand-rolled |
|---|---|---|
| `video_player` | Full-screen video playback | Codec handling, hardware acceleration, and streaming buffering are platform-framework territory (`ExoPlayer`/`AVPlayer`/HTML5 under the hood either way) — not something worth re-implementing |
| `just_audio` | Voice-message / audio playback | Same reasoning — audio decoding and platform playback session management |
| `url_launcher` | Opening a link the person tapped | A one-line platform-channel call; wrapping it ourselves would still just call the same platform API |

Everything else that a typical "chat SDK" tutorial reaches for a
dependency for is hand-written instead, specifically because it's small
enough to own and specific enough to chat UI that a general-purpose
package would carry unused surface area:

- **Markdown** — `widgets/message/markdown_text.dart` is a ~250-line
  block/inline parser covering headings, bold/italic, inline+fenced
  code, blockquotes, lists, and links. Not CommonMark/GFM-complete —
  intentionally, see [`01_OVERVIEW.md`](01_OVERVIEW.md).
- **Link detection & preview rendering** — `core/utils/url_detector.dart`
  + `widgets/message/link_preview_card.dart`. Resolving the actual
  OpenGraph metadata is still the host app's job (a URL fetch + HTML
  parse); the package only renders whatever you resolved.
- **Image caching** — plain `Image.network`, which Flutter already
  caches in memory via `ImageCache`; no `cached_network_image` needed
  for this package's use case (thumbnails in a scrolling list).
- **Reactions, typing, pagination, grouping** — all state-machine logic
  living in `ChatController` and a few pure functions
  (`message_group_utils.dart`), not "features" in the dependency sense.

**Explicitly not attempted as package dependencies**, even though a
real app needs them: image/file picking, camera capture, audio
*recording* (as opposed to playback), sockets/REST, and any
state-management library. See the table in
[`01_OVERVIEW.md`](01_OVERVIEW.md#what-it-deliberately-does-not-include).

## Why this shape makes the package easy to keep updating

- **A model field addition never touches a widget.** `ChatMessage`
  gained `isStreaming` in the AI-streaming phase; no `MessageBubble`
  constructor changed — it just started reading one more field.
- **A new widget never touches the controller.** `LocationPreviewCard`
  and `ChatContactMessage` were added purely inside `widgets/media/`;
  `ChatController` doesn't know they exist.
- **A new dependency-free utility never touches anything else.**
  `formatDuration`/`formatFileSize`/`url_detector` are leaf functions —
  changing their internals can't ripple anywhere by construction, since
  nothing below `core/` exists for them to depend on.
- **Every constructor parameter, not a derived/hardcoded value,** means
  "I want this one thing different" is almost always a call-site change,
  not a package-source change — see the repeated pattern across
  `ChatLinkTextStyle`, `ChatDimensions`, `ChatSpacing`, and every
  widget's own style overrides.
