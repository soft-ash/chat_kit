# 10. API Integration

`ChatController` is the seam between your backend and the UI. It never
opens a socket, never makes an HTTP call, and never knows what transport
you're using — it only exposes methods for you to call when your
transport layer receives something, and callbacks
(`ChatView.onSendText`, etc.) that fire when the person does something
that needs to leave the device.

For a complete, runnable reference, see
`/example/lib/with_socket/socket_chat_screen.dart` — everything below is
extracted from that file.

## The shape of the integration

```
Your Socket / REST client
         │
         ▼
  ChatController methods        (addIncomingMessage, updateMessageStatus, ...)
         │
         ▼
    Stream<ChatState>
         │
         ▼
      ChatView / MessageList
         │
         ▲
  onSendText / onSendMedia / onTypingChanged callbacks
         │
         ▼
Your Socket / REST client
```

## Receiving messages

Whatever your transport is, when a message arrives, parse it into a
`ChatMessage` and hand it to the controller:

```dart
socket.on('message:new', (data) {
  final json = Map<String, dynamic>.from(data as Map);
  chatController.addIncomingMessage(ChatMessage.fromJson(json));
});
```

`ChatMessage.fromJson` uses `SafeJson` throughout — a malformed payload
degrades to sensible defaults instead of throwing, so a single bad
message from the server can't crash the chat screen (see
[`04_MODELS.md`](04_MODELS.md)).

If the same message might arrive twice (common with at-least-once socket
delivery), you don't need to deduplicate yourself —
`addIncomingMessage` checks the id against its internal index and
updates in place instead of creating a second bubble.

## Sending messages (optimistic UI)

The standard pattern: show the message immediately with
`ChatMessageStatus.sending`, then flip its status once the server
confirms.

```dart
void handleSendText(String text) {
  final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
  final message = ChatMessage(
    id: localId,
    senderId: currentUserId,
    type: ChatMessageType.text,
    text: text,
    createdAt: DateTime.now(),
    status: ChatMessageStatus.sending,
  );

  chatController.addOutgoingMessage(message); // shows instantly

  socket.emit('message:send', {...message.toJson(), 'localId': localId});
}

socket.on('message:ack', (data) {
  final json = Map<String, dynamic>.from(data as Map);
  final localId = json['localId'] as String?;
  if (localId != null) {
    chatController.updateMessageStatus(localId, ChatMessageStatus.sent);
  }
});
```

If the send fails, call
`chatController.updateMessageStatus(localId, ChatMessageStatus.failed)`
instead — `MediaUploadOverlay`/`MessageBubble` already know how to show
a retry affordance for a failed message; wire `onRetryAttachment`
(for media) or your own retry action (for text) to re-attempt the same
`socket.emit`.

## Sending media (upload flow)

The package never uploads anything itself. The flow:

1. Host app picks files (`image_picker`, `file_picker`, camera).
2. Build `ChatAttachment`s with `localPath` set, `url: null`.
3. Show them via `ChatInputBar.pendingAttachments` (optionally review via
   `AttachmentReviewScreen` first).
4. On send (`onSendMedia`), upload each file through your own API,
   getting back a real `url`.
5. Update the message's attachments with the resolved `url` via
   `chatController.updateMessage(...)`.

```dart
onSendMedia: (caption, attachments) async {
  final message = ChatMessage(
    id: localId,
    senderId: currentUserId,
    type: attachments.first.type, // or ChatMessageType.image, etc.
    text: caption,
    attachments: attachments,
    createdAt: DateTime.now(),
    status: ChatMessageStatus.sending,
  );
  chatController.addOutgoingMessage(message);

  final uploaded = <ChatAttachment>[];
  for (final attachment in attachments) {
    final url = await myApi.upload(File(attachment.localPath!));
    uploaded.add(attachment.copyWith(url: url, uploadProgress: 1.0));
  }

  chatController.updateMessage(message.copyWith(
    attachments: uploaded,
    status: ChatMessageStatus.sent,
  ));
  socket.emit('message:send', message.toJson());
},
```

For per-file progress while uploading, call
`chatController.updateMessage` with the attachment's `uploadProgress`
updated as your upload client reports it — `MediaUploadOverlay` reads
that value directly.

## Cursor-based pagination

```dart
ChatController(
  currentUserId: currentUserId,
  onLoadMoreMessages: (cursor) async {
    final response = await myApi.getMessages(
      conversationId: conversationId,
      before: cursor, // null on the first call
      limit: 30,
    );
    return response.messages.map(ChatMessage.fromJson).toList();
  },
)
```

Return fewer messages than your page size (or an empty list) to signal
"nothing older left" — `ChatController` stops calling `onLoadMoreMessages`
once that happens. See [`05_CONTROLLER.md`](05_CONTROLLER.md#pagination)
for the exact ordering/cursor semantics.

## Typing indicator

```dart
// Outgoing
onTypingChanged: (isTyping) => socket.emit('typing', {
  'userId': currentUserId,
  'conversationId': conversationId,
  'isTyping': isTyping,
}),

// Incoming
socket.on('typing', (data) {
  final json = Map<String, dynamic>.from(data as Map);
  if (json['isTyping'] == true) {
    chatController.setUserTyping(resolveUser(json['userId']));
  } else {
    chatController.clearUserTyping(json['userId']);
  }
});
```

`ChatInputBar` already debounces `onTypingChanged` (only fires "stopped"
after a few seconds of no keystrokes) — you don't need your own
debounce on top of it.

## AI streaming

For a token-by-token response from an LLM API (SSE, a raw stream, or a
polling loop — the package doesn't care which):

```dart
Future<void> sendToAssistant(String userText) async {
  chatController.addOutgoingMessage(ChatMessage(
    id: newId(), senderId: currentUserId, type: ChatMessageType.text,
    text: userText, createdAt: DateTime.now(),
  ));

  final aiMessageId = newId();
  chatController.startStreamingMessage(ChatMessage(
    id: aiMessageId,
    senderId: 'assistant',
    type: ChatMessageType.text,
    text: '',
    createdAt: DateTime.now(),
  ));

  await for (final chunk in myAiClient.streamResponse(userText)) {
    chatController.appendStreamingChunk(aiMessageId, chunk);
  }

  chatController.completeStreamingMessage(aiMessageId);
}
```

`MessageBubble` shows a blinking `StreamingCursor` automatically while
`isStreaming` is `true`, and clears it the moment
`completeStreamingMessage` runs. Enable Markdown rendering for the AI
conversation with `enableMarkdown: true` on `MessageList`/`ChatView` —
most model responses use it.

To let the person stop generation mid-stream, cancel your own
stream subscription and call `completeStreamingMessage` yourself; wire
`ChatDefaultActions.stopGenerating` to do exactly that.

## Connection state

```dart
socket.onConnect((_) => chatController.setConnectionState(ChatConnectionState.online));
socket.onDisconnect((_) => chatController.setConnectionState(ChatConnectionState.offline));
```

Read `ChatState.connectionState` (via the controller's stream, or inside
any widget that already receives `ChatState`) to show your own
"reconnecting..." banner — a natural fit for `ChatLayers.aboveMessages`
or `ChatLayers.header`.
