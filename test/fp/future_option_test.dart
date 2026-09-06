import 'dart:async';

import 'package:odu_core/odu_core.dart';
import 'package:test/test.dart';

void main() {
  Future<Option<int>> some([int value = 2]) async => Some(value);
  Future<Option<int>> none() async => const None();

  group('FutureOption', () {
    test('maps and flatMaps synchronous and asynchronous transforms', () async {
      expect(await some().map((value) => value * 2).unwrap(), 4);
      expect(await none().map((value) => value * 2).isNone(), isTrue);
      expect(await some().mapAsync((value) async => value * 3).unwrap(), 6);
      expect(
        await none().mapAsync((value) async => value * 3).isNone(),
        isTrue,
      );
      expect(await some().flatMap((value) => Some('$value')).unwrap(), '2');
      expect(await none().flatMap(Some.new).isNone(), isTrue);
      expect(
        await some().flatMapAsync((value) async => Some('$value')).unwrap(),
        '2',
      );
      expect(
        await none().flatMapAsync((value) async => Some('$value')).isNone(),
        isTrue,
      );
    });

    test('unwrap and fallback methods handle both branches lazily', () async {
      var calls = 0;
      int fallback() {
        calls++;
        return 3;
      }

      expect(await some().unwrap(), 2);
      await expectLater(none().unwrap(), throwsStateError);
      expect(await some().unwrapOr(3), 2);
      expect(await none().unwrapOr(3), 3);
      expect(await some().unwrapOrElse(fallback), 2);
      expect(await some().unwrapOrElseAsync(() async => fallback()), 2);
      expect(calls, isZero);
      expect(await none().unwrapOrElse(fallback), 3);
      expect(await none().unwrapOrElseAsync(() async => fallback()), 3);
      expect(calls, 2);
    });

    test('inspects and filters only present values', () async {
      var inspected = 0;
      expect(await some().inspect((value) => inspected = value).unwrap(), 2);
      expect(
        await none().inspect((value) => inspected = value).isNone(),
        isTrue,
      );
      expect(inspected, 2);
      expect(await some().filter((value) => value.isEven).isSome(), isTrue);
      expect(await some().filter((value) => value.isOdd).isNone(), isTrue);
      expect(await none().filter((_) => true).isNone(), isTrue);
      expect(
        await some().filterAsync((value) async => value.isEven).isSome(),
        isTrue,
      );
      expect(
        await some().filterAsync((value) async => value.isOdd).isNone(),
        isTrue,
      );
    });

    test('exposes state and nullable conversion', () async {
      expect(await some().isSome(), isTrue);
      expect(await some().isNone(), isFalse);
      expect(await none().isSome(), isFalse);
      expect(await some().toNullable(), 2);
      expect(await none().toNullable(), isNull);
    });

    test('returns configured or default None on timeout', () async {
      final pending = Completer<Option<int>>().future;

      expect(await pending.withTimeout(Duration.zero).isNone(), isTrue);
      expect(
        await pending
            .withTimeout(Duration.zero, onTimeout: () => const Some(9))
            .unwrap(),
        9,
      );
    });
  });

  group('FutureOptionFactory', () {
    test('creates Some, None, and nullable options', () async {
      expect(await FutureOptionFactory.some(1).unwrap(), 1);
      expect(await FutureOptionFactory.none<int>().isNone(), isTrue);
      expect(await FutureOptionFactory.fromNullable(1).unwrap(), 1);
      expect(
        await FutureOptionFactory.fromNullable<int>(null).isNone(),
        isTrue,
      );
    });
  });

  group('FutureOptionList', () {
    test('waitAll preserves every option and order', () async {
      final values = await FutureOptionList.waitAll([some(1), none(), some()]);

      expect(values[0].unwrap(), 1);
      expect(values[1].isNone, isTrue);
      expect(values[2].unwrap(), 2);
    });

    test(
      'waitAllOrNone requires all values and supports empty input',
      () async {
        expect(
          await FutureOptionList.waitAllOrNone([some(1), some()]).unwrap(),
          [1, 2],
        );
        expect(
          await FutureOptionList.waitAllOrNone([some(), none()]).isNone(),
          isTrue,
        );
        expect(await FutureOptionList.waitAllOrNone<int>([]).unwrap(), isEmpty);
      },
    );

    test('any returns the first Some in input order or None', () async {
      expect(
        await FutureOptionList.any([none(), some(), some(3)]).unwrap(),
        2,
      );
      expect(await FutureOptionList.any([none(), none()]).isNone(), isTrue);
      expect(await FutureOptionList.any<int>([]).isNone(), isTrue);
    });

    test('collectSome ignores None values', () async {
      expect(await FutureOptionList.collectSome([some(1), none(), some()]), [
        1,
        2,
      ]);
    });
  });
}
