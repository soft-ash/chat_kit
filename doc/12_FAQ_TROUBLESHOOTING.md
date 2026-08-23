# 12. FAQ & Troubleshooting

## "My messages aren't showing up"

Check that you're calling `addIncomingMessage`/`addOutgoingMessage` on
the *same* `ChatController` instance that's passed to `ChatView`/
`MessageList`. A common mistake when wiring a state-management binding
is constructing a second `ChatController` by accident (e.g. inside a
`build()` method that re-runs) instead of reusing the one created in
`initState`/a provider.

## "The list doesn't scroll to the bottom on a new message"

`MessageList` only auto-scrolls if the user was already near the bottom
(`_stickToBottom`, based on scroll position within 80px of max extent) —
this is intentional, so it doesn't yank someone away from a message
they're reading further up. If you want to force a jump-to-bottom
regardless (e.g. right after sending your own message), that's a
`ScrollController` you'd own yourself in a custom list layout; `ChatView`
doesn't currently expose one.

## "Reactions aren't showing"

`MessageBubble`/`MessageList` hide reactions entirely if `currentUserId`
is `null` — this is required to know whose reaction is "mine" for the
highlighted-chip styling. Make sure `currentUserId` is passed through
(it is automatically via `ChatView`, using `controller.currentUserId`;
double-check if you're using `MessageList` directly).

## "Long-press doesn't open the action sheet"

`MessageBubble.actions` (or `MessageList.messageActions`) must be
non-null and non-empty for the sheet to open automatically. If it's
`null`, long-press only fires `onLongPress` (or `onMessageLongPress`) —
useful if you want to build your own menu instead of using
`showMessageActionSheet`.

## "Markdown isn't rendering, I just see the raw `**bold**` text"

Set `enableMarkdown: true` on `MessageList`/`ChatView` (or per-bubble on
`MessageBubble`). It defaults to `false` because most human-to-human
chat text shouldn't be Markdown-interpreted (someone typing `*not
sure*` isn't asking for italics) — turn it on specifically for AI
conversations. See [`10_API_INTEGRATION.md`](10_API_INTEGRATION.md#ai-streaming).

## "Links aren't clickable"

Plain-text links work automatically (`LinkifiedText` detects any
`http(s)://` substring). If a link isn't detected, check it actually has
an explicit scheme — `www.example.com` without `http://`/`https://` is
deliberately *not* auto-linked (see the security note in
[`03_ARCHITECTURE.md`](03_ARCHITECTURE.md)).

## "Video/audio won't play"

Almost always a platform setup gap, not a package bug — see
`/SETUP.md`. Common causes: missing `INTERNET` permission on Android,
missing `<queries>` block on Android 11+, `minSdkVersion` below 21, or
(for `http`, not `https`, URLs on iOS) missing the ATS exception.

## "`launchSafeUrl` returns `false` / links don't open"

By design, only `http`/`https` schemes are ever launched (see doc
section 17 in the original architecture spec). If your link preview or
message text contains a `tel:`, `mailto:`, or custom scheme, that's
intentionally refused — handle those cases yourself via `onLinkTap` if
you need them.

## "The custom message I registered isn't rendering"

Checklist:
1. Is `message.type` actually `ChatMessageType.custom`? A message with
   `type: text` and a `customType` field set is still rendered as text.
2. Does `message.customType` (or `metadata['customType']`) exactly match
   the string you `register()`'d?
3. Did you pass `registry.asMessageBuilder()` — not the registry itself
   — as `customMessageBuilder`?

## "Pagination keeps calling `onLoadMoreMessages` forever" / "never calls it again"

Check your return value against `pageSize` (default `30`, or whatever
you passed to `ChatController(pageSize: ...)`). Returning fewer items
than `pageSize` (including an empty list) is what tells the controller
`hasMoreMessages = false`. If your backend's actual page size differs
from the controller's `pageSize`, pass the real value explicitly.

## "I'm seeing duplicate messages after a reconnect"

You shouldn't need to deduplicate before calling
`addIncomingMessage` — it already checks the id against the internal
index and updates in place rather than duplicating (see
[`05_CONTROLLER.md`](05_CONTROLLER.md#sending--receiving-messages)). If
you're still seeing duplicates, check that your server is sending a
stable `id` for the same logical message on redelivery, not generating
a fresh one each time.

## "Should I use `ChatView` or the individual widgets?"

`ChatView` for the common case — a single scrollable conversation
screen. Reach for `MessageList` + `ChatInputBar` directly (skipping
`ChatView`) when your layout genuinely doesn't fit the
header/messages/input stack — e.g. a side-by-side chat + document
viewer, or a chat embedded inside a larger custom screen. Every widget
`ChatView` composes is independently exported for exactly this reason —
see [`03_ARCHITECTURE.md`](03_ARCHITECTURE.md).

## "Can I use this without Flutter's Material widgets (Cupertino-only app)?"

The default widgets use `Material`-family components in a handful of
places (`InkWell`, `Material` for ripple effects, `showModalBottomSheet`
for menus). They render fine inside a `CupertinoApp` in practice (they
don't require a `Scaffold`/`MaterialApp` ancestor for anything critical
to function), but they won't visually match Cupertino's design language
automatically. Full Cupertino-styled equivalents aren't provided — using
`customMessageBuilder`/your own `ChatInputBar` replacement is the path
if you need pixel-perfect iOS-native styling everywhere.

## Where to ask something not covered here

Check [`08_FEATURES.md`](08_FEATURES.md) first — a lot of "does it
support X" questions are answered by that checklist (built vs. UI-hook
vs. intentionally out of scope).
