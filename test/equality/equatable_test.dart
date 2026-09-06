import 'package:odu_core/odu_core.dart';
import 'package:test/test.dart';

void main() {
  group('Equatable', () {
    test('compares instances by runtime type and properties', () {
      expect(const _Value(1, 'one'), const _Value(1, 'one'));
      expect(const _Value(1, 'one'), isNot(const _Value(2, 'one')));
      expect(const _Value(1, 'one'), isNot(const _OtherValue(1, 'one')));
    });

    test('produces equal hash codes for equal instances', () {
      const first = _Value(1, 'one');
      const second = _Value(1, 'one');
      final values = <_Value>{};
      values.add(first);
      values.add(second);

      expect(first.hashCode, second.hashCode);
      expect(values, hasLength(1));
    });

    test('compares nested collections structurally', () {
      const first = _CollectionValue([
        1,
        {
          'items': <Object?>[1, 2],
        },
        {1, 2},
      ]);
      const second = _CollectionValue([
        1,
        {
          'items': <Object?>[1, 2],
        },
        {2, 1},
      ]);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('keeps iterable order significant', () {
      expect(
        const _CollectionValue([1, 2]),
        isNot(const _CollectionValue([2, 1])),
      );
    });

    test('formats the runtime type and properties', () {
      expect(const _Value(1, 'one').toString(), '_Value(1, one)');
    });
  });
}

final class const _Value(final int id, final String name) extends Equatable {
  @override
  List<Object?> get props => [id, name];
}

final class const _OtherValue(final int id, final String name)
    extends Equatable {
  @override
  List<Object?> get props => [id, name];
}

final class const _CollectionValue(final List<Object?> items)
    extends Equatable {
  @override
  List<Object?> get props => [items];
}
