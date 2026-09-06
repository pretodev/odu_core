import 'package:odu_core/src/json/parser.dart';

/// Read-only, typed accessors for a JSON object.
extension type DataJsonObject._(Map<String, Object?> _data) {
  new(Object? data) : this._(JsonParser.parseMap(data));

  Map<String, Object?> get values => _data;

  String string(String key) => JsonParser.parseString(_data[key]);
  String? stringOrNull(String key) => JsonParser.tryParseString(_data[key]);
  int integer(String key) => JsonParser.parseInt(_data[key]);
  int? integerOrNull(String key) => JsonParser.tryParseInt(_data[key]);
  double decimal(String key) => JsonParser.parseDouble(_data[key]);
  double? decimalOrNull(String key) => JsonParser.tryParseDouble(_data[key]);
  bool boolean(String key) => JsonParser.parseBool(_data[key]);
  bool? booleanOrNull(String key) => JsonParser.tryParseBool(_data[key]);

  DateTime dateTimeOr(String key, DateTime fallback) =>
      JsonParser.tryParseDateTime(_data[key]) ?? fallback;
  DateTime? dateTimeOrNull(String key) =>
      JsonParser.tryParseDateTime(_data[key]);

  List<T> list<T>(String key, T Function(Object? item) itemParser) =>
      JsonParser.parseList(_data[key], itemParser);
  List<DataJsonObject> listOfObjects(String key) =>
      JsonParser.parseList(_data[key], DataJsonObject.new);
  Map<String, Object?> map(String key) => JsonParser.parseMap(_data[key]);
  DataJsonObject object(String key) => DataJsonObject(_data[key]);
}
