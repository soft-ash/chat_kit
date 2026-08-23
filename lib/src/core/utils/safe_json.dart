/// Defensive JSON readers used by every `fromJson` factory in the package.
///
/// Rationale (see SDK security architecture): incoming socket/API payloads
/// are untrusted. We never let a malformed or missing field throw during
/// parsing and crash the chat screen — we fall back to safe defaults and
/// let the UI render *something* instead of nothing.
abstract final class SafeJson {
  static String string(Map<String, dynamic> json, String key, {String fallback = ''}) {
    final value = json[key];
    if (value is String) return value;
    return fallback;
  }

  static String? stringOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  static int intValue(Map<String, dynamic> json, String key, {int fallback = 0}) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double doubleValue(Map<String, dynamic> json, String key, {double fallback = 0}) {
    final value = json[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool boolValue(Map<String, dynamic> json, String key, {bool fallback = false}) {
    final value = json[key];
    if (value is bool) return value;
    return fallback;
  }

  static DateTime dateTime(Map<String, dynamic> json, String key, {DateTime? fallback}) {
    final value = json[key];
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is int) {
      // Assume milliseconds since epoch.
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return fallback ?? DateTime.now();
  }

  static Map<String, dynamic>? mapOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<Map<String, dynamic>> listOfMaps(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) return const [];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Parses an enum by name, matching case-insensitively, falling back
  /// safely instead of throwing when the server sends an unknown value
  /// (e.g. a newer client introduced a message type this build doesn't know).
  static T enumValue<T extends Enum>(
    Map<String, dynamic> json,
    String key,
    List<T> values,
    T fallback,
  ) {
    final raw = json[key];
    if (raw is! String) return fallback;
    for (final v in values) {
      if (v.name.toLowerCase() == raw.toLowerCase()) return v;
    }
    return fallback;
  }
}
