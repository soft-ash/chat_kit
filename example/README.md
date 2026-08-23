# advanced_chat_kit — examples

Five self-contained ways to see the package in action. Run any one of
them from `lib/main.dart`'s picker screen, or open the individual file
and read it — every example is meant to be read as documentation first,
runnable code second.

| File | What it shows |
|---|---|
| `no_socket/local_preview_screen.dart` | Zero backend — a `ChatController` living entirely in memory. Fastest way to try a theme or layout change. |
| `with_socket/socket_chat_screen.dart` | Real `socket_io_client` transport: connect, join a room, send with optimistic `sending` → `sent` status, receive, typing events. |
| `state_bindings/getx_binding_example.dart` | `ChatController.stream` → `.obs` → `Obx`. |
| `state_bindings/riverpod_binding_example.dart` | `ChatController.stream` → `StreamProvider`. |
| `state_bindings/bloc_binding_example.dart` | `ChatController.stream` → `Cubit.emit`. |

## The one thing to notice across all five

`ChatController` and `ChatView` never change. Only the file that owns
*where messages come from* changes — a fake `Future.delayed`, a real
socket, a `.obs`, a `StreamProvider`, a `Cubit`. That's the whole point
of keeping the package state-management- and transport-agnostic: pick
whichever binding matches the rest of your app, and none of the actual
chat UI code has to know or care.

## Running

```bash
cd example
flutter pub get
flutter run
```

If you only want one of the four extra dependencies (`get`,
`flutter_riverpod`, `flutter_bloc`, `socket_io_client`), delete the
matching example file and its line from `pubspec.yaml` — none of them are
required by `advanced_chat_kit` itself, only by the specific example
demonstrating that integration.
