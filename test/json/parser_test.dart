import 'package:odu_core/odu_core.dart';
import 'package:test/test.dart';

void main() {
  group('JsonParser', () {
    test('parses strings and nullable strings', () {
      expect(JsonParser.parseString('value'), 'value');
      expect(JsonParser.parseString(42), '42');
      expect(JsonParser.parseString(null), isEmpty);
      expect(JsonParser.tryParseString(null), isNull);
    });

    test('parses integer representations safely', () {
      expect(JsonParser.parseInt(2), 2);
      expect(JsonParser.parseInt(2.0), 2);
      expect(JsonParser.parseInt(' 2 '), 2);
      expect(JsonParser.parseInt(2.5), isZero);
      expect(JsonParser.tryParseInt('invalid'), isNull);
    });

    test('parses decimal representations safely', () {
      expect(JsonParser.parseDouble(2), 2.0);
      expect(JsonParser.parseDouble(2.5), 2.5);
      expect(JsonParser.parseDouble(' 2.5 '), 2.5);
      expect(JsonParser.parseDouble('invalid'), 0.0);
      expect(JsonParser.tryParseDouble(null), isNull);
      expect(JsonParser.tryParseDouble(double.nan), isNull);
      expect(JsonParser.tryParseDouble(double.infinity), isNull);
    });

    test('parses supported boolean representations', () {
      expect(JsonParser.parseBool(true), isTrue);
      expect(JsonParser.parseBool(' TRUE '), isTrue);
      expect(JsonParser.parseBool(1), isTrue);
      expect(JsonParser.parseBool(false), isFalse);
      expect(JsonParser.parseBool('false'), isFalse);
      expect(JsonParser.parseBool('invalid'), isFalse);
      expect(JsonParser.tryParseBool('invalid'), isNull);
      expect(JsonParser.tryParseBool(0), isFalse);
    });

    test('parses lists, maps, and dates with safe defaults', () {
      expect(JsonParser.parseList([1, 2], JsonParser.parseString), ['1', '2']);
      expect(
        JsonParser.parseList<int>('invalid', JsonParser.parseInt),
        isEmpty,
      );
      expect(JsonParser.parseMap({'id': 1}), {'id': 1});
      expect(JsonParser.parseMap(<Object?, Object?>{'id': 1}), {'id': 1});
      expect(JsonParser.parseMap(<Object?, Object?>{1: 'id'}), isEmpty);
      expect(JsonParser.parseMap('invalid'), isEmpty);
      final date = DateTime.utc(2025, 1, 2);
      expect(JsonParser.tryParseDateTime(date), same(date));
      expect(JsonParser.tryParseDateTime('2025-01-02'), DateTime(2025, 1, 2));
      expect(JsonParser.tryParseDateTime('invalid'), isNull);
    });
  });

  group('DataJsonObject', () {
    test('reads typed fields and nested structures', () {
      final data = DataJsonObject({
        'string': 1,
        'integer': '2',
        'decimal': 2,
        'boolean': 'true',
        'date': '2025-01-02T03:04:05.000Z',
        'list': ['1', 2],
        'map': {'id': 3},
        'objects': [
          {'id': 1},
          {'id': 2},
        ],
      });

      expect(data.string('string'), '1');
      expect(data.integer('integer'), 2);
      expect(data.decimal('decimal'), 2.0);
      expect(data.boolean('boolean'), isTrue);
      expect(data.booleanOrNull('missing'), isNull);
      expect(data.dateTimeOrNull('date'), DateTime.utc(2025, 1, 2, 3, 4, 5));
      expect(data.list('list', JsonParser.parseInt), [1, 2]);
      expect(data.map('map'), {'id': 3});
      expect(data.object('map').integer('id'), 3);
      expect(data.listOfObjects('objects').map((item) => item.integer('id')), [
        1,
        2,
      ]);
    });

    test('returns defaults and nullable values for absent fields', () {
      final data = DataJsonObject(null);
      final fallback = DateTime.utc(2020);

      expect(data.string('missing'), isEmpty);
      expect(data.stringOrNull('missing'), isNull);
      expect(data.integer('missing'), isZero);
      expect(data.integerOrNull('missing'), isNull);
      expect(data.decimal('missing'), 0.0);
      expect(data.decimalOrNull('missing'), isNull);
      expect(data.boolean('missing'), isFalse);
      expect(data.dateTimeOrNull('missing'), isNull);
      expect(data.dateTimeOr('missing', fallback), same(fallback));
      expect(data.list<Object?>('missing', (item) => item), isEmpty);
      expect(data.map('missing'), isEmpty);
    });
  });

  group('DataJsonList', () {
    test('reads typed items and handles optional indexes', () {
      final data = DataJsonList([
        '1',
        2,
        'true',
        '2025-01-02',
        [1, '2'],
        {'id': 3},
      ]);

      expect(data.length, 6);
      expect(data.isEmpty, isFalse);
      expect(data.isNotEmpty, isTrue);
      expect(data.item(0), '1');
      expect(data.itemOrNull(-1), isNull);
      expect(data.itemOrNull(6), isNull);
      expect(data.string(1), '2');
      expect(data.integer(0), 1);
      expect(data.decimal(1), 2.0);
      expect(data.boolean(2), isTrue);
      expect(data.dateTimeOrNull(3), DateTime(2025, 1, 2));
      expect(data.list(4, JsonParser.parseInt), [1, 2]);
      expect(data.map(5), {'id': 3});
      expect(data.object(5).integer('id'), 3);
      expect(data.string(99), isEmpty);
      expect(data.integerOrNull(99), isNull);
      expect(data.booleanOrNull(99), isNull);
      expect(data.map(99), isEmpty);
    });

    test('uses an empty list for invalid input', () {
      final data = DataJsonList('invalid');

      expect(data.isEmpty, isTrue);
      expect(data.itemOrNull(0), isNull);
    });

    test('does not expose mutable collections', () {
      final sourceList = <Object?>[1];
      final list = DataJsonList(sourceList);
      sourceList.add(2);

      expect(list.values, [1]);
      expect(() => list.values.add(2), throwsUnsupportedError);

      final sourceMap = <String, Object?>{'id': 1};
      final object = DataJsonObject(sourceMap);
      sourceMap['id'] = 2;

      expect(object.integer('id'), 1);
      expect(() => object.values['id'] = 2, throwsUnsupportedError);
    });
  });

  test('parseList propagates item parser failures', () {
    expect(
      () => JsonParser.parseList<int>(['invalid'], JsonParser.parseInt).single,
      returnsNormally,
    );
    expect(
      () => JsonParser.parseList<int>([1], (_) => throw StateError('failed')),
      throwsStateError,
    );
  });

  test('JsonSerializable defines a typed JSON object contract', () {
    const serializable = _Serializable(1);

    expect(serializable.toJson(), {'id': 1});
  });
}

final class const _Serializable(final int id) implements JsonSerializable {
  @override
  Map<String, Object?> toJson() => {'id': id};
}
