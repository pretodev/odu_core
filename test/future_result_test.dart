import 'package:odu_core/odu_core.dart';
import 'package:test/test.dart';

void main() {
  group('FutureResult factory constructors', () {
    test('ok creates a successful FutureResult', () async {
      final result = await FutureResultFactory.ok(42);
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(42));
    });

    test('err creates an error FutureResult', () async {
      final error = Exception('test error');
      final result = await FutureResultFactory.err<int>(error);
      expect(result, isA<Err<int>>());
      expect((result as Err<int>).value, equals(error));
    });

    test('err with stackTrace preserves stackTrace', () async {
      final error = Exception('test error');
      final stackTrace = StackTrace.current;
      final result = await FutureResultFactory.err<int>(error, stackTrace);
      expect(result, isA<Err<int>>());
      expect((result as Err<int>).stackTrace, equals(stackTrace));
    });

    test('from wraps successful Future', () async {
      final future = Future.value(42);
      final result = await FutureResultFactory.from(future);
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(42));
    });

    test('from wraps failing Future', () async {
      final future = Future<int>.error(Exception('failed'));
      final result = await FutureResultFactory.from(future);
      expect(result, isA<Err<int>>());
    });

    test('from converts non-Exception errors to Exception', () async {
      final future = Future<int>.error('string error');
      final result = await FutureResultFactory.from(future);
      expect(result, isA<Err<int>>());
      expect((result as Err<int>).value.toString(), contains('string error'));
    });
  });

  group('FutureResult map', () {
    test('transforms Ok value', () async {
      final result = await FutureResultFactory.ok(42).map((x) => x * 2);
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(84));
    });

    test('preserves Err', () async {
      final error = Exception('test');
      final result = await FutureResultFactory.err<int>(
        error,
      ).map((x) => x * 2);
      expect(result, isA<Err<int>>());
      expect((result as Err<int>).value, equals(error));
    });

    test('can change type', () async {
      final result = await FutureResultFactory.ok(42).map((x) => x.toString());
      expect(result, isA<Ok<String>>());
      expect((result as Ok<String>).value, equals('42'));
    });
  });

  group('FutureResult mapAsync', () {
    test('asynchronously transforms Ok value', () async {
      final result = await FutureResultFactory.ok(
        42,
      ).mapAsync((x) async => x * 2);
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(84));
    });

    test('preserves Err', () async {
      final error = Exception('test');
      final result = await FutureResultFactory.err<int>(
        error,
      ).mapAsync((x) async => x * 2);
      expect(result, isA<Err<int>>());
      expect((result as Err<int>).value, equals(error));
    });

    test('handles async transformation', () async {
      final result = await FutureResultFactory.ok('hello').mapAsync(
        (s) => Future.delayed(
          const Duration(milliseconds: 10),
          () => s.toUpperCase(),
        ),
      );
      expect(result, isA<Ok<String>>());
      expect((result as Ok<String>).value, equals('HELLO'));
    });
  });

  group('FutureResult mapErr', () {
    test('transforms Err value', () async {
      final error = Exception('original');
      final result = await FutureResultFactory.err<int>(
        error,
      ).mapErr((e) => Exception('transformed: $e'));
      expect(result, isA<Err<int>>());
      expect((result as Err<int>).value.toString(), contains('transformed'));
    });

    test('preserves Ok', () async {
      final result = await FutureResultFactory.ok(
        42,
      ).mapErr((e) => Exception('transformed'));
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(42));
    });
  });

  group('FutureResult mapErrAsync', () {
    test('asynchronously transforms Err value', () async {
      final error = Exception('original');
      final result = await FutureResultFactory.err<int>(
        error,
      ).mapErrAsync((e) async => Exception('transformed: $e'));
      expect(result, isA<Err<int>>());
      expect((result as Err<int>).value.toString(), contains('transformed'));
    });

    test('preserves Ok', () async {
      final result = await FutureResultFactory.ok(
        42,
      ).mapErrAsync((e) async => Exception('transformed'));
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(42));
    });
  });

  group('FutureResult flatMap', () {
    test('chains Ok results', () async {
      final result = await FutureResultFactory.ok(
        42,
      ).flatMap((x) => Ok(x.toString()));
      expect(result, isA<Ok<String>>());
      expect((result as Ok<String>).value, equals('42'));
    });

    test('short-circuits on Err', () async {
      final error = Exception('test');
      final result = await FutureResultFactory.err<int>(
        error,
      ).flatMap((x) => Ok(x.toString()));
      expect(result, isA<Err<String>>());
      expect((result as Err<String>).value, equals(error));
    });

    test('can return Err from transformation', () async {
      final result = await FutureResultFactory.ok(
        42,
      ).flatMap<String>((x) => Err(Exception('failed')));
      expect(result, isA<Err<String>>());
    });
  });

  group('FutureResult flatMapAsync', () {
    test('chains async Ok results', () async {
      final result = await FutureResultFactory.ok(
        42,
      ).flatMapAsync((x) => FutureResultFactory.ok(x.toString()));
      expect(result, isA<Ok<String>>());
      expect((result as Ok<String>).value, equals('42'));
    });

    test('short-circuits on Err', () async {
      final error = Exception('test');
      final result = await FutureResultFactory.err<int>(
        error,
      ).flatMapAsync((x) => FutureResultFactory.ok(x.toString()));
      expect(result, isA<Err<String>>());
      expect((result as Err<String>).value, equals(error));
    });

    test('can return Err from async transformation', () async {
      final result = await FutureResultFactory.ok(42).flatMapAsync<String>(
        (x) => FutureResultFactory.err(Exception('failed')),
      );
      expect(result, isA<Err<String>>());
    });
  });

  group('FutureResult unwrap', () {
    test('returns Ok value', () async {
      final value = await FutureResultFactory.ok(42).unwrap();
      expect(value, equals(42));
    });

    test('throws on Err', () async {
      expect(
        () => FutureResultFactory.err<int>(Exception('test')).unwrap(),
        throwsStateError,
      );
    });
  });

  group('FutureResult unwrapOr', () {
    test('returns Ok value', () async {
      final value = await FutureResultFactory.ok(42).unwrapOr(100);
      expect(value, equals(42));
    });

    test('returns default on Err', () async {
      final value = await FutureResultFactory.err<int>(
        Exception('test'),
      ).unwrapOr(100);
      expect(value, equals(100));
    });
  });

  group('FutureResult unwrapOrElse', () {
    test('returns Ok value', () async {
      final value = await FutureResultFactory.ok(42).unwrapOrElse((e) => 100);
      expect(value, equals(42));
    });

    test('computes value from error', () async {
      final value = await FutureResultFactory.err<int>(
        Exception('test'),
      ).unwrapOrElse((e) => 100);
      expect(value, equals(100));
    });
  });

  group('FutureResult unwrapOrElseAsync', () {
    test('returns Ok value', () async {
      final value = await FutureResultFactory.ok(
        42,
      ).unwrapOrElseAsync((e) async => 100);
      expect(value, equals(42));
    });

    test('asynchronously computes value from error', () async {
      final value = await FutureResultFactory.err<int>(
        Exception('test'),
      ).unwrapOrElseAsync((e) async => 100);
      expect(value, equals(100));
    });
  });

  group('FutureResult isOk and isFail', () {
    test('isOk returns true for Ok', () async {
      expect(await FutureResultFactory.ok(42).isOk(), isTrue);
    });

    test('isOk returns false for Err', () async {
      expect(
        await FutureResultFactory.err<int>(Exception('test')).isOk(),
        isFalse,
      );
    });

    test('isFail returns false for Ok', () async {
      expect(await FutureResultFactory.ok(42).isFail(), isFalse);
    });

    test('isFail returns true for Err', () async {
      expect(
        await FutureResultFactory.err<int>(Exception('test')).isFail(),
        isTrue,
      );
    });
  });

  group('FutureResult inspect', () {
    test('calls inspector on Ok', () async {
      var called = false;
      await FutureResultFactory.ok(42).inspect((x) => called = true);
      expect(called, isTrue);
    });

    test('does not call inspector on Err', () async {
      var called = false;
      await FutureResultFactory.err<int>(
        Exception('test'),
      ).inspect((x) => called = true);
      expect(called, isFalse);
    });

    test('preserves Ok value', () async {
      final result = await FutureResultFactory.ok(42).inspect((x) {});
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(42));
    });
  });

  group('FutureResult inspectErr', () {
    test('calls inspector on Err', () async {
      var called = false;
      await FutureResultFactory.err<int>(
        Exception('test'),
      ).inspectErr((e) => called = true);
      expect(called, isTrue);
    });

    test('does not call inspector on Ok', () async {
      var called = false;
      await FutureResultFactory.ok(42).inspectErr((e) => called = true);
      expect(called, isFalse);
    });

    test('preserves Err', () async {
      final error = Exception('test');
      final result = await FutureResultFactory.err<int>(
        error,
      ).inspectErr((e) {});
      expect(result, isA<Err<int>>());
      expect((result as Err<int>).value, equals(error));
    });
  });

  group('FutureResult toOption', () {
    test('converts Ok to Some', () async {
      final option = await FutureResultFactory.ok(42).toOption();
      expect(option, isA<Some<int>>());
      expect((option as Some<int>).value, equals(42));
    });

    test('converts Err to None', () async {
      final option = await FutureResultFactory.err<int>(
        Exception('test'),
      ).toOption();
      expect(option, isA<None<int>>());
    });
  });

  group('FutureResult recover', () {
    test('preserves Ok', () async {
      final result = await FutureResultFactory.ok(42).recover((e) => 100);
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(42));
    });

    test('recovers from Err', () async {
      final result = await FutureResultFactory.err<int>(
        Exception('test'),
      ).recover((e) => 100);
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(100));
    });
  });

  group('FutureResult recoverAsync', () {
    test('preserves Ok', () async {
      final result = await FutureResultFactory.ok(
        42,
      ).recoverAsync((e) async => 100);
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(42));
    });

    test('asynchronously recovers from Err', () async {
      final result = await FutureResultFactory.err<int>(
        Exception('test'),
      ).recoverAsync((e) async => 100);
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(100));
    });
  });

  group('FutureResult recoverWith', () {
    test('preserves Ok', () async {
      final result = await FutureResultFactory.ok(
        42,
      ).recoverWith((e) => const Ok(100));
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(42));
    });

    test('recovers with Ok', () async {
      final result = await FutureResultFactory.err<int>(
        Exception('test'),
      ).recoverWith((e) => const Ok(100));
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(100));
    });

    test('can return Err from recovery', () async {
      final newError = Exception('new error');
      final result = await FutureResultFactory.err<int>(
        Exception('test'),
      ).recoverWith((e) => Err(newError));
      expect(result, isA<Err<int>>());
      expect((result as Err<int>).value, equals(newError));
    });
  });

  group('FutureResult recoverWithAsync', () {
    test('preserves Ok', () async {
      final result = await FutureResultFactory.ok(
        42,
      ).recoverWithAsync((e) => FutureResultFactory.ok(100));
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(42));
    });

    test('asynchronously recovers with Ok', () async {
      final result = await FutureResultFactory.err<int>(
        Exception('test'),
      ).recoverWithAsync((e) => FutureResultFactory.ok(100));
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(100));
    });

    test('can return Err from async recovery', () async {
      final newError = Exception('new error');
      final result = await FutureResultFactory.err<int>(
        Exception('test'),
      ).recoverWithAsync((e) => FutureResultFactory.err(newError));
      expect(result, isA<Err<int>>());
      expect((result as Err<int>).value, equals(newError));
    });
  });

  group('FutureResult timeout', () {
    test('completes before timeout', () async {
      final result = await FutureResultFactory.ok(
        42,
      ).timeout(const Duration(seconds: 1));
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(42));
    });

    test('returns default error on timeout', () async {
      final future = Future.delayed(
        const Duration(milliseconds: 100),
        () => const Ok(42) as Result<int>,
      );
      final result = await future.withTimeout(const Duration(milliseconds: 10));
      expect(result, isA<Err<int>>());
      expect((result as Err<int>).value.toString(), contains('timed out'));
    });

    test('uses custom timeout handler', () async {
      final future = Future.delayed(
        const Duration(milliseconds: 100),
        () => const Ok(42) as Result<int>,
      );
      final result = await future.withTimeout(
        const Duration(milliseconds: 10),
        onTimeout: () => Err(Exception('custom timeout')),
      );
      expect(result, isA<Err<int>>());
      expect((result as Err<int>).value.toString(), contains('custom timeout'));
    });
  });

  group('FutureResultList waitAll', () {
    test('waits for all results', () async {
      final results = await FutureResultList.waitAll([
        FutureResultFactory.ok(1),
        FutureResultFactory.ok(2),
        FutureResultFactory.ok(3),
      ]);
      expect(results, hasLength(3));
      expect(results[0], isA<Ok<int>>());
      expect(results[1], isA<Ok<int>>());
      expect(results[2], isA<Ok<int>>());
    });

    test('includes Err results', () async {
      final results = await FutureResultList.waitAll([
        FutureResultFactory.ok(1),
        FutureResultFactory.err<int>(Exception('test')),
        FutureResultFactory.ok(3),
      ]);
      expect(results, hasLength(3));
      expect(results[0], isA<Ok<int>>());
      expect(results[1], isA<Err<int>>());
      expect(results[2], isA<Ok<int>>());
    });
  });

  group('FutureResultList waitAllOrError', () {
    test('returns Ok with all values if all succeed', () async {
      final result = await FutureResultList.waitAllOrError([
        FutureResultFactory.ok(1),
        FutureResultFactory.ok(2),
        FutureResultFactory.ok(3),
      ]);
      expect(result, isA<Ok<List<int>>>());
      expect((result as Ok<List<int>>).value, equals([1, 2, 3]));
    });

    test('returns first Err if any fails', () async {
      final error = Exception('test');
      final result = await FutureResultList.waitAllOrError([
        FutureResultFactory.ok(1),
        FutureResultFactory.err<int>(error),
        FutureResultFactory.ok(3),
      ]);
      expect(result, isA<Err<List<int>>>());
      expect((result as Err<List<int>>).value, equals(error));
    });

    test('returns Ok with empty list for empty input', () async {
      final result = await FutureResultList.waitAllOrError<int>([]);
      expect(result, isA<Ok<List<int>>>());
      expect((result as Ok<List<int>>).value, isEmpty);
    });
  });

  group('FutureResultList any', () {
    test('returns first Ok result', () async {
      final result = await FutureResultList.any([
        FutureResultFactory.err<int>(Exception('1')),
        FutureResultFactory.ok(42),
        FutureResultFactory.ok(100),
      ]);
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(42));
    });

    test('returns Err if all fail', () async {
      final result = await FutureResultList.any([
        FutureResultFactory.err<int>(Exception('1')),
        FutureResultFactory.err<int>(Exception('2')),
        FutureResultFactory.err<int>(Exception('3')),
      ]);
      expect(result, isA<Err<int>>());
    });

    test('returns Err for empty input', () async {
      final result = await FutureResultList.any<int>([]);
      expect(result, isA<Err<int>>());
      expect(
        (result as Err<int>).value.toString(),
        contains('No future results provided'),
      );
    });
  });

  group('FutureResult chaining example', () {
    test('complex chaining scenario', () async {
      FutureResult<int> divide(int a, int b) async {
        if (b == 0) {
          return Err(Exception('Division by zero'));
        }
        return Ok(a ~/ b);
      }

      final result = await divide(
        100,
        2,
      ).map((x) => x + 10).flatMapAsync((x) => divide(x, 3)).recover((e) => 0);

      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(20));
    });

    test('error handling in chain', () async {
      FutureResult<int> divide(int a, int b) async {
        if (b == 0) {
          return Err(Exception('Division by zero'));
        }
        return Ok(a ~/ b);
      }

      final result = await divide(
        100,
        0,
      ).map((x) => x + 10).recover((e) => 999);

      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, equals(999));
    });
  });
}
