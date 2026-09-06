/// Contract for values that can be represented as a JSON object.
abstract interface class JsonSerializable() {
  Map<String, Object?> toJson();
}
