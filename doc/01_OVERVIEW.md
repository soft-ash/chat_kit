# 1. Overview

## What is `advanced_chat_kit`?

A production-grade Flutter chat **UI/UX SDK** — not a `ChatScreen`
widget, an engine + extension framework for building one. It renders
messages, handles input, media, reactions, replies, forwards, custom
message types, AI streaming, and theming. It does **not** talk to a
server, does **not** pick a state-management library for you, and does
**not** implement calling.

## The one-sentence version

> **The package owns the chat UI. The host app owns the backend, the
> socket, the state management, and the business logic.**

Everything else in this documentation is a consequence of that one
sentence.

## Why built this way

The original goal was a package that could drop into *any* Flutter app —
GetX, Riverpod, Bloc, or plain `setState` — without dragging in a second
state-management library as a transitive dependency, and without forcing
a specific backend/socket implementation. Three architectural decisions
follow directly from that goal:

1. **`ChatController` is plain Dart.** No `GetxController`, no
   `ChangeNotifier`, no `StateNotifier` — just a class holding a
   `List<ChatMessage>` and emitting `Stream<ChatState>`. Any state
   management can wrap a `Stream` (`.obs`, `StreamProvider`, `Cubit`,
   `StreamBuilder`) — see [`11_STATE_MANAGEMENT.md`](11_STATE_MANAGEMENT.md).

2. **No networking dependency at all.** No `dio`, no `http`, no
   `socket_io_client` inside the package. `ChatController` exposes
   methods like `addIncomingMessage()` and `updateMessageStatus()` that
   the host app calls when *its* socket/REST layer receives something —
   see [`10_API_INTEGRATION.md`](10_API_INTEGRATION.md).

3. **Every visual value is a constructor parameter, not a hardcoded
   number.** Height, width, padding, radius, color, gradient — all flow
   through `ChatTheme` (or a widget's own constructor). Changing the look
   never means editing package source — see
   [`06_THEMING.md`](06_THEMING.md).

## What it includes

- Single, group, and AI chat types
- Message bubbles with WhatsApp/Telegram-style consecutive-message
  grouping
- A fully extensible input bar: text, inline actions, an expandable
  action panel, press-and-hold voice recording with slide-to-cancel
- Real media rendering: images (pinch-zoom viewer), video (lazy
  full-screen player), voice messages (inline seek player), documents
- Reply, forward, reactions, long-press action menu
- A custom-message-widget registry (date invitation cards, product
  cards, payment cards, polls — anything)
- Link detection + OpenGraph-style preview cards, with tap-to-open
- A lightweight, dependency-free Markdown renderer
- Location and contact message cards
- Multi-attachment sending with preview-before-send
- AI response streaming (token-by-token) with a blinking cursor
- Audio/video call action UI hooks (no WebRTC dependency)
- A full `ChatView` assembly, or every piece usable standalone
- A complete theming system (colors, gradients, dimensions, spacing,
  typography, link styling)

See [`08_FEATURES.md`](08_FEATURES.md) for the exhaustive checklist.

## What it deliberately does NOT include

| Not included | Why | What you do instead |
|---|---|---|
| A backend / REST client | Every app's API is different | Call `ChatController` methods from your own API layer |
| A socket implementation | Same reason | See [`10_API_INTEGRATION.md`](10_API_INTEGRATION.md) |
| GetX/Riverpod/Bloc dependency | Keeps the package usable in any app | Bind `ChatController.stream` yourself — see [`11_STATE_MANAGEMENT.md`](11_STATE_MANAGEMENT.md) |
| WebRTC/Agora/calling SDK | Calling implementations vary wildly | `ChatCallButtons`/`CallStatusBanner` fire intent only |
| A maps SDK | Avoids an API-key dependency | `LocationPreviewCard` renders whatever static image you give it |
| Camera/mic **permission** handling | Picking/recording is host-app code | Use `image_picker`/`file_picker`/your own recorder; hand results to the package as `ChatAttachment` |
| Authentication | Out of scope for a UI package | N/A |

## Design principles that shaped every file

- **State-management agnostic** — plain Dart core, `Stream`-based contract.
- **Dependency-light** — only `video_player`, `just_audio`, and
  `url_launcher` (all official/well-maintained, all essential to a
  feature that genuinely needs platform media APIs). Everything else —
  Markdown, link detection, image caching, reactions, typing, pagination
  — is hand-written. See [`03_ARCHITECTURE.md`](03_ARCHITECTURE.md) for
  the full dependency reasoning.
- **Untrusted-input by default** — every `fromJson` uses `SafeJson`,
  which never throws on malformed/missing fields; it falls back to a
  safe default instead.
- **Declarative, not executable, remote data** — custom message payloads
  are `type: custom, customType: 'x', metadata: {...}` — a string key
  and a data map, never a function or code the package evaluates.
- **O(1) message operations** — `List<ChatMessage>` + `Map<String, int>`
  index, so lookup/update/delete by id never scans the whole
  conversation.
- **No full-list rebuilds** — every bubble has `key: ValueKey(id)`;
  updating one message (a reaction, a status change, a streaming chunk)
  only rebuilds that one Element.
- **Every subsystem fails independently** — a broken link preview, a
  failed thumbnail, a playback error never takes down the rest of the
  chat screen.
