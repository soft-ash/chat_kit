import '../core/utils/safe_json.dart';

/// A participant in a conversation. Kept intentionally minimal — the host
/// app's real user model can carry anything extra it needs and map into
/// this at the edges.
class ChatUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  const ChatUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: SafeJson.string(json, 'id'),
      name: SafeJson.string(json, 'name', fallback: 'Unknown'),
      avatarUrl: SafeJson.stringOrNull(json, 'avatarUrl'),
      isOnline: SafeJson.boolValue(json, 'isOnline'),
      lastSeen: json['lastSeen'] == null ? null : SafeJson.dateTime(json, 'lastSeen'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
    };
  }

  ChatUser copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  bool operator ==(Object other) => other is ChatUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
