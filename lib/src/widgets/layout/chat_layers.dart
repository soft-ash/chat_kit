import 'package:flutter/material.dart';

/// Every extension slot [ChatView] mounts around the core chat screen,
/// matching [ChatLayerPosition] one-for-one. Each slot is a plain,
/// independent `Widget?` field — leave any of them `null` without
/// affecting the rest (see doc section 30, "custom chat layers must be
/// optional").
///
/// ```text
/// ┌──────────────────────────────┐
/// │ header                       │  <- your own AppBar-like widget
/// ├──────────────────────────────┤
/// │ belowHeader                  │
/// ├──────────────────────────────┤
/// │ aboveMessages                 │  <- banner, date/event strip, promo
/// │                                │
/// │         Message List          │
/// │                                │
/// │ belowMessages                 │
/// ├──────────────────────────────┤
/// │ aboveInput                    │  <- custom action panel, e.g.
/// ├──────────────────────────────┤
/// │           Input Bar           │
/// │ belowInput                    │
/// └──────────────────────────────┘
///        overlay (floats above everything, e.g. a scroll-to-bottom FAB)
/// ```
class ChatLayers {
  final Widget? header;
  final Widget? belowHeader;
  final Widget? aboveMessages;
  final Widget? belowMessages;
  final Widget? aboveInput;
  final Widget? belowInput;
  final Widget? overlay;

  const ChatLayers({
    this.header,
    this.belowHeader,
    this.aboveMessages,
    this.belowMessages,
    this.aboveInput,
    this.belowInput,
    this.overlay,
  });
}
