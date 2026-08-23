# 7. Widgets Reference

Every widget below is independently exported from
`package:advanced_chat_kit/advanced_chat_kit.dart` and independently
usable — `ChatView` composes many of them for convenience, but none of
them require going through `ChatView` first.

## Layout & assembly (`widgets/layout/`)

### `ChatView`

The full assembly — see [`02_GETTING_STARTED.md`](02_GETTING_STARTED.md)
for a complete example. Required: `controller`, `theme`, `onSendText`.
Everything else is an optional pass-through to the `MessageList`/
`ChatInputBar` it composes internally (message actions, reactions,
Markdown, link taps, voice recording, pending attachments, reply state,
`background`, `layers`, ...) — see the constructor doc comments in
`chat_view.dart` for the full parameter list, since it mirrors
`MessageList` and `ChatInputBar` almost one-for-one.

### `ChatBackground`

Named constructors, exactly one style per instance:

```dart
ChatBackground.color(Color color)
ChatBackground.gradient(Gradient gradient)
ChatBackground.image(ImageProvider image, {BoxFit fit = BoxFit.cover})
ChatBackground.custom(Widget widget)
```

Pass to `ChatView.background` or render directly via
`ChatBackgroundView(background: ..., child: ...)`.

### `ChatLayers`

Seven independently-optional `Widget?` slots matching
`ChatLayerPosition`: `header`, `belowHeader`, `aboveMessages`,
`belowMessages`, `aboveInput`, `belowInput`, `overlay`. Pass to
`ChatView.layers`.

## Message rendering (`widgets/message/`)

### `MessageBubble`

The default sender/receiver bubble. Required: `message`, `isMe`,
`theme`. Notable optional parameters: `sender` (for name/avatar),
`isFirstInGroup`/`isLastInGroup` (from `resolveGroupInfo`),
`customMessageBuilder`, `onTap`/`onLongPress`, `onReplyPreviewTap`,
`onRetryAttachment`, `onOpenDocument`, `onLocationTap`, `onContactTap`,
`actions` (auto-opens the long-press sheet when non-null),
`reactionEmojis`, `currentUserId` + `onToggleReaction` (reactions hidden
entirely if `currentUserId` is `null`), `enableMarkdown`, `onLinkTap`.

### `MessageList`

Scrollable, grouped, auto-scrolling list of `ChatState.messages`.
Required: `state`, `currentUserId`, `theme`. Mirrors nearly every
`MessageBubble` parameter above plus: `userResolver` (`ChatUser?
Function(String senderId)`), `onLoadMore` (wire to
`controller.loadMore`), `emptyState`, `typingIndicator` (slot — pass a
`TypingIndicatorBubble` when `state.isTyping`).

### `MarkdownText`

Standalone Markdown renderer — see
[`03_ARCHITECTURE.md`](03_ARCHITECTURE.md#dependency-policy) for scope.
Required: `data`, `baseStyle`, `linkStyle` (`ChatLinkTextStyle`),
`codeBackground`. Optional: `onLinkTap`.

### `LinkifiedText`

Plain text with tappable `http`/`https` spans — what `MessageBubble`
uses for non-Markdown text messages. Required: `text`, `style`,
`linkStyle`. Optional: `onLinkTap`.

### `LinkPreviewCard`

Renders a `ChatLinkPreview`. Required: `preview`, `theme`. Optional:
`onTap`, plus independent `titleStyle`/`descriptionStyle` overrides if
you need this one card to diverge from the theme's typography.

### `LocationPreviewCard`

Required: `address`, `theme`. Optional: `label` (defaults to `'Pinned
location'`), `staticMapImageUrl` (a real static-map image you fetched —
falls back to a decorative gridded placeholder if omitted), `onTap`.

### `MessageReactionsRow`

Groups raw `List<ChatReaction>` into emoji+count chips. Required:
`reactions`, `currentUserId`, `theme`, `onToggle` (`ValueChanged<String>`
— the emoji tapped).

### `MessageStatusIcon`

The small sending/sent/delivered/read/failed glyph. Required: `status`,
`colors`.

### `TypingIndicatorBubble`

Animated three-dot bubble. Required: `theme`. Feed it into
`MessageList.typingIndicator` guarded by `state.isTyping`.

### `StreamingCursor`

Blinking cursor for in-progress AI messages. Required: `color`.
`MessageBubble` renders this automatically when `message.isStreaming`
is `true` — you don't normally construct it directly.

## Input (`widgets/input/`)

### `ChatInputBar`

The full input bar. Required: `theme`, `onSendText`. Notable optional
parameters: `onTypingChanged`, `replyingTo` + `onCancelReply`,
`inlineActions`/`expandableActions` (`List<ChatInputAction>`),
`enableVoice` + `onVoiceRecordStart`/`Cancel`/`Stop`,
`pendingAttachments` + `onRemovePendingAttachment`/
`onTapPendingAttachment` + `onSendMedia` (multi-attachment sending — see
[`08_FEATURES.md`](08_FEATURES.md)), `composerLinkPreview` +
`onDismissLinkPreview` (shows `LinkPreviewComposerBar` while typing a
URL), `hintText`, `controller`/`focusNode` (bring your own
`TextEditingController` if you need one).

### `ChatInputAction` / `ChatActionGroup`

```dart
ChatInputAction({required id, required icon, required label, required onPressed, color})
```

Used for both `inlineActions` (icons beside the field) and
`expandableActions` (the "+"-toggled panel row).

### `PendingAttachmentsBar`

The thumbnail strip for media selected but not yet sent. Required:
`attachments`, `theme`. Optional: `onRemove`, `onTapPreview`. Rendered
automatically inside `ChatInputBar` when `pendingAttachments` is
non-empty — construct directly only for a custom layout.

### `ReplyPreviewBar`

The "Replying to X" strip above the input. Required: `reply`, `theme`,
`onCancel`.

### `LinkPreviewComposerBar`

Shows a live link-preview card *while composing*, before sending —
mirrors what the recipient will see. Required: `preview`, `theme`,
`onDismiss`.

## Media (`widgets/media/`)

All of these are what `MessageBubble` renders internally for their
respective `ChatMessageType`; construct directly only if you're building
a custom layout that bypasses `MessageBubble`.

| Widget | Required params | Notes |
|---|---|---|
| `ChatImageMessage` | `attachment`, `status`, `theme` | Tap opens `ImageViewerScreen` |
| `ChatVideoMessage` | `attachment`, `status`, `theme` | Tap opens `VideoPlayerScreen` |
| `ChatAudioMessage` | `attachment`, `status`, `theme`, `isMe` | Owns its own lazily-created `AudioPlayer` |
| `ChatDocumentMessage` | `attachment`, `status`, `theme`, `isMe` | `onOpen` callback — opening the file is host-app logic |
| `ChatContactMessage` | `name`, `theme`, `isMe` | `subtitle`, `avatarUrl`, `onTap` optional |
| `MediaUploadOverlay` | `status`, `progress` | Shared sending-spinner/retry-icon overlay used by all the above |
| `ImageViewerScreen` | `imageUrl` | Full-screen pinch-zoom; push via `Navigator` |
| `VideoPlayerScreen` | `videoUrl` | Full-screen player; push via `Navigator` |
| `AttachmentReviewScreen` | `attachments`, `theme` | Preview-before-send flow — see [`08_FEATURES.md`](08_FEATURES.md) |

## Actions (`widgets/actions/`)

| Widget/function | Purpose |
|---|---|
| `ChatMessageAction` | Model for one long-press menu row |
| `ChatDefaultActions` | Static builders: `reply`, `forward`, `copy`, `edit`, `pin`, `save`, `share`, `translate`, `report`, `delete`, `regenerate`, `stopGenerating` |
| `showMessageActionSheet(...)` | Opens the long-press sheet (reaction row + action list) |
| `ReactionBar` | The quick-tap emoji strip at the top of the action sheet |
| `showForwardPickerSheet(...)` | Searchable multi-select "Forward to" picker over `List<ChatForwardTarget>` |
| `ChatForwardTarget` | `{id, name, avatarUrl}` — one forward destination |
| `ChatCallButtons` | Audio/video call icon buttons — fires `onCall(ChatCallType)` only |
| `CallStatusBanner` | "Calling.../In call" strip — `label`, `onEndCall` |

## Custom messages (`widgets/custom/`)

See [`09_CUSTOM_MESSAGES.md`](09_CUSTOM_MESSAGES.md) for the full guide.

| Class | Purpose |
|---|---|
| `ChatWidgetRegistry` | `register(type, builder)` / `asMessageBuilder()` |
| `ChatWidgetAction` / `ChatWidgetActionGroup` | Buttons *inside* a custom card (e.g. Accept/Cancel) — responsive Row↔Wrap |
| `DateInvitationCard` | Worked example built on the registry |

## Miscellaneous

- **`ChatAvatar`** (`widgets/chat_avatar.dart`) — network image with
  initials fallback. Required: `user`, `size`, `colors`.
- **`resolveGroupInfo(messages, index)`** (`widgets/message/message_group_utils.dart`)
  — the consecutive-message grouping function `MessageList` uses
  internally; exposed in case you're building a custom list and want the
  same grouping behavior.
