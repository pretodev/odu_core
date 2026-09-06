/// Safely converts values received from untyped JSON payloads.
///
/// `dynamic` is intentionally restricted to this boundary. Parsed values are
/// exposed by the rest of the module as `Object?`.
abstract final class const JsonParser._() {
  static String parseString(dynamic value) => tryParseString(value) ?? '';

  static String? tryParseString(dynamic value) =>
      value is String ? value : (value as Object?)?.toString();

  static int parseInt(dynamic value) => tryParseInt(value) ?? 0;

  static int? tryParseInt(dynamic value) => switch (value) {
    int() => value,
    double() when value.isFinite && value == value.truncateToDouble() =>
      value.toInt(),
    _ => int.tryParse(parseString(value).trim()),
  };

  static double parseDouble(dynamic value) => tryParseDouble(value) ?? 0.0;

  static double? tryParseDouble(dynamic value) {
    final parsed = switch (value) {
      num() => value.toDouble(),
      _ => double.tryParse(parseString(value).trim()),
    };
    return parsed?.isFinite ?? false ? parsed : null;
  }

  static bool parseBool(dynamic value) => tryParseBool(value) ?? false;

  static bool? tryParseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    return switch ((value as Object?)?.toString().trim().toLowerCase()) {
      'true' || '1' => true,
      'false' || '0' => false,
      _ => null,
    };
  }

  static List<T> parseList<T>(
    dynamic value,
    T Function(Object? item) itemParser,
  ) => value is List
      ? List<T>.unmodifiable(value.cast<Object?>().map<T>(itemParser))
      : const [];

  static Map<String, Object?> parseMap(dynamic value) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      return const {};
    }
    return Map<String, Object?>.unmodifiable(
      value.map<String, Object?>((key, item) => MapEntry(key as String, item)),
    );
  }

  static DateTime? tryParseDateTime(dynamic value) =>
      value is DateTime ? value : DateTime.tryParse(parseString(value));
}
