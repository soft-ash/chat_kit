# 11. State Management

`ChatController` is plain Dart exposing `Stream<ChatState>` — it doesn't
know GetX, Riverpod, or Bloc exist, and never will (see
[`01_OVERVIEW.md`](01_OVERVIEW.md)). Binding it to whichever one your
app already uses is a few lines, shown below for each. Full runnable
versions of all four live in `/example/lib/state_bindings/` and
`/example/lib/no_socket/local_preview_screen.dart` (the plain-`setState`
case).

## The one thing every binding has in common

```
ChatController.stream  →  <your state management's reactive primitive>  →  UI
```

And the one thing every binding's teardown does:

```dart
yourFrameworksDisposeHook(() {
  chatController.dispose(); // never skip this — see doc section 5, lifecycle
});
```

**Also worth knowing:** `ChatView` already subscribes to
`controller.stream` internally via its own `StreamBuilder`. None of the
bindings below are *required* just to render `ChatView` — they matter
once some *other* widget on the same screen (a header showing unread
count, a custom typing indicator placed outside `ChatView`) also needs
to react to `ChatState` the idiomatic way for your framework.

## GetX

```dart
class ChatGetxController extends GetxController {
  ChatGetxController({required this.chatController});
  final ChatController chatController;

  late final Rx<ChatState> state = chatController.currentState.obs;

  @override
  void onInit() {
    super.onInit();
    chatController.stream.listen((newState) => state.value = newState);
  }

  @override
  void onClose() {
    chatController.dispose();
    super.onClose();
  }
}
```

Use with `Obx(() => ...)` wherever you read `state.value`. Full version:
`/example/lib/state_bindings/getx_binding_example.dart`.

## Riverpod

```dart
final chatControllerProvider = Provider.autoDispose<ChatController>((ref) {
  final controller = ChatController(currentUserId: currentUserId);
  ref.onDispose(controller.dispose);
  return controller;
});

final chatStateProvider = StreamProvider.autoDispose<ChatState>((ref) {
  return ref.watch(chatControllerProvider).stream;
});
```

`chatControllerProvider` is a plain `Provider` (the controller itself
needs no Riverpod-specific wrapper); only its *stream* goes through
`StreamProvider`. Full version:
`/example/lib/state_bindings/riverpod_binding_example.dart`.

## Bloc / Cubit

```dart
class ChatCubit extends Cubit<ChatState> {
  ChatCubit({required this.chatController}) : super(chatController.currentState) {
    _subscription = chatController.stream.listen(emit);
  }

  final ChatController chatController;
  late final StreamSubscription<ChatState> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    chatController.dispose();
    return super.close();
  }
}
```

A `Cubit` is already "hold a value, emit new ones" — this one's whole
job is subscribing and re-emitting. Use with `BlocBuilder<ChatCubit,
ChatState>`. Full version:
`/example/lib/state_bindings/bloc_binding_example.dart`.

## Plain `setState`

No binding needed at all — `ChatView`'s internal `StreamBuilder` is
sufficient on its own:

```dart
class MyChatScreen extends StatefulWidget {
  @override
  State<MyChatScreen> createState() => _MyChatScreenState();
}

class _MyChatScreenState extends State<MyChatScreen> {
  late final ChatController _controller = ChatController(currentUserId: 'me');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatView(controller: _controller, theme: ChatTheme.light(), onSendText: ...);
  }
}
```

Full version: `/example/lib/no_socket/local_preview_screen.dart`.

## Provider (ChangeNotifier-based)

Not shown as a full example, but the shape is identical to the Riverpod
case with `ChangeNotifierProvider` swapped for a thin wrapper:

```dart
class ChatChangeNotifier extends ChangeNotifier {
  ChatChangeNotifier(this.chatController) {
    _subscription = chatController.stream.listen((_) => notifyListeners());
  }
  final ChatController chatController;
  late final StreamSubscription<ChatState> _subscription;
  ChatState get state => chatController.currentState;

  @override
  void dispose() {
    _subscription.cancel();
    chatController.dispose();
    super.dispose();
  }
}
```

Use with `ChangeNotifierProvider` + `Consumer`/`context.watch`.

## Multiple conversations at once

Each `ChatController` owns exactly one conversation. For a chat-list app
with several open conversations, keep one controller per
`conversationId` (a `Map<String, ChatController>` in whatever state
container you're using) and dispose each controller when its
conversation screen closes — this is the "Chat A → Chat B → Chat A must
not leave listeners from Chat B active" lifecycle rule from
[`03_ARCHITECTURE.md`](03_ARCHITECTURE.md).
