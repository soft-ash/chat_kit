import '../core/utils/safe_json.dart';

/// A single emoji reaction from a single user on a message.
/// Multiple [ChatReaction]s accumulate on [ChatMessage.reactions].
class ChatReaction {
  final String userId;
  final String emoji;
  final DateTime reactedAt;

  const ChatReaction({
    required this.userId,
    required this.emoji,
    required this.reactedAt,
  });

  factory ChatReaction.fromJson(Map<String, dynamic> json) {
    return ChatReaction(
      userId: SafeJson.string(json, 'userId'),
      emoji: SafeJson.string(json, 'emoji', fallback: '👍'),
      reactedAt: SafeJson.dateTime(json, 'reactedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'emoji': emoji,
      'reactedAt': reactedAt.toIso8601String(),
    };
  }
}
