# advanced_chat_kit

A state-management-agnostic, production-grade Flutter chat UI/UX SDK.
Own your socket, backend, and state management — this package owns the
chat experience.

```dart
Scaffold(
  appBar: AppBar(title: Text(otherUser.name)),
  body: ChatView(
    controller: chatController,
    theme: ChatTheme.light(),
    onSendText: (text) {
      final message = ChatMessage(
        id: newId(), senderId: currentUserId, type: ChatMessageType.text,
        text: text, createdAt: DateTime.now(),
      );
      chatController.addOutgoingMessage(message);
      socket.emit('send_message', message.toJson());
    },
  ),
)
```

## Why this package

- **Zero state-management dependency.** No GetX, Riverpod, Bloc, or
  Provider inside the package — `ChatController` exposes a plain
  `Stream<ChatState>`. Bind it however your app already works; see
  [`doc/11_STATE_MANAGEMENT.md`](doc/11_STATE_MANAGEMENT.md).
- **Zero networking dependency.** No socket, no REST client baked in —
  `ChatController` is the seam between your backend and the UI; see
  [`doc/10_API_INTEGRATION.md`](doc/10_API_INTEGRATION.md).
- **Three plugin dependencies, total.** `video_player`, `just_audio`,
  `url_launcher` — everything else (Markdown, link detection, reactions,
  pagination, image caching) is hand-written. See
  [`doc/03_ARCHITECTURE.md`](doc/03_ARCHITECTURE.md#dependency-policy).
- **Every visual value is a constructor parameter.** Height, width,
  padding, radius, color, gradient — never a hardcoded literal in a
  `build()` method. See [`doc/06_THEMING.md`](doc/06_THEMING.md).
- **Every feature is optional and composable.** Reactions, replies,
  forwards, media, Markdown, custom message widgets, AI streaming, call
  hooks — turn on only what you need.

## What's included

Single/group/AI chat · WhatsApp-style message grouping · fully
extensible input bar with press-and-hold voice recording · image/video/
audio/document rendering with a lazily-initialized full-screen player ·
reply, forward, reactions, long-press action menu · a custom-message
registry for application-defined cards · link detection with
tap-to-open + OpenGraph-style preview cards · a lightweight Markdown
renderer · location and contact message cards · multi-attachment sending
with preview-before-send · AI response streaming with a blinking cursor
· audio/video call UI hooks · a complete theming system · a full
`ChatView` assembly, or every piece usable standalone.

See [`doc/08_FEATURES.md`](doc/08_FEATURES.md) for the exhaustive,
honest checklist — including what's intentionally left to the host app.

## Getting started

```yaml
dependencies:
  advanced_chat_kit:
    path: ../advanced_chat_kit   # or git/pub.dev, once published
```

Then read [`doc/02_GETTING_STARTED.md`](doc/02_GETTING_STARTED.md) for a
complete minimum working example, and `/SETUP.md` for the Android/iOS
platform configuration `video_player`/`just_audio`/`url_launcher` need.

## Documentation

Full reference lives in [`/doc`](doc/README.md) — architecture, every
model field, the complete `ChatController` API, theming, every widget's
constructor parameters, the custom-message pattern, backend integration,
state-management bindings, and an FAQ.

## Examples

`/example` has five runnable screens: a fully local no-backend preview,
a real `socket_io_client` integration, and GetX/Riverpod/Bloc binding
examples. See [`example/README.md`](example/README.md).

## Tests

```bash
flutter test
```

`/test` covers the model layer (JSON round-trips, defensive parsing),
the controller (CRUD, reactions, streaming, pagination, lifecycle), and
widget rendering.

## License

MIT — see [`LICENSE`](LICENSE).
