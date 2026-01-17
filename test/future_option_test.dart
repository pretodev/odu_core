import 'package:odu_core/odu_core.dart';
import 'package:test/test.dart';

void main() {
  group('FutureOption factory constructors', () {
    test('some creates a FutureOption with Some', () async {
      final option = await FutureOptionFactory.some(42);
      expect(option, isA<Some<int>>());
      expect((option as Some<int>).value, equals(42));
    });

    test('none creates a FutureOption with None', () async {
      final option = await FutureOptionFactory.none<int>();
      expect(option, isA<None<int>>());
    });

    test('from converts non-null Future to Some', () async {
      final future = Future.value(42);
      final option = await FutureOptionFactory.from(future);
      expect(option, isA<Some<int>>());
      expect((option as Some<int>).value, equals(42));
    });

    test('from converts null Future to None', () async {
      final future = Future<int?>.value(null);
      final option = await FutureOptionFactory.from(future);
      expect(option, isA<None<int>>());
    });
  });

  group('FutureOption map', () {
    test('transforms Some value', () async {
      final option = await FutureOptionFactory.some(42).map((x) => x * 2);
      expect(option, isA<Some<int>>());
      expect((option as Some<int>).value, equals(84));
    });

    test('preserves None', () async {
      final option =
          await FutureOptionFactory.none<int>().map((x) => x * 2);
      expect(option, isA<None<int>>());
    });

    test('can change type', () async {
      final option =
          await FutureOptionFactory.some(42).map((x) => x.toString());
      expect(option, isA<Some<String>>());
      expect((option as Some<String>).value, equals('42'));
    });
  });

  group('FutureOption mapAsync', () {
    test('asynchronously transforms Some value', () async {
      final option =
          await FutureOptionFactory.some(42).mapAsync((x) async => x * 2);
      expect(option, isA<Some<int>>());
      expect((option as Some<int>).value, equals(84));
    });

    test('preserves None', () async {
      final option = await FutureOptionFactory.none<int>()
          .mapAsync((x) async => x * 2)
          ;
      expect(option, isA<None<int>>());
    });

    test('handles async transformation', () async {
      final option = await FutureOptionFactory.some('hello')
          .mapAsync((s) => Future.delayed(
                const Duration(milliseconds: 10),
                () => s.toUpperCase(),
              ))
          ;
      expect(option, isA<Some<String>>());
      expect((option as Some<String>).value, equals('HELLO'));
    });
  });

  group('FutureOption flatMap', () {
    test('chains Some results', () async {
      final option = await FutureOptionFactory.some(42)
          .flatMap((x) => Some(x.toString()))
          ;
      expect(option, isA<Some<String>>());
      expect((option as Some<String>).value, equals('42'));
    });

    test('short-circuits on None', () async {
      final option = await FutureOptionFactory.none<int>()
          .flatMap((x) => Some(x.toString()))
          ;
      expect(option, isA<None<String>>());
    });

    test('can return None from transformation', () async {
      final option =
          await FutureOptionFactory.some(42).flatMap<String>((x) => const None());
      expect(option, isA<None<String>>());
    });
  });

  group('FutureOption flatMapAsync', () {
    test('chains async Some results', () async {
      final option = await FutureOptionFactory.some(42)
          .flatMapAsync((x) => FutureOptionFactory.some(x.toString()))
          ;
      expect(option, isA<Some<String>>());
      expect((option as Some<String>).value, equals('42'));
    });

    test('short-circuits on None', () async {
      final option = await FutureOptionFactory.none<int>()
          .flatMapAsync((x) => FutureOptionFactory.some(x.toString()))
          ;
      expect(option, isA<None<String>>());
    });

    test('can return None from async transformation', () async {
      final option = await FutureOptionFactory.some(42)
          .flatMapAsync<String>((x) => FutureOptionFactory.none())
          ;
      expect(option, isA<None<String>>());
    });
  });

  group('FutureOption unwrap', () {
    test('returns Some value', () async {
      final value = await FutureOptionFactory.some(42).unwrap();
      expect(value, equals(42));
    });

    test('throws on None', () async {
      expect(
        () => FutureOptionFactory.none<int>().unwrap(),
        throwsStateError,
      );
    });
  });

  group('FutureOption unwrapOr', () {
    test('returns Some value', () async {
      final value = await FutureOptionFactory.some(42).unwrapOr(100);
      expect(value, equals(42));
    });

    test('returns default on None', () async {
      final value = await FutureOptionFactory.none<int>().unwrapOr(100);
      expect(value, equals(100));
    });
  });

  group('FutureOption unwrapOrElseAsync', () {
    test('returns Some value', () async {
      final value = await FutureOptionFactory.some(42).unwrapOrElseAsync(() async => 100);
      expect(value, equals(42));
    });

    test('asynchronously computes default on None', () async {
      final value =
          await FutureOptionFactory.none<int>().unwrapOrElseAsync(() async => 100);
      expect(value, equals(100));
    });
  });

  group('FutureOption isSome and isNone', () {
    test('isSome returns true for Some', () async {
      expect(await FutureOptionFactory.some(42).isSome(), isTrue);
    });

    test('isSome returns false for None', () async {
      expect(await FutureOptionFactory.none<int>().isSome(), isFalse);
    });

    test('isNone returns false for Some', () async {
      expect(await FutureOptionFactory.some(42).isNone(), isFalse);
    });

    test('isNone returns true for None', () async {
      expect(await FutureOptionFactory.none<int>().isNone(), isTrue);
    });
  });

  group('FutureOption inspect', () {
    test('calls inspector on Some', () async {
      var called = false;
      await FutureOptionFactory.some(42).inspect((x) => called = true);
      expect(called, isTrue);
    });

    test('does not call inspector on None', () async {
      var called = false;
      await FutureOptionFactory.none<int>().inspect((x) => called = true);
      expect(called, isFalse);
    });

    test('preserves Some value', () async {
      final option = await FutureOptionFactory.some(42).inspect((x) {});
      expect(option, isA<Some<int>>());
      expect((option as Some<int>).value, equals(42));
    });
  });

  group('FutureOption okOr', () {
    test('converts Some to Ok', () async {
      final result =
          await FutureOptionFactory.some(42).okOr(Exception('test'));
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(42));
    });

    test('converts None to Err', () async {
      final error = Exception('test');
      final result = await FutureOptionFactory.none<int>().okOr(error);
      expect(result, isA<Err<int>>());
      expect((result as Err<int>).value, equals(error));
    });
  });

  group('FutureOption okOrElse', () {
    test('converts Some to Ok', () async {
      final result = await FutureOptionFactory.some(42)
          .okOrElse(() => Exception('test'))
          ;
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(42));
    });

    test('converts None to Err with lazy error', () async {
      final error = Exception('test');
      final result =
          await FutureOptionFactory.none<int>().okOrElse(() => error);
      expect(result, isA<Err<int>>());
      expect((result as Err<int>).value, equals(error));
    });

    test('does not call error provider for Some', () async {
      var called = false;
      await FutureOptionFactory.some(42).okOrElse(() {
        called = true;
        return Exception('test');
      });
      expect(called, isFalse);
    });
  });

  group('FutureOption toNullable', () {
    test('converts Some to value', () async {
      final value = await FutureOptionFactory.some(42).toNullable();
      expect(value, equals(42));
    });

    test('converts None to null', () async {
      final value = await FutureOptionFactory.none<int>().toNullable();
      expect(value, isNull);
    });
  });

  group('FutureOption filter', () {
    test('preserves Some when predicate is true', () async {
      final option =
          await FutureOptionFactory.some(42).filter((x) => x > 0);
      expect(option, isA<Some<int>>());
      expect((option as Some<int>).value, equals(42));
    });

    test('converts Some to None when predicate is false', () async {
      final option =
          await FutureOptionFactory.some(42).filter((x) => x < 0);
      expect(option, isA<None<int>>());
    });

    test('preserves None', () async {
      final option =
          await FutureOptionFactory.none<int>().filter((x) => x > 0);
      expect(option, isA<None<int>>());
    });
  });

  group('FutureOption filterAsync', () {
    test('preserves Some when async predicate is true', () async {
      final option = await FutureOptionFactory.some(42)
          .filterAsync((x) async => x > 0)
          ;
      expect(option, isA<Some<int>>());
      expect((option as Some<int>).value, equals(42));
    });

    test('converts Some to None when async predicate is false', () async {
      final option = await FutureOptionFactory.some(42)
          .filterAsync((x) async => x < 0)
          ;
      expect(option, isA<None<int>>());
    });

    test('preserves None', () async {
      final option = await FutureOptionFactory.none<int>()
          .filterAsync((x) async => x > 0)
          ;
      expect(option, isA<None<int>>());
    });
  });

  group('FutureOption timeout', () {
    test('completes before timeout', () async {
      final option = await FutureOptionFactory.some(42)
          .timeout(const Duration(seconds: 1))
          ;
      expect(option, isA<Some<int>>());
      expect((option as Some<int>).value, equals(42));
    });

    test('returns default None on timeout', () async {
      final future = Future.delayed(
        const Duration(milliseconds: 100),
        () => const Some(42) as Option<int>,
      );
      final option = await future
          .withTimeout(const Duration(milliseconds: 10));
      expect(option, isA<None<int>>());
    });

    test('uses custom timeout handler', () async {
      final future = Future.delayed(
        const Duration(milliseconds: 100),
        () => const Some(42) as Option<int>,
      );
      final option = await future
          .withTimeout(
            const Duration(milliseconds: 10),
            onTimeout: () => const Some(999),
          );
      expect(option, isA<Some<int>>());
      expect((option as Some<int>).value, equals(999));
    });
  });

  group('FutureOption chaining example', () {
    test('complex chaining scenario', () async {
      FutureOption<int> findValue(String key) async {
        final map = {'answer': 42, 'zero': 0};
        return map.containsKey(key) ? Some(map[key]!) : const None();
      }

      final result = await findValue('answer')
          .map((x) => x * 2)
          .filter((x) => x > 50)
          ;

      expect(result, isA<Some<int>>());
      expect((result as Some<int>).value, equals(84));
    });

    test('filter removes value in chain', () async {
      FutureOption<int> findValue(String key) async {
        final map = {'answer': 42, 'zero': 0};
        return map.containsKey(key) ? Some(map[key]!) : const None();
      }

      final result = await findValue('answer')
          .map((x) => x * 2)
          .filter((x) => x > 100)
          ;

      expect(result, isA<None<int>>());
    });

    test('conversion to Result', () async {
      FutureOption<String> getUsername(int userId) async {
        return userId == 1 ? const Some('Alice') : const None();
      }

      final result = await getUsername(1)
          .okOr(Exception('User not found'))
          ;

      expect(result, isA<Ok<String>>());
      expect((result as Ok<String>).value, equals('Alice'));
    });

    test('None converts to Err', () async {
      FutureOption<String> getUsername(int userId) async {
        return userId == 1 ? const Some('Alice') : const None();
      }

      final result = await getUsername(999)
          .okOr(Exception('User not found'))
          ;

      expect(result, isA<Err<String>>());
    });
  });

  group('FutureOption integration with nullable types', () {
    test('from handles nullable futures', () async {
      String? getNullable(bool returnNull) {
        return returnNull ? null : 'value';
      }

      final someOption =
          await FutureOptionFactory.from(Future.value(getNullable(false)));
      expect(someOption, isA<Some<String>>());

      final noneOption =
          await FutureOptionFactory.from(Future.value(getNullable(true)));
      expect(noneOption, isA<None<String>>());
    });

    test('toNullable round-trip', () async {
      final original = 'test value';
      final nullable =
          await FutureOptionFactory.some(original).toNullable();
      final option = await FutureOptionFactory.from(Future.value(nullable));

      expect(option, isA<Some<String>>());
      expect((option as Some<String>).value, equals(original));
    });
  });

  group('FutureOption edge cases', () {
    test('chaining multiple filters', () async {
      final option = await FutureOptionFactory.some(42)
          .filter((x) => x > 0)
          .filter((x) => x < 100)
          .filter((x) => x.isEven)
          ;

      expect(option, isA<Some<int>>());
      expect((option as Some<int>).value, equals(42));
    });

    test('filter chain with failure', () async {
      final option = await FutureOptionFactory.some(42)
          .filter((x) => x > 0)
          .filter((x) => x > 100) // This fails
          .filter((x) => x.isEven)
          ;

      expect(option, isA<None<int>>());
    });

    test('flatMap with conditional None', () async {
      FutureOption<int> parsePositive(String s) async {
        final value = int.tryParse(s);
        return (value != null && value > 0) ? Some(value) : const None();
      }

      final someResult = await FutureOptionFactory.some('42')
          .flatMapAsync((s) => parsePositive(s))
          ;
      expect(someResult, isA<Some<int>>());

      final noneResult = await FutureOptionFactory.some('-42')
          .flatMapAsync((s) => parsePositive(s))
          ;
      expect(noneResult, isA<None<int>>());
    });
  });
}
