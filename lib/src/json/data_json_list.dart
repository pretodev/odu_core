import 'package:odu_core/src/json/data_json_object.dart';
import 'package:odu_core/src/json/parser.dart';

/// Typed accessors for an untyped JSON array.
extension type DataJsonList._(List<JsonValue> _data)
    implements List<JsonValue> {
  new(JsonValue data) : this._(JsonParser.parseList(data, (item) => item));

  int get length => _data.length;
  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;
  JsonValue item(int index) => _data[index];
  JsonValue itemOrNull(int index) =>
      index >= 0 && index < _data.length ? _data[index] : null;
  String string(int index) => JsonParser.parseString(_data[index]);
  String? stringOrNull(int index) => JsonParser.tryParseString(_data[index]);
  int integer(int index) => JsonParser.parseInt(_data[index]);
  int? integerOrNull(int index) => JsonParser.tryParseInt(_data[index]);
  double decimal(int index) => JsonParser.parseDouble(_data[index]);
  double? decimalOrNull(int index) => JsonParser.tryParseDouble(_data[index]);
  bool boolean(int index) => JsonParser.parseBool(_data[index]);
  DateTime dateTimeOrNow(int index) =>
      JsonParser.tryParseDateTime(_data[index]) ?? DateTime.now();
  DateTime? dateTimeOrNull(int index) =>
      JsonParser.tryParseDateTime(_data[index]);
  List<T> list<T>(int index, T Function(JsonValue item) itemParser) =>
      JsonParser.parseList(_data[index], itemParser);
  Map<String, JsonValue> at(int index) => JsonParser.parseMap(_data[index]);
  DataJsonObject object(int index) => DataJsonObject(_data[index]);
}
