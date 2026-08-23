import 'package:advanced_chat_kit/advanced_chat_kit.dart';
import 'package:flutter_test/flutter_test.dart';

ChatMessage _textMessage(String id, {String senderId = 'u1', String text = 'hi'}) {
  return ChatMessage(
    id: id,
    senderId: senderId,
    type: ChatMessageType.text,
    text: text,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('ChatController — message CRUD', () {
    late ChatController controller;

    setUp(() {
      controller = ChatController(currentUserId: 'me');
    });

    tearDown(() => controller.dispose());

    test('addIncomingMessage appends and is retrievable in O(1) via messageById', () {
      controller.addIncomingMessage(_textMessage('m1'));
      controller.addIncomingMessage(_textMessage('m2'));

      expect(controller.messages, hasLength(2));
      expect(controller.messageById('m2')?.id, 'm2');
      expect(controller.messageById('missing'), isNull);
    });

    test('addIncomingMessage with a duplicate id updates in place instead of duplicating', () {
      controller.addIncomingMessage(_textMessage('m1', text: 'first'));
      controller.addIncomingMessage(_textMessage('m1', text: 'duplicate delivery'));

      expect(controller.messages, hasLength(1));
      expect(controller.messageById('m1')?.text, 'duplicate delivery');
    });

    test('updateMessageStatus only changes the targeted message', () {
      controller.addOutgoingMessage(_textMessage('m1'));
      controller.addOutgoingMessage(_textMessage('m2'));

      controller.updateMessageStatus('m1', ChatMessageStatus.read);

      expect(controller.messageById('m1')?.status, ChatMessageStatus.read);
      expect(controller.messageById('m2')?.status, ChatMessageStatus.sent);
    });

    test('editMessage updates text and stamps editedAt', () {
      controller.addOutgoingMessage(_textMessage('m1', text: 'original'));
      controller.editMessage('m1', 'edited text');

      final message = controller.messageById('m1')!;
      expect(message.text, 'edited text');
      expect(message.isEdited, isTrue);
    });

    test('deleteMessage soft-deletes by default, keeping the tombstone', () {
      controller.addOutgoingMessage(_textMessage('m1', text: 'secret'));
      controller.deleteMessage('m1');

      final message = controller.messageById('m1')!;
      expect(message.isDeleted, isTrue);
      expect(message.text, isNull);
      expect(controller.messages, hasLength(1));
    });

    test('deleteMessage with hard:true removes it from the list entirely', () {
      controller.addOutgoingMessage(_textMessage('m1'));
      controller.addOutgoingMessage(_textMessage('m2'));
      controller.deleteMessage('m1', hard: true);

      expect(controller.messages, hasLength(1));
      expect(controller.messageById('m1'), isNull);
      // Index must be rebuilt correctly after removal.
      expect(controller.messageById('m2')?.id, 'm2');
    });
  });

  group('ChatController — reactions', () {
    late ChatController controller;

    setUp(() {
      controller = ChatController(currentUserId: 'me');
      controller.addIncomingMessage(_textMessage('m1'));
    });

    tearDown(() => controller.dispose());

    test('addReaction appends and replaces a prior reaction from the same user', () {
      controller.addReaction('m1', ChatReaction(userId: 'me', emoji: '👍', reactedAt: DateTime.utc(2026, 1, 1)));
      controller.addReaction('m1', ChatReaction(userId: 'me', emoji: '❤️', reactedAt: DateTime.utc(2026, 1, 1)));

      final reactions = controller.messageById('m1')!.reactions;
      expect(reactions, hasLength(1));
      expect(reactions.first.emoji, '❤️');
    });

    test("removeReaction removes only the given user's reaction", () {
      controller.addReaction('m1', ChatReaction(userId: 'me', emoji: '👍', reactedAt: DateTime.utc(2026, 1, 1)));
      controller.addReaction('m1', ChatReaction(userId: 'other', emoji: '😂', reactedAt: DateTime.utc(2026, 1, 1)));

      controller.removeReaction('m1', 'me');

      final reactions = controller.messageById('m1')!.reactions;
      expect(reactions, hasLength(1));
      expect(reactions.first.userId, 'other');
    });
  });

  group('ChatController — AI streaming', () {
    late ChatController controller;

    setUp(() => controller = ChatController(currentUserId: 'me'));
    tearDown(() => controller.dispose());

    test('startStreamingMessage inserts with isStreaming true', () {
      controller.startStreamingMessage(_textMessage('ai1', senderId: 'assistant', text: ''));
      expect(controller.messageById('ai1')?.isStreaming, isTrue);
    });

    test('appendStreamingChunk accumulates text without duplicating the message', () {
      controller.startStreamingMessage(_textMessage('ai1', senderId: 'assistant', text: ''));
      controller.appendStreamingChunk('ai1', 'Hel');
      controller.appendStreamingChunk('ai1', 'lo');

      expect(controller.messages, hasLength(1));
      expect(controller.messageById('ai1')?.text, 'Hello');
      expect(controller.messageById('ai1')?.isStreaming, isTrue);
    });

    test('completeStreamingMessage clears isStreaming and sets status', () {
      controller.startStreamingMessage(_textMessage('ai1', senderId: 'assistant', text: 'partial'));
      controller.completeStreamingMessage('ai1');

      final message = controller.messageById('ai1')!;
      expect(message.isStreaming, isFalse);
      expect(message.status, ChatMessageStatus.sent);
    });
  });

  group('ChatController — typing indicator', () {
    test('setUserTyping populates typingUsers, clearUserTyping empties it', () {
      final controller = ChatController(currentUserId: 'me');
      addTearDown(controller.dispose);

      controller.setUserTyping(const ChatUser(id: 'u2', name: 'Ash'));
      expect(controller.currentState.typingUsers.containsKey('u2'), isTrue);
      expect(controller.currentState.isTyping, isTrue);

      controller.clearUserTyping('u2');
      expect(controller.currentState.typingUsers, isEmpty);
      expect(controller.currentState.isTyping, isFalse);
    });
  });

  group('ChatController — pagination', () {
    test('loadMore prepends older messages and stops when a short page arrives', () async {
      var callCount = 0;

      final controller = ChatController(
        currentUserId: 'me',
        pageSize: 2,
        onLoadMoreMessages: (cursor) async {
          callCount++;
          if (callCount == 1) {
            // ChatController preserves whatever order the host returns —
            // it doesn't re-sort. Returning oldest-of-the-batch first
            // here means the final list reads old_1, old_2 in that order.
            return [_textMessage('old_1'), _textMessage('old_2')];
          }
          return const []; // nothing older left
        },
      );
      addTearDown(controller.dispose);

      await controller.loadMore();
      expect(controller.messages.map((m) => m.id), ['old_1', 'old_2']);
      expect(controller.currentState.hasMoreMessages, isTrue);

      await controller.loadMore();
      expect(controller.currentState.hasMoreMessages, isFalse);
    });

    test('loadMore surfaces errors via loadError without throwing', () async {
      final controller = ChatController(
        currentUserId: 'me',
        onLoadMoreMessages: (_) async => throw Exception('network down'),
      );
      addTearDown(controller.dispose);

      await controller.loadMore();
      expect(controller.currentState.loadError, contains('network down'));
      expect(controller.currentState.isLoadingMore, isFalse);
    });
  });

  group('ChatController — stream emission', () {
    test('every mutation emits a new ChatState on the stream', () async {
      final controller = ChatController(currentUserId: 'me');
      addTearDown(controller.dispose);

      final states = <ChatState>[];
      final subscription = controller.stream.listen(states.add);

      controller.addIncomingMessage(_textMessage('m1'));
      controller.updateMessageStatus('m1', ChatMessageStatus.read);
      await Future<void>.delayed(Duration.zero);

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states.last.messages.single.status, ChatMessageStatus.read);

      await subscription.cancel();
    });
  });
}
