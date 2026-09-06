import 'package:odu_core/src/json/data_json_object.dart';
import 'package:odu_core/src/json/parser.dart';

/// Read-only, typed accessors for a JSON array.
extension type DataJsonList._(List<Object?> _data) {
  new(Object? data) : this._(JsonParser.parseList(data, (item) => item));

  List<Object?> get values => _data;
  int get length => _data.length;
  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;

  Object? item(int index) => _data[index];
  Object? itemOrNull(int index) => _validIndex(index) ? _data[index] : null;

  String string(int index) => JsonParser.parseString(itemOrNull(index));
  String? stringOrNull(int index) =>
      JsonParser.tryParseString(itemOrNull(index));
  int integer(int index) => JsonParser.parseInt(itemOrNull(index));
  int? integerOrNull(int index) => JsonParser.tryParseInt(itemOrNull(index));
  double decimal(int index) => JsonParser.parseDouble(itemOrNull(index));
  double? decimalOrNull(int index) =>
      JsonParser.tryParseDouble(itemOrNull(index));
  bool boolean(int index) => JsonParser.parseBool(itemOrNull(index));
  bool? booleanOrNull(int index) => JsonParser.tryParseBool(itemOrNull(index));

  DateTime dateTimeOr(int index, DateTime fallback) =>
      JsonParser.tryParseDateTime(itemOrNull(index)) ?? fallback;
  DateTime? dateTimeOrNull(int index) =>
      JsonParser.tryParseDateTime(itemOrNull(index));

  List<T> list<T>(int index, T Function(Object? item) itemParser) =>
      JsonParser.parseList(itemOrNull(index), itemParser);
  Map<String, Object?> map(int index) => JsonParser.parseMap(itemOrNull(index));
  DataJsonObject object(int index) => DataJsonObject(itemOrNull(index));

  @Deprecated('Use map(index) instead.')
  Map<String, Object?> at(int index) => map(index);

  bool _validIndex(int index) => index >= 0 && index < _data.length;
}
