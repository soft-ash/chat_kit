# 4. Models

Every model in `lib/src/model/` is immutable, has `fromJson`/`toJson`,
and (except where noted) a `copyWith`. All `fromJson` factories parse
through `SafeJson` — a malformed or missing field never throws; it falls
back to a safe default instead (see [`03_ARCHITECTURE.md`](03_ARCHITECTURE.md)).

## `ChatUser`

A participant in a conversation — kept intentionally minimal. Your real
user model can carry anything extra it needs and map into this at the
edges (a `toChatUser()` extension method on your own model is the usual
pattern).

| Field | Type | Default | Notes |
|---|---|---|---|
| `id` | `String` | required | |
| `name` | `String` | required | |
| `avatarUrl` | `String?` | `null` | |
| `isOnline` | `bool` | `false` | |
| `lastSeen` | `DateTime?` | `null` | |

Equality is by `id` only (`==`/`hashCode` overridden).

## `ChatMessage`

The central model. One class handles text, media, system, and
application-defined custom messages.

| Field | Type | Default | Notes |
|---|---|---|---|
| `id` | `String` | required | |
| `senderId` | `String` | required | |
| `conversationId` | `String?` | `null` | |
| `text` | `String?` | `null` | Also the caption for media messages |
| `type` | `ChatMessageType` | required | `text`, `image`, `video`, `audio`, `document`, `location`, `contact`, `system`, `custom` |
| `customType` | `String?` | `null` | Only meaningful when `type == custom` — the [`ChatWidgetRegistry`](09_CUSTOM_MESSAGES.md) lookup key |
| `createdAt` | `DateTime` | required | |
| `updatedAt` | `DateTime?` | `null` | |
| `editedAt` | `DateTime?` | `null` | Setting this is what `message.isEdited` checks |
| `status` | `ChatMessageStatus` | `sent` | `sending`, `sent`, `delivered`, `read`, `failed` |
| `attachments` | `List<ChatAttachment>` | `[]` | |
| `replyTo` | `ChatReply?` | `null` | |
| `forwardedFrom` | `ForwardedMessage?` | `null` | |
| `reactions` | `List<ChatReaction>` | `[]` | |
| `linkPreview` | `ChatLinkPreview?` | `null` | |
| `metadata` | `Map<String, dynamic>?` | `null` | Freeform — custom-message payload *and* any extra field on a normal message |
| `isDeleted` | `bool` | `false` | Soft-delete tombstone flag |
| `isStreaming` | `bool` | `false` | AI streaming in progress — see [`10_API_INTEGRATION.md`](10_API_INTEGRATION.md) |

Convenience getters: `isEdited`, `hasAttachments`, `isCustom`.
Equality is by `id` only.

**Custom messages**: set `type: ChatMessageType.custom`, `customType:
'your_type_string'`, and put your payload in `metadata`. `customType` is
also read from `metadata['customType']` if not set directly on the
model, so a server that only knows how to send a flat JSON blob still
works.

## `ChatAttachment`

A single media/file attached to a message. A message can hold several
(see [multi-attachment sending](07_WIDGETS_REFERENCE.md#pendingattachmentsbar)).

| Field | Type | Default | Notes |
|---|---|---|---|
| `id` | `String` | required | |
| `type` | `ChatMessageType` | required | Reuses the message-type enum |
| `url` | `String?` | `null` | Remote URL — `null` while still uploading |
| `localPath` | `String?` | `null` | Local file path — used for preview before/while uploading |
| `thumbnailUrl` | `String?` | `null` | |
| `fileName` | `String?` | `null` | |
| `fileSizeBytes` | `int?` | `null` | |
| `duration` | `Duration?` | `null` | Audio/video only |
| `width` / `height` | `double?` | `null` | Image/video only |
| `uploadProgress` | `double` | `1.0` | `0.0`–`1.0` |

`isUploaded` getter: `true` once `url` is set. Both `url` and
`localPath` can be non-null at once — the UI prefers `url` when present,
falls back to `localPath` (guarded for web, where `dart:io.File` isn't
meaningful) otherwise.

## `ChatReaction`

One user's emoji reaction on one message. `ChatMessage.reactions` is a
flat `List<ChatReaction>`; [`MessageReactionsRow`](07_WIDGETS_REFERENCE.md)
groups them into emoji→count chips at render time — the model itself
stays ungrouped.

| Field | Type |
|---|---|
| `userId` | `String` |
| `emoji` | `String` |
| `reactedAt` | `DateTime` |

No `copyWith` — reactions are small enough to just construct fresh.

## `ChatReply`

A lightweight *snapshot* of the message being replied to — not the full
original `ChatMessage`. Deliberately: if the original is later edited or
deleted, the reply keeps showing what the replying user actually saw at
reply-time.

| Field | Type | Notes |
|---|---|---|
| `messageId` | `String` | |
| `senderId` | `String` | |
| `senderName` | `String` | |
| `type` | `ChatMessageType` | |
| `preview` | `String?` | Short text snippet |
| `thumbnailUrl` | `String?` | Shown as a small square thumbnail when replying to media |

## `ForwardedMessage`

A *reference*, not a duplicate of the original message — used when
forwarding. The backend decides how a forwarded message is ultimately
persisted; the package just carries this pointer.

| Field | Type |
|---|---|
| `originalMessageId` | `String` |
| `originalSenderId` | `String` |
| `type` | `ChatMessageType` |
| `preview` | `String?` |

## `ChatLinkPreview`

Resolved OpenGraph-style metadata for a URL found in a text message.
*Resolving* this (an HTTP fetch + HTML parse) is the host app's job —
the package only renders whatever you set on `ChatMessage.linkPreview`.

| Field | Type | Notes |
|---|---|---|
| `url` | `String` | |
| `title` | `String?` | |
| `description` | `String?` | |
| `imageUrl` | `String?` | |
| `siteName` | `String?` | Shown as the domain line if set, else derived from `url` |
| `statsLabel` | `String?` | Optional metrics line, e.g. `"32K views · 4.2K reactions"` |

## Enums (`core/enums/chat_enums.dart`)

| Enum | Values |
|---|---|
| `ChatType` | `single`, `group`, `ai` |
| `ChatMessageType` | `text`, `image`, `video`, `audio`, `document`, `location`, `contact`, `system`, `custom` |
| `ChatMessageStatus` | `sending`, `sent`, `delivered`, `read`, `failed` |
| `ChatLayerPosition` | `aboveHeader`, `belowHeader`, `aboveMessages`, `belowMessages`, `aboveInput`, `belowInput`, `overlay` |
| `ChatCallType` | `audio`, `video` |
| `ChatConnectionState` | `online`, `connecting`, `offline` |

## `ChatState` (in `controller/`, not `model/` — see [`05_CONTROLLER.md`](05_CONTROLLER.md))

The immutable snapshot `ChatController` emits. Listed here for
completeness since it's the shape every UI in the package ultimately
reads from:

| Field | Type | Default |
|---|---|---|
| `messages` | `List<ChatMessage>` | `[]` |
| `typingUsers` | `Map<String, ChatUser>` | `{}` |
| `connectionState` | `ChatConnectionState` | `online` |
| `isLoadingMore` | `bool` | `false` |
| `hasMoreMessages` | `bool` | `true` |
| `loadError` | `String?` | `null` |

Convenience getters: `isEmpty`, `isTyping`.
