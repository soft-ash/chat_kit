# 5. Controller

`ChatController` is the framework-agnostic brain of one conversation —
plain Dart, no `Widget` in its dependency graph. This document is the
complete method-by-method reference; for *why* it's shaped this way see
[`01_OVERVIEW.md`](01_OVERVIEW.md) and [`03_ARCHITECTURE.md`](03_ARCHITECTURE.md).

## Construction

```dart
ChatController({
  required String currentUserId,
  String? conversationId,
  ChatType type = ChatType.single,
  LoadMoreMessages? onLoadMoreMessages,
  int pageSize = 30,
})
```

- **`currentUserId`** — used by widgets like `MessageList` to decide
  `isMe` per bubble; the controller itself doesn't otherwise use it.
- **`onLoadMoreMessages`** — `Future<List<ChatMessage>> Function(String? cursor)`.
  Called by [`loadMore()`](#pagination) with `null` on the first call,
  then whatever cursor you returned last time. Leave `null` if you don't
  need pagination (e.g. the local-preview example).
- **`pageSize`** — used only to decide whether a returned page is "the
  last one" (`older.length < pageSize` clears `hasMoreMessages`).

## Reading state

| Member | Type | Notes |
|---|---|---|
| `stream` | `Stream<ChatState>` | Broadcast — the one thing every UI subscribes to |
| `currentState` | `ChatState` | Synchronous snapshot, useful before the first stream event or to seed a `.obs`/`StreamBuilder` |
| `messages` | `List<ChatMessage>` (unmodifiable) | Same list `currentState.messages` exposes |
| `messageById(String id)` | `ChatMessage?` | O(1) average — backed by the internal `Map<String, int>` index |

## Sending & receiving messages

```dart
void addOutgoingMessage(ChatMessage message);  // locally authored — status: sending
void addIncomingMessage(ChatMessage message);  // arrived from socket/API
```

Both append to the end of the list and emit a new `ChatState`. If a
message with the same `id` already exists, `addIncomingMessage`
transparently calls `updateMessage` instead of creating a duplicate —
this is what makes at-least-once socket delivery safe to feed straight
in without deduplicating yourself first.

```dart
void updateMessage(ChatMessage updated);
void updateMessageStatus(String messageId, ChatMessageStatus status);
void editMessage(String messageId, String newText);       // also stamps editedAt
void deleteMessage(String messageId, {bool hard = false}); // soft by default
```

`deleteMessage`'s default (`hard: false`) clears `text`/`attachments`
and sets `isDeleted: true` — the tombstone `MessageBubble` renders
("This message was deleted") instead of removing the row outright. Pass
`hard: true` to actually remove it from the list (index is rebuilt
automatically).

All four of these look the message up via the same O(1) index, replace
it in place, and emit — no full-list scan, no full-list rebuild
downstream (every `MessageBubble` in `MessageList` has `key:
ValueKey(id)`, so only the one affected Element re-renders).

## AI streaming

```dart
void startStreamingMessage(ChatMessage message);
void appendStreamingChunk(String messageId, String chunk);
void completeStreamingMessage(String messageId, {ChatMessageStatus status = ChatMessageStatus.sent});
```

See [`10_API_INTEGRATION.md`](10_API_INTEGRATION.md#ai-streaming) for the
full wiring pattern against a real streaming API. Short version:
`startStreamingMessage` inserts with `isStreaming: true` (typically
empty `text`), `appendStreamingChunk` is called once per token/chunk and
just concatenates onto the existing text, `completeStreamingMessage`
clears the flag.

## Reactions

```dart
void addReaction(String messageId, ChatReaction reaction);
void removeReaction(String messageId, String userId);
```

`addReaction` replaces any prior reaction from the same `userId` on that
message rather than accumulating duplicates — one emoji per person per
message, last write wins.

## Typing indicator

```dart
void setUserTyping(ChatUser user, {Duration autoClearAfter = const Duration(seconds: 5)});
void clearUserTyping(String userId);
```

`setUserTyping` auto-clears itself after `autoClearAfter` if you never
call `clearUserTyping` explicitly — protects against a dropped "stopped
typing" socket event leaving a stale indicator on screen forever.

## Pagination

```dart
Future<void> loadInitial();  // alias for loadMore()
Future<void> loadMore();
```

Calling `loadMore()`:

1. No-ops if already loading, `hasMoreMessages` is `false`, or
   `onLoadMoreMessages` wasn't provided.
2. Sets `isLoadingMore: true`, emits (so a spinner can show).
3. Awaits `onLoadMoreMessages(cursor)`.
4. Prepends the returned messages (skipping any already present by id),
   in the exact order returned — the controller doesn't re-sort.
5. Sets the next cursor and `hasMoreMessages` based on whether a full
   page came back.
6. On any thrown error, sets `loadError` to the exception's string
   instead of propagating — check `ChatState.loadError` to show retry UI.

See `MessageList.onLoadMore`, which is exactly `controller.loadMore` in
every example.

## Connection state

```dart
void setConnectionState(ChatConnectionState state);
```

Purely a pass-through slot — push your socket's actual connectivity in
here (`online`/`connecting`/`offline`) whenever it changes; nothing in
the controller reacts to it automatically, but it's part of the emitted
`ChatState` for any UI (a banner, a status dot) that wants to read it.

## Lifecycle

```dart
void dispose();
```

**Always call this** when the owning screen/controller is disposed —
`State.dispose()`, `GetxController.onClose()`, `Cubit.close()`, whatever
your binding's teardown hook is. It cancels the internal typing-clear
timer and closes the stream controller. Skipping this is exactly the
"listeners from Chat B still active while viewing Chat A" leak the
architecture doc warns about — see every binding example in
[`11_STATE_MANAGEMENT.md`](11_STATE_MANAGEMENT.md) for where this call
belongs in each framework's teardown hook.
