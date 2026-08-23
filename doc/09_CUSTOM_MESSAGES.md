# 9. Custom Messages

This is the extension point that lets the package support "product
cards", "payment cards", "polls", "bookings", or literally any
application-specific message without ever modifying package source.

## The pattern

1. Server/host sends a message with `type: custom` and a `customType`
   string identifying which kind of card it is. The actual payload lives
   in `metadata` — a plain `Map<String, dynamic>`.
2. You register a builder function for that `customType` on a
   `ChatWidgetRegistry`.
3. You pass `registry.asMessageBuilder()` as `customMessageBuilder` to
   `MessageList`/`ChatView`.

The package never interprets `metadata` itself — it's purely declarative
data, never executable code (see [`03_ARCHITECTURE.md`](03_ARCHITECTURE.md)
and the security note in the original architecture doc). A malicious or
malformed `metadata` map can make your card render wrong; it can't make
the package *do* anything it wasn't already capable of.

## Worked example: the date-invitation card

This ships with the package as a complete reference
(`lib/src/widgets/custom/examples/date_invitation_card.dart`).

**The message**, as it would arrive from your backend:

```json
{
  "id": "m123",
  "senderId": "u1",
  "type": "custom",
  "customType": "date_invitation",
  "createdAt": "2026-01-01T12:00:00Z",
  "metadata": {
    "title": "Date with GoldenHour",
    "location": "Amber & Oak Cafe",
    "time": "Tomorrow 4:00 PM",
    "travelTime": "12 min"
  }
}
```

**Registering the builder:**

```dart
final registry = ChatWidgetRegistry()
  ..register('date_invitation', (context, message, isMe) {
    return DateInvitationCard(
      message: message,
      theme: myTheme,
      onAccept: () => myController.respondToInvite(message.id, accepted: true),
      onCancel: () => myController.respondToInvite(message.id, accepted: false),
    );
  });
```

**Wiring it in:**

```dart
ChatView(
  controller: chatController,
  theme: myTheme,
  onSendText: ...,
  customMessageBuilder: registry.asMessageBuilder(),
)
```

That's the entire integration. `MessageBubble` calls
`customMessageBuilder(context, message, isMe)` for every message; if it
returns `null` (not a `custom` type, or a `customType` with no
registered builder), the bubble falls back to its normal rendering —
which for an unregistered custom type is a small "Unsupported message —
register a builder" placeholder rather than a crash.

## Building your own card

A custom card is a completely normal `StatelessWidget`/`StatefulWidget`.
The only two things it needs from the package are:

1. Read your fields out of `message.metadata` (type-check each field —
   it's untrusted remote data, same as any other `fromJson`; see
   `SafeJson`'s pattern in [`04_MODELS.md`](04_MODELS.md)).
2. Use `ChatTheme` for colors/spacing so it visually matches the rest of
   the conversation.

If your card needs multiple action buttons (Accept/Cancel/Details, or
however many), use `ChatWidgetActionGroup` — it automatically switches
between a `Row` of equal-width buttons and a `Wrap` if there isn't
enough horizontal room, so you don't have to think about narrow-screen
overflow yourself:

```dart
ChatWidgetActionGroup(
  theme: theme,
  actions: [
    ChatWidgetAction(id: 'accept', label: 'Accept', isPrimary: true, onPressed: onAccept),
    ChatWidgetAction(id: 'details', label: 'Details', onPressed: onDetails),
    ChatWidgetAction(id: 'cancel', label: 'Cancel', onPressed: onCancel),
  ],
)
```

## Multiple custom types

Register as many as you need on the same registry — each `customType`
string maps to its own builder:

```dart
final registry = ChatWidgetRegistry()
  ..register('date_invitation', (context, message, isMe) => DateInvitationCard(...))
  ..register('product', (context, message, isMe) => ProductCard(message.metadata))
  ..register('payment', (context, message, isMe) => PaymentCard(message.metadata))
  ..register('poll', (context, message, isMe) => PollCard(message, onVote: ...));
```

## Sending a custom message

Constructing one locally (e.g. after the user fills out a form in your
app) is just a normal `ChatMessage`:

```dart
chatController.addOutgoingMessage(
  ChatMessage(
    id: newId(),
    senderId: currentUserId,
    type: ChatMessageType.custom,
    customType: 'date_invitation',
    createdAt: DateTime.now(),
    metadata: {
      'title': 'Date with GoldenHour',
      'location': 'Amber & Oak Cafe',
      'time': 'Tomorrow 4:00 PM',
      'travelTime': '12 min',
    },
  ),
);
// then send message.toJson() over your socket/API as usual
```

## `ChatWidgetRegistry` API

```dart
class ChatWidgetRegistry {
  ChatWidgetRegistry({Map<String, ChatCustomWidgetBuilder>? widgets});

  void register(String customType, ChatCustomWidgetBuilder builder);
  void unregister(String customType);
  bool isRegistered(String customType);
  List<String> get registeredTypes;

  ChatMessageBuilder asMessageBuilder(); // pass this to customMessageBuilder
}

typedef ChatCustomWidgetBuilder = Widget Function(
  BuildContext context,
  ChatMessage message,
  bool isMe,
);
```
