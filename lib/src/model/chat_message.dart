import '../core/constants/chat_constants.dart';
import '../core/enums/chat_enums.dart';
import '../core/utils/safe_json.dart';
import 'chat_attachment.dart';
import 'chat_link_preview.dart';
import 'chat_reaction.dart';
import 'chat_reply.dart';

/// The single message model used across text, media, system, and custom
/// (application-defined) messages.
///
/// For custom widgets (date invitation cards, product cards, payment
/// cards, polls, etc.) set [type] to [ChatMessageType.custom] and put the
/// application-specific payload in [metadata]. The package never
/// interprets [metadata] itself — it hands it to the host app's
/// `customMessageBuilder`. This keeps remote data declarative rather than
/// executable (see SDK security architecture, section 16).
class ChatMessage {
  final String id;
  final String senderId;
  final String? conversationId;

  final String? text;
  final ChatMessageType type;

  /// Only meaningful when [type] is [ChatMessageType.custom]. Identifies
  /// which registered widget builder should render this message, e.g.
  /// `'date_invitation'`, `'product'`, `'payment'`.
  final String? customType;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? editedAt;

  final ChatMessageStatus status;

  final List<ChatAttachment> attachments;
  final ChatReply? replyTo;
  final ForwardedMessage? forwardedFrom;
  final List<ChatReaction> reactions;
  final ChatLinkPreview? linkPreview;

  /// Freeform, application-owned payload. Used both for [customType]
  /// message data and for any extra fields the host app wants to attach
  /// to a normal text/media message (e.g. AI response token usage).
  final Map<String, dynamic>? metadata;

  final bool isDeleted;

  /// `true` while an AI response is still arriving token-by-token.
  /// [ChatController.appendStreamingChunk] flips [text] incrementally
  /// while this stays `true`; [ChatController.completeStreamingMessage]
  /// sets it back to `false`. [MessageBubble] shows a blinking
  /// [StreamingCursor] at the end of the text while this is `true` (see
  /// doc section 23, AI streaming: "the UI should update efficiently
  /// without rebuilding the entire conversation" — only this one message
  /// re-renders per chunk, via the same O(1) indexed update every other
  /// mutation uses).
  final bool isStreaming;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.type,
    required this.createdAt,
    this.conversationId,
    this.text,
    this.customType,
    this.updatedAt,
    this.editedAt,
    this.status = ChatMessageStatus.sent,
    this.attachments = const [],
    this.replyTo,
    this.forwardedFrom,
    this.reactions = const [],
    this.linkPreview,
    this.metadata,
    this.isDeleted = false,
    this.isStreaming = false,
  });

  bool get isEdited => editedAt != null;
  bool get hasAttachments => attachments.isNotEmpty;
  bool get isCustom => type == ChatMessageType.custom;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final replyJson = SafeJson.mapOrNull(json, 'replyTo');
    final forwardedJson = SafeJson.mapOrNull(json, 'forwardedFrom');
    final linkPreviewJson = SafeJson.mapOrNull(json, 'linkPreview');
    final metadataJson = SafeJson.mapOrNull(json, 'metadata');

    return ChatMessage(
      id: SafeJson.string(json, 'id'),
      senderId: SafeJson.string(json, 'senderId'),
      conversationId: SafeJson.stringOrNull(json, 'conversationId'),
      text: SafeJson.stringOrNull(json, 'text'),
      type: SafeJson.enumValue(json, 'type', ChatMessageType.values, ChatMessageType.text),
      customType: SafeJson.stringOrNull(json, 'customType') ??
          (metadataJson != null ? SafeJson.stringOrNull(metadataJson, ChatMetadataKeys.customType) : null),
      createdAt: SafeJson.dateTime(json, 'createdAt'),
      updatedAt: json['updatedAt'] == null ? null : SafeJson.dateTime(json, 'updatedAt'),
      editedAt: json['editedAt'] == null ? null : SafeJson.dateTime(json, 'editedAt'),
      status: SafeJson.enumValue(json, 'status', ChatMessageStatus.values, ChatMessageStatus.sent),
      attachments: SafeJson.listOfMaps(json, 'attachments').map(ChatAttachment.fromJson).toList(),
      replyTo: replyJson == null ? null : ChatReply.fromJson(replyJson),
      forwardedFrom: forwardedJson == null ? null : ForwardedMessage.fromJson(forwardedJson),
      reactions: SafeJson.listOfMaps(json, 'reactions').map(ChatReaction.fromJson).toList(),
      linkPreview: linkPreviewJson == null ? null : ChatLinkPreview.fromJson(linkPreviewJson),
      metadata: metadataJson,
      isDeleted: SafeJson.boolValue(json, 'isDeleted'),
      isStreaming: SafeJson.boolValue(json, 'isStreaming'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      if (conversationId != null) 'conversationId': conversationId,
      if (text != null) 'text': text,
      'type': type.name,
      if (customType != null) 'customType': customType,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (editedAt != null) 'editedAt': editedAt!.toIso8601String(),
      'status': status.name,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      if (replyTo != null) 'replyTo': replyTo!.toJson(),
      if (forwardedFrom != null) 'forwardedFrom': forwardedFrom!.toJson(),
      'reactions': reactions.map((r) => r.toJson()).toList(),
      if (linkPreview != null) 'linkPreview': linkPreview!.toJson(),
      if (metadata != null) 'metadata': metadata,
      'isDeleted': isDeleted,
      if (isStreaming) 'isStreaming': isStreaming,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? conversationId,
    String? text,
    ChatMessageType? type,
    String? customType,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? editedAt,
    ChatMessageStatus? status,
    List<ChatAttachment>? attachments,
    ChatReply? replyTo,
    ForwardedMessage? forwardedFrom,
    List<ChatReaction>? reactions,
    ChatLinkPreview? linkPreview,
    Map<String, dynamic>? metadata,
    bool? isDeleted,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      conversationId: conversationId ?? this.conversationId,
      text: text ?? this.text,
      type: type ?? this.type,
      customType: customType ?? this.customType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      editedAt: editedAt ?? this.editedAt,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      replyTo: replyTo ?? this.replyTo,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
      reactions: reactions ?? this.reactions,
      linkPreview: linkPreview ?? this.linkPreview,
      metadata: metadata ?? this.metadata,
      isDeleted: isDeleted ?? this.isDeleted,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  bool operator ==(Object other) => other is ChatMessage && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
