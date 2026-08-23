# advanced_chat_kit — Documentation

Full reference for the package: what it is, why it's built the way it
is, every model/field, every widget, and how to wire it into a real app.

| # | Document | What's in it |
|---|---|---|
| 1 | [`01_OVERVIEW.md`](01_OVERVIEW.md) | What this package is, the core design principle, what it does and does **not** do |
| 2 | [`02_GETTING_STARTED.md`](02_GETTING_STARTED.md) | Install, minimum working example, project structure |
| 3 | [`03_ARCHITECTURE.md`](03_ARCHITECTURE.md) | Clean-architecture layers, folder structure, why each layer exists |
| 4 | [`04_MODELS.md`](04_MODELS.md) | Every data model, every field, every enum — with types and defaults |
| 5 | [`05_CONTROLLER.md`](05_CONTROLLER.md) | `ChatController` full API — every method, what it does, when to call it |
| 6 | [`06_THEMING.md`](06_THEMING.md) | `ChatTheme`, `ChatColors`, `ChatDimensions`, `ChatSpacing`, `ChatTypography`, `ChatLinkTextStyle` — every field |
| 7 | [`07_WIDGETS_REFERENCE.md`](07_WIDGETS_REFERENCE.md) | Every public widget, grouped by area, with full constructor parameters |
| 8 | [`08_FEATURES.md`](08_FEATURES.md) | Complete feature checklist — what's built, what's a UI hook only, what's intentionally left to the host app |
| 9 | [`09_CUSTOM_MESSAGES.md`](09_CUSTOM_MESSAGES.md) | `ChatWidgetRegistry` — building your own message types (cards, polls, payments, ...) |
| 10 | [`10_API_INTEGRATION.md`](10_API_INTEGRATION.md) | Wiring a real backend — REST pagination, sockets, optimistic sends, AI streaming |
| 11 | [`11_STATE_MANAGEMENT.md`](11_STATE_MANAGEMENT.md) | Binding `ChatController` to GetX, Riverpod, Bloc, or plain `setState` |
| 12 | [`12_FAQ_TROUBLESHOOTING.md`](12_FAQ_TROUBLESHOOTING.md) | Common questions and gotchas |

## Fastest path to "I just want to see it running"

Read [`02_GETTING_STARTED.md`](02_GETTING_STARTED.md), then open
`/example/lib/no_socket/local_preview_screen.dart` — it's a complete,
runnable, backend-free chat screen in ~60 lines.

## Fastest path to "I'm integrating this into my real app"

Read [`10_API_INTEGRATION.md`](10_API_INTEGRATION.md) and
[`11_STATE_MANAGEMENT.md`](11_STATE_MANAGEMENT.md) together, then look at
`/example/lib/with_socket/socket_chat_screen.dart` for a complete worked
example combining both.
