import 'package:flutter/material.dart';

import '../../core/enums/chat_enums.dart';
import '../../model/chat_message.dart';

/// Signature for a registered custom-message renderer. The package hands
/// you the raw [ChatMessage] (read `message.metadata` for your payload)
/// and whether the current user sent it — you decide what to draw.
typedef ChatCustomWidgetBuilder = Widget Function(BuildContext context, ChatMessage message, bool isMe);

/// Central place to register application-specific message widgets —
/// date invitation cards, product cards, payment cards, polls, bookings,
/// games, anything — without ever touching the package's core rendering
/// path (see SDK doc sections 6 and 11).
///
/// The package never inspects or interprets what a `customType` string
/// means; it only uses it as a lookup key. Remote data stays declarative
/// (`type: custom, customType: 'date_invitation'`) rather than
/// executable — see doc section 16, "Custom Widget Security".
///
/// Usage:
/// ```dart
/// final registry = ChatWidgetRegistry()
///   ..register('date_invitation', (context, message, isMe) {
///     return DateInvitationCard(
///       message: message,
///       theme: myTheme,
///       onAccept: () => myController.respondToInvite(message.id, true),
///       onCancel: () => myController.respondToInvite(message.id, false),
///     );
///   })
///   ..register('product', (context, message, isMe) => ProductCard(message));
///
/// MessageList(
///   ...
///   customMessageBuilder: registry.asMessageBuilder(),
/// )
/// ```
class ChatWidgetRegistry {
  final Map<String, ChatCustomWidgetBuilder> _builders = {};

  ChatWidgetRegistry({Map<String, ChatCustomWidgetBuilder>? widgets}) {
    if (widgets != null) _builders.addAll(widgets);
  }

  /// Registers or replaces the builder for [customType].
  void register(String customType, ChatCustomWidgetBuilder builder) {
    _builders[customType] = builder;
  }

  void unregister(String customType) => _builders.remove(customType);

  bool isRegistered(String customType) => _builders.containsKey(customType);

  List<String> get registeredTypes => List.unmodifiable(_builders.keys);

  /// Adapts this registry into the `ChatMessageBuilder` signature expected
  /// by [MessageBubble]/[MessageList]'s `customMessageBuilder`. Returning
  /// `null` from the underlying builder function means "fall back to the
  /// package's default rendering" — that happens automatically here for
  /// any non-custom message, or a `customType` with no registered builder,
  /// so an unrecognized type degrades gracefully instead of crashing the
  /// chat screen (see doc section 24, error isolation).
  Widget? Function(BuildContext context, ChatMessage message, bool isMe) asMessageBuilder() {
    return (context, message, isMe) {
      if (message.type != ChatMessageType.custom) return null;
      final type = message.customType;
      if (type == null) return null;
      final builder = _builders[type];
      if (builder == null) return null;
      return builder(context, message, isMe);
    };
  }
}
