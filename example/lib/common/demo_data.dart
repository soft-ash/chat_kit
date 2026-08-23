import 'package:advanced_chat_kit/advanced_chat_kit.dart';

/// Everything the examples share, kept in one place so each example file
/// only has to focus on the thing it's actually demonstrating (state
/// binding, socket wiring, ...) rather than re-declaring users and a
/// theme every time.
class DemoData {
  static const currentUserId = 'user_me';

  static const me = ChatUser(id: currentUserId, name: 'You');

  static const otherUser = ChatUser(
    id: 'user_ash',
    name: 'Ash',
    isOnline: true,
  );

  static ChatUser? resolveUser(String id) {
    if (id == currentUserId) return me;
    if (id == otherUser.id) return otherUser;
    return null;
  }

  static ChatTheme theme() => ChatTheme.light();

  /// A couple of seed messages so a freshly opened example screen isn't
  /// empty — purely cosmetic, not required by the package.
  static List<ChatMessage> seedMessages() {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: 'seed_1',
        senderId: otherUser.id,
        type: ChatMessageType.text,
        text: 'Hey! This is a local preview — no backend involved.',
        createdAt: now.subtract(const Duration(minutes: 3)),
        status: ChatMessageStatus.read,
      ),
      ChatMessage(
        id: 'seed_2',
        senderId: currentUserId,
        type: ChatMessageType.text,
        text: 'Nice, so I can just try the UI without setting up a socket first.',
        createdAt: now.subtract(const Duration(minutes: 2)),
        status: ChatMessageStatus.read,
      ),
    ];
  }
}
