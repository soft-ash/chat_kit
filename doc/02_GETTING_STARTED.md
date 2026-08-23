# 2. Getting Started

## 1. Install

Add the package to your app's `pubspec.yaml`. If you're developing
against the source in this repo (not yet published to pub.dev), use a
path or git dependency:

```yaml
dependencies:
  flutter:
    sdk: flutter
  advanced_chat_kit:
    path: ../advanced_chat_kit   # adjust to wherever you placed it
```

Then:

```bash
flutter pub get
```

The package itself pulls in exactly three plugin dependencies —
`video_player`, `just_audio`, `url_launcher` — nothing else. See
[`03_ARCHITECTURE.md`](03_ARCHITECTURE.md#dependency-policy) for why
these three specifically.

**Platform setup** (Android permissions, iOS Info.plist entries) is
required before video/audio/link features work correctly on-device — see
`/SETUP.md` at the repo root. It's a handful of manifest lines, not
package code.

## 2. Import

```dart
import 'package:advanced_chat_kit/advanced_chat_kit.dart';
```

Every public model, controller, theme class, and widget is exported from
this single barrel file.

## 3. The three things you always need

1. A **`ChatController`** — the framework-agnostic brain of one
   conversation.
2. A **`ChatTheme`** — visual configuration (`ChatTheme.light()` or
   `ChatTheme.dark()` to start).
3. A **`ChatView`** (or `MessageList` + `ChatInputBar` separately, if you
   want a custom layout) — the actual screen.

## 4. Minimum working example (no backend)

This is the entire `/example/lib/no_socket/local_preview_screen.dart`
pattern, trimmed down:

```dart
import 'package:advanced_chat_kit/advanced_chat_kit.dart';
import 'package:flutter/material.dart';

class MyChatScreen extends StatefulWidget {
  const MyChatScreen({super.key});

  @override
  State<MyChatScreen> createState() => _MyChatScreenState();
}

class _MyChatScreenState extends State<MyChatScreen> {
  late final ChatController _controller = ChatController(
    currentUserId: 'me',
  );

  @override
  void dispose() {
    _controller.dispose(); // always dispose — see doc section 5 (lifecycle)
    super.dispose();
  }

  void _handleSendText(String text) {
    _controller.addOutgoingMessage(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        senderId: 'me',
        type: ChatMessageType.text,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: ChatView(
        controller: _controller,
        theme: ChatTheme.light(),
        onSendText: _handleSendText,
      ),
    );
  }
}
```

That's a fully working, scrollable, themeable chat screen. Nothing sends
anywhere yet — the next step is wiring it to a real backend.

## 5. Connecting to a real backend

Read [`10_API_INTEGRATION.md`](10_API_INTEGRATION.md) for the full
pattern (sockets, REST pagination, optimistic sending, status updates).
The short version: your socket/API callbacks call
`_controller.addIncomingMessage(...)` when something arrives, and
`onSendText`/`onSendMedia` call your socket/API when the user sends
something. `ChatController` is the seam between the two.

## 6. Picking a state-management binding

If your app already uses GetX, Riverpod, or Bloc, read
[`11_STATE_MANAGEMENT.md`](11_STATE_MANAGEMENT.md) — `ChatController`
itself never needs to change; only how you subscribe to `.stream` does.

## 7. Where to go next

- Want every visual value adjustable? → [`06_THEMING.md`](06_THEMING.md)
- Want to add a custom message type (payment card, poll, booking)? →
  [`09_CUSTOM_MESSAGES.md`](09_CUSTOM_MESSAGES.md)
- Want the full list of every widget and its parameters? →
  [`07_WIDGETS_REFERENCE.md`](07_WIDGETS_REFERENCE.md)
- Want to know exactly what's built vs. left to you? →
  [`08_FEATURES.md`](08_FEATURES.md)
