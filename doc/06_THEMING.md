# 6. Theming

Every visual value in the package's default widgets — color, gradient,
size, padding, radius, font — comes from a `ChatTheme` (or, for a few
widgets, their own constructor override). Nothing is a hardcoded literal
buried in a `build()` method. This document lists every field on every
theme class.

## `ChatTheme` — the top-level object

```dart
class ChatTheme {
  final ChatColors colors;
  final ChatTypography typography;
  final ChatDimensions dimensions;
  final ChatSpacing spacing;
  final ChatLinkTextStyle linkStyle;
}
```

Two starting points: `ChatTheme.light()` and `ChatTheme.dark()`. Compose
only the pieces you want to change:

```dart
final myTheme = ChatTheme.light().copyWith(
  colors: ChatColors.light().copyWith(
    senderBubble: const Color(0xFF7C3AED),
    senderBubbleGradient: const LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
    ),
  ),
  dimensions: const ChatDimensions(messageBubbleRadius: 22),
);
```

## `ChatColors`

| Field | Used for |
|---|---|
| `senderBubble` | Outgoing bubble background (ignored if `senderBubbleGradient` is set) |
| `senderText` | Text/icon color on outgoing bubbles |
| `receiverBubble` | Incoming bubble background |
| `receiverText` | Text/icon color on incoming bubbles |
| `background` | Chat screen / input bar background |
| `inputBackground` | Text field fill, action panel background, code blocks |
| `inputBorder` | Text field border, dividers |
| `hintText` | Placeholder text, timestamps, secondary labels |
| `primary` | Accent — send button, links inside cards, "mine" reaction highlight |
| `onPrimary` | Text/icon color on top of `primary` |
| `timestamp` | Bubble timestamp text |
| `linkText` | *(legacy fallback — prefer `ChatTheme.linkStyle`, see below)* |
| `danger` | Failed status, destructive action labels, delete icons |
| `success` | Reserved for host-app use (delivered/read affordances beyond the built-in status icon) |
| `senderBubbleGradient` | `Gradient?` — takes precedence over `senderBubble` when set |
| `backgroundGradient` | `Gradient?` — reserved for host-app background compositions; see also [`ChatBackground`](07_WIDGETS_REFERENCE.md#chatbackground) for the full color/gradient/image/custom background system |

`ChatColors.light()` and `.dark()` give you complete, ready-to-use
palettes; every field is still individually overridable via `copyWith`.

## `ChatTypography`

Six `TextStyle` fields, all with sensible defaults so you only override
what you need:

| Field | Default |
|---|---|
| `messageText` | `fontSize: 15, height: 1.35` |
| `senderName` | `fontSize: 12, fontWeight: w600` |
| `timestamp` | `fontSize: 11` |
| `inputText` | `fontSize: 15` |
| `inputHint` | `fontSize: 15` |
| `systemMessage` | `fontSize: 12, fontStyle: italic` |

## `ChatDimensions`

| Field | Default | Controls |
|---|---|---|
| `avatarSize` | `40` | Reserved for larger avatar contexts (headers, contact cards) |
| `avatarSizeSmall` | `28` | The avatar shown beside grouped message bubbles |
| `sendButtonSize` | `44` | Send/mic round button diameter |
| `inputMinHeight` / `inputMaxHeight` | `48` / `140` | Text field growth range |
| `maxMessageWidthFactor` | `0.78` | Bubble max width as a fraction of screen width |
| `messageBubbleRadius` | `18` | Bubble corner radius (grouped bubbles use a tighter `4` on the shared side) |
| `actionIconSize` | `24` | Icons in `ChatInputActionPanel` / custom action buttons |

## `ChatSpacing`

| Field | Default | Controls |
|---|---|---|
| `messagePadding` | `12` | Padding inside a bubble |
| `inputPadding` | `10` | Padding around the input row |
| `sectionSpacing` | `8` | Reserved general-purpose spacing unit |
| `attachmentSpacing` | `6` | Reserved for attachment-grid layouts |
| `listPaddingHorizontal` / `listPaddingVertical` | `12` / `8` | Message list outer padding |
| `sameSenderGap` | `2` | Vertical gap between two consecutive bubbles from the same sender |
| `differentSenderGap` | `12` | Vertical gap when the sender changes (or the grouping window elapses) |

## `ChatLinkTextStyle`

Kept deliberately separate from `ChatColors`/`ChatTypography` — link
styling (inside plain text, inside Markdown, and the raw-URL line atop a
link preview card) changes independently of the rest of the message
text far more often than any other single style decision, so it gets its
own small value object instead of being folded into a general-purpose
one.

| Field | Type | Default |
|---|---|---|
| `color` | `Color` | `Color(0xFF3B82F6)` |
| `fontSize` | `double?` | `null` (inherits surrounding text size) |
| `fontWeight` | `FontWeight?` | `null` (inherits) |
| `decoration` | `TextDecoration` | `TextDecoration.underline` |

```dart
ChatTheme.light().copyWith(
  linkStyle: const ChatLinkTextStyle(
    color: Color(0xFF16A34A),
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.none,
  ),
)
```

`.apply(TextStyle base)` merges onto a base style, only overriding the
fields this `ChatLinkTextStyle` actually sets — a link naturally
inherits the surrounding paragraph's font size unless you deliberately
want it to differ.

## Per-widget style overrides

A handful of widgets accept style objects directly in their own
constructor, layered *on top of* whatever `ChatTheme` provides, for the
cases where "restyle this one call site" shouldn't mean "restyle
everything using this theme":

- `LinkPreviewCard` — independent title/description text styles
- `LocationPreviewCard` — independent label/address text styles

See [`07_WIDGETS_REFERENCE.md`](07_WIDGETS_REFERENCE.md) for exact
parameter names on each.

## The rule this all follows

If you find yourself wanting to change *one* visual thing and the only
way to do it is edit package source — that's a bug in the package's
theming coverage, not something to work around. Every phase of this
package's development treated "is this value a constructor parameter"
as a hard requirement, not a nice-to-have.
