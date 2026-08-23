import 'package:advanced_chat_kit/advanced_chat_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatMessage.fromJson / toJson', () {
    test('round-trips a plain text message', () {
      final original = ChatMessage(
        id: 'm1',
        senderId: 'u1',
        type: ChatMessageType.text,
        text: 'hello world',
        createdAt: DateTime.utc(2026, 1, 1, 12),
        status: ChatMessageStatus.delivered,
      );

      final restored = ChatMessage.fromJson(original.toJson());

      expect(restored.id, 'm1');
      expect(restored.senderId, 'u1');
      expect(restored.text, 'hello world');
      expect(restored.type, ChatMessageType.text);
      expect(restored.status, ChatMessageStatus.delivered);
      expect(restored.createdAt, original.createdAt);
    });

    test('round-trips reply, reactions, and attachments', () {
      final original = ChatMessage(
        id: 'm2',
        senderId: 'u2',
        type: ChatMessageType.image,
        createdAt: DateTime.utc(2026, 1, 1),
        replyTo: const ChatReply(
          messageId: 'm1',
          senderId: 'u1',
          senderName: 'Ash',
          type: ChatMessageType.text,
          preview: 'hello world',
        ),
        reactions: [
          ChatReaction(userId: 'u3', emoji: '❤️', reactedAt: DateTime.utc(2026, 1, 1)),
        ],
        attachments: [
          ChatAttachment(id: 'a1', type: ChatMessageType.image, url: 'https://example.com/a.jpg'),
        ],
      );

      final restored = ChatMessage.fromJson(original.toJson());

      expect(restored.replyTo?.messageId, 'm1');
      expect(restored.replyTo?.senderName, 'Ash');
      expect(restored.reactions, hasLength(1));
      expect(restored.reactions.first.emoji, '❤️');
      expect(restored.attachments, hasLength(1));
      expect(restored.attachments.first.url, 'https://example.com/a.jpg');
    });

    test('parses a custom message and its declared customType', () {
      final json = {
        'id': 'm3',
        'senderId': 'u1',
        'type': 'custom',
        'customType': 'date_invitation',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'metadata': {'location': 'Amber & Oak Cafe'},
      };

      final message = ChatMessage.fromJson(json);

      expect(message.isCustom, isTrue);
      expect(message.customType, 'date_invitation');
      expect(message.metadata?['location'], 'Amber & Oak Cafe');
    });
  });

  group('ChatMessage.fromJson defensive parsing (SafeJson)', () {
    test('never throws on a mostly-empty/malformed payload', () {
      expect(() => ChatMessage.fromJson(const {}), returnsNormally);
    });

    test('falls back to text type for an unknown/garbage type string', () {
      final message = ChatMessage.fromJson({
        'id': 'm4',
        'senderId': 'u1',
        'type': 'totally_not_a_real_type',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      });

      expect(message.type, ChatMessageType.text);
    });

    test('falls back to sent status for a garbage status string', () {
      final message = ChatMessage.fromJson({
        'id': 'm5',
        'senderId': 'u1',
        'type': 'text',
        'status': 'nonsense',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      });

      expect(message.status, ChatMessageStatus.sent);
    });

    test('tolerates non-string ids/names inside nested maps without crashing', () {
      final json = {
        'id': 12345, // wrong type on purpose
        'senderId': 'u1',
        'type': 'text',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      };

      final message = ChatMessage.fromJson(json);
      // SafeJson.string falls back to '' rather than throwing.
      expect(message.id, '');
    });
  });

  group('ChatMessage.copyWith', () {
    test('only overrides provided fields', () {
      final original = ChatMessage(
        id: 'm1',
        senderId: 'u1',
        type: ChatMessageType.text,
        text: 'original',
        createdAt: DateTime.utc(2026, 1, 1),
        status: ChatMessageStatus.sending,
      );

      final updated = original.copyWith(status: ChatMessageStatus.sent);

      expect(updated.text, 'original');
      expect(updated.status, ChatMessageStatus.sent);
      expect(updated.id, original.id);
    });
  });
}
