import '../core/enums/chat_enums.dart';
import '../core/utils/safe_json.dart';

/// A single media/file attachment on a message.
///
/// Both a remote [url] and a local [localPath] can be present at once:
/// while a message is `sending`, the UI renders from [localPath]; once the
/// host app's upload callback resolves, [url] is set and the local file
/// can be released. This is what lets the media layer avoid ever holding
/// large buffers longer than needed (see memory management requirements).
class ChatAttachment {
  final String id;
  final ChatMessageType type;
  final String? url;
  final String? localPath;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final Duration? duration; // audio/video
  final double? width; // image/video
  final double? height; // image/video
  final double uploadProgress; // 0.0–1.0

  const ChatAttachment({
    required this.id,
    required this.type,
    this.url,
    this.localPath,
    this.thumbnailUrl,
    this.fileName,
    this.fileSizeBytes,
    this.duration,
    this.width,
    this.height,
    this.uploadProgress = 1.0,
  });

  bool get isUploaded => url != null;

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    final durationMs = json['durationMs'];
    return ChatAttachment(
      id: SafeJson.string(json, 'id'),
      type: SafeJson.enumValue(json, 'type', ChatMessageType.values, ChatMessageType.document),
      url: SafeJson.stringOrNull(json, 'url'),
      localPath: SafeJson.stringOrNull(json, 'localPath'),
      thumbnailUrl: SafeJson.stringOrNull(json, 'thumbnailUrl'),
      fileName: SafeJson.stringOrNull(json, 'fileName'),
      fileSizeBytes: json['fileSizeBytes'] == null ? null : SafeJson.intValue(json, 'fileSizeBytes'),
      duration: durationMs is num ? Duration(milliseconds: durationMs.toInt()) : null,
      width: json['width'] == null ? null : SafeJson.doubleValue(json, 'width'),
      height: json['height'] == null ? null : SafeJson.doubleValue(json, 'height'),
      uploadProgress: SafeJson.doubleValue(json, 'uploadProgress', fallback: 1.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      if (url != null) 'url': url,
      if (localPath != null) 'localPath': localPath,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
      if (duration != null) 'durationMs': duration!.inMilliseconds,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      'uploadProgress': uploadProgress,
    };
  }

  ChatAttachment copyWith({
    String? id,
    ChatMessageType? type,
    String? url,
    String? localPath,
    String? thumbnailUrl,
    String? fileName,
    int? fileSizeBytes,
    Duration? duration,
    double? width,
    double? height,
    double? uploadProgress,
  }) {
    return ChatAttachment(
      id: id ?? this.id,
      type: type ?? this.type,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}
