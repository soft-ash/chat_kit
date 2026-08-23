import '../core/enums/chat_enums.dart';
import '../core/utils/safe_json.dart';

/// A lightweight reference to the message being replied to. We deliberately
/// store a preview snapshot rather than the full original [ChatMessage] —
/// the original may later be edited or deleted, and the reply should keep
/// showing what the replying user actually saw at reply-time.
class ChatReply {
  final String messageId;
  final String senderId;
  final String senderName;
  final String? preview;
  final ChatMessageType type;
  final String? thumbnailUrl;

  const ChatReply({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.type,
    this.preview,
    this.thumbnailUrl,
  });

  factory ChatReply.fromJson(Map<String, dynamic> json) {
    return ChatReply(
      messageId: SafeJson.string(json, 'messageId'),
      senderId: SafeJson.string(json, 'senderId'),
      senderName: SafeJson.string(json, 'senderName', fallback: 'Unknown'),
      type: SafeJson.enumValue(json, 'type', ChatMessageType.values, ChatMessageType.text),
      preview: SafeJson.stringOrNull(json, 'preview'),
      thumbnailUrl: SafeJson.stringOrNull(json, 'thumbnailUrl'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'type': type.name,
      if (preview != null) 'preview': preview,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    };
  }
}

/// A reference used when forwarding a message, rather than duplicating the
/// full message object. The backend decides how this is ultimately persisted.
class ForwardedMessage {
  final String originalMessageId;
  final String originalSenderId;
  final ChatMessageType type;
  final String? preview;

  const ForwardedMessage({
    required this.originalMessageId,
    required this.originalSenderId,
    required this.type,
    this.preview,
  });

  factory ForwardedMessage.fromJson(Map<String, dynamic> json) {
    return ForwardedMessage(
      originalMessageId: SafeJson.string(json, 'originalMessageId'),
      originalSenderId: SafeJson.string(json, 'originalSenderId'),
      type: SafeJson.enumValue(json, 'type', ChatMessageType.values, ChatMessageType.text),
      preview: SafeJson.stringOrNull(json, 'preview'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalMessageId': originalMessageId,
      'originalSenderId': originalSenderId,
      'type': type.name,
      if (preview != null) 'preview': preview,
    };
  }
}
