import 'package:advanced_chat_kit/advanced_chat_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ChatMessage _textMessage({
  String id = 'm1',
  String senderId = 'u1',
  String text = 'hello',
  bool isDeleted = false,
  List<ChatReaction> reactions = const [],
}) {
  return ChatMessage(
    id: id,
    senderId: senderId,
    type: ChatMessageType.text,
    text: text,
    createdAt: DateTime.utc(2026, 1, 1, 12, 30),
    isDeleted: isDeleted,
    reactions: reactions,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  final theme = ChatTheme.light();

  testWidgets('renders message text', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MessageBubble(
          message: _textMessage(text: 'hello there'),
          isMe: true,
          theme: theme,
        ),
      ),
    );

    expect(find.text('hello there'), findsOneWidget);
  });

  testWidgets('shows delivery status icon only for isMe bubbles', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MessageBubble(
          message: _textMessage(), // default status: ChatMessageStatus.sent
          isMe: true,
          theme: theme,
        ),
      ),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('deleted messages render the tombstone, not the original text', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MessageBubble(
          message: _textMessage(text: 'this should not show', isDeleted: true),
          isMe: false,
          theme: theme,
        ),
      ),
    );

    expect(find.text('this should not show'), findsNothing);
    expect(find.text('This message was deleted'), findsOneWidget);
  });

  testWidgets('renders grouped emoji+count reaction chips', (tester) async {
    final message = _textMessage(
      reactions: [
        ChatReaction(userId: 'u2', emoji: '❤️', reactedAt: DateTime.utc(2026, 1, 1)),
        ChatReaction(userId: 'u3', emoji: '❤️', reactedAt: DateTime.utc(2026, 1, 1)),
        ChatReaction(userId: 'u4', emoji: '👍', reactedAt: DateTime.utc(2026, 1, 1)),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        MessageBubble(
          message: message,
          isMe: false,
          theme: theme,
          currentUserId: 'u1',
        ),
      ),
    );

    expect(find.text('❤️'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // grouped count for ❤️
    expect(find.text('👍'), findsOneWidget);
  });

  testWidgets('tapping the bubble fires onTap with the message', (tester) async {
    ChatMessage? tapped;

    await tester.pumpWidget(
      _wrap(
        MessageBubble(
          message: _textMessage(id: 'tap_me'),
          isMe: true,
          theme: theme,
          onTap: (message) => tapped = message,
        ),
      ),
    );

    await tester.tap(find.text('hello'));
    expect(tapped?.id, 'tap_me');
  });
}
