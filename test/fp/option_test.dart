import 'package:odu_core/odu_core.dart';
import 'package:test/test.dart';

void main() {
  group('Option', () {
    test('reports whether it contains a value', () {
      expect(const Some(1).isSome, isTrue);
      expect(const Some(1).isNone, isFalse);
      expect(const None<int>().isSome, isFalse);
      expect(const None<int>().isNone, isTrue);
    });

    test('unwrap returns Some value and throws for None', () {
      expect(const Some(1).unwrap(), 1);
      expect(const None<int>().unwrap, throwsStateError);
    });

    test('fallback methods are lazy and only apply to None', () {
      var calls = 0;
      int fallback() {
        calls++;
        return 2;
      }

      expect(const Some(1).unwrapOr(2), 1);
      expect(const None<int>().unwrapOr(2), 2);
      expect(const Some(1).unwrapOrElse(fallback), 1);
      expect(calls, isZero);
      expect(const None<int>().unwrapOrElse(fallback), 2);
      expect(calls, 1);
    });

    test('map and flatMap transform only Some', () {
      expect(const Some(2).map((value) => value * 2).unwrap(), 4);
      expect(const None<int>().map((value) => value * 2).isNone, isTrue);
      expect(const Some(2).flatMap((value) => Some('$value')).unwrap(), '2');
      expect(const None<int>().flatMap(Some.new).isNone, isTrue);
    });

    test('converts from and to nullable values', () {
      expect(Option.fromNullable(1).unwrap(), 1);
      expect(Option.fromNullable<int>(null).isNone, isTrue);
      expect(const Some(1).toNullable(), 1);
      expect(const None<int>().toNullable(), isNull);
    });

    test('has descriptive string representations', () {
      expect(const Some<int>(1).toString(), 'Option<int>.some(1)');
      expect(const None<int>().toString(), 'Option<int>.none()');
    });
  });
}
