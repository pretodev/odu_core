/// A value received from an untyped JSON payload.
typedef JsonValue = dynamic;

/// Safely converts untyped JSON values into application-friendly types.
abstract final class const JsonParser._() {
  static String parseString(JsonValue value) =>
      value is String ? value : (value as Object?)?.toString() ?? '';

  static String? tryParseString(JsonValue value) =>
      value is String ? value : (value as Object?)?.toString();

  static int parseInt(JsonValue value) => tryParseInt(value) ?? 0;

  static double parseDouble(JsonValue value) => tryParseDouble(value) ?? 0.0;

  static int? tryParseInt(JsonValue value) => switch (value) {
    int() => value,
    double() when value.isFinite && value == value.truncateToDouble() =>
      value.toInt(),
    _ => int.tryParse(parseString(value).trim()),
  };

  static double? tryParseDouble(JsonValue value) => switch (value) {
    num() => value.toDouble(),
    _ => double.tryParse(parseString(value).trim()),
  };

  static bool parseBool(JsonValue value) {
    if (value is bool) {
      return value;
    }
    final normalized = (value as Object?)?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  static List<T> parseList<T>(
    JsonValue value,
    T Function(JsonValue item) itemParser,
  ) => value is List<JsonValue> ? value.map<T>(itemParser).toList() : <T>[];

  static Map<String, JsonValue> parseMap(JsonValue value) =>
      value is Map<String, JsonValue> ? value : <String, JsonValue>{};

  static DateTime? tryParseDateTime(JsonValue value) =>
      value is DateTime ? value : DateTime.tryParse(parseString(value));
}
