import 'dart:async';

import 'package:odu_core/odu_core.dart';
import 'package:test/test.dart';

void main() {
  const failure = _Failure('failed');
  Future<Result<int>> success([int value = 2]) async => Ok(value);
  Future<Result<int>> error() async => const Err(failure);

  group('FutureResult', () {
    test(
      'maps and flatMaps success synchronously and asynchronously',
      () async {
        expect(await success().map((value) => value * 2).unwrap(), 4);
        expect(await error().map((value) => value * 2).isFail(), isTrue);
        expect(
          await success().mapAsync((value) async => value * 3).unwrap(),
          6,
        );
        expect(
          await error().mapAsync((value) async => value * 3).isFail(),
          isTrue,
        );
        expect(await success().flatMap((value) => Ok('$value')).unwrap(), '2');
        expect(await error().flatMap(Ok.new).isFail(), isTrue);
        expect(
          await success().flatMapAsync((value) async => Ok('$value')).unwrap(),
          '2',
        );
        expect(
          await error().flatMapAsync((value) async => Ok('$value')).isFail(),
          isTrue,
        );
      },
    );

    test('maps failures synchronously and asynchronously', () async {
      expect(
        await success().mapErr((_) => const _Failure('other')).unwrap(),
        2,
      );
      final mapped =
          await error().mapErr((_) => const _Failure('other')) as Err<int>;
      expect(mapped.failure.failureReason, 'other');
      final mappedAsync = await error().mapErrAsync(
        (_) async => const _Failure('async'),
      ) as Err<int>;
      expect(mappedAsync.failure.failureReason, 'async');
      expect(
        await success()
            .mapErrAsync((_) async => const _Failure('other'))
            .unwrap(),
        2,
      );
    });

    test('unwrap and fallback methods handle both branches', () async {
      expect(await success().unwrap(), 2);
      await expectLater(error().unwrap(), throwsStateError);
      expect(await success().unwrapOr(3), 2);
      expect(await error().unwrapOr(3), 3);
      expect(await success().unwrapOrElse((_) => 3), 2);
      expect(await error().unwrapOrElse((_) => 3), 3);
      expect(await success().unwrapOrElseAsync((_) async => 3), 2);
      expect(await error().unwrapOrElseAsync((_) async => 3), 3);
    });

    test('inspects only the matching branch', () async {
      var valueSeen = 0;
      Failure? failureSeen;
      expect(await success().inspect((value) => valueSeen = value).unwrap(), 2);
      expect(
        await error().inspect((value) => valueSeen = value).isFail(),
        isTrue,
      );
      expect(
        await success().inspectErr((value) => failureSeen = value).unwrap(),
        2,
      );
      expect(
        await error().inspectErr((value) => failureSeen = value).isFail(),
        isTrue,
      );
      expect(valueSeen, 2);
      expect(failureSeen, same(failure));
    });

    test('recovers with values and Results', () async {
      expect(await error().recover((_) => 3).unwrap(), 3);
      expect(await success().recover((_) => 3).unwrap(), 2);
      expect(await error().recoverAsync((_) async => 3).unwrap(), 3);
      expect(await success().recoverAsync((_) async => 3).unwrap(), 2);
      expect(await error().recoverWith((_) => const Ok(3)).unwrap(), 3);
      expect(await success().recoverWith((_) => const Ok(3)).unwrap(), 2);
      expect(
        await error().recoverWithAsync((_) async => const Ok(3)).unwrap(),
        3,
      );
      expect(
        await success().recoverWithAsync((_) async => const Ok(3)).unwrap(),
        2,
      );
    });

    test('exposes state predicates', () async {
      expect(await success().isOk(), isTrue);
      expect(await success().isFail(), isFalse);
      expect(await error().isOk(), isFalse);
      expect(await error().isFail(), isTrue);
    });

    test('returns configured or default failure on timeout', () async {
      final pending = Completer<Result<int>>().future;
      final defaultResult =
          await pending.withTimeout(Duration.zero) as Err<int>;

      expect(defaultResult.failure, isA<ResultTimeoutFailure>());
      expect(defaultResult.failure.debugDetails, contains('0:00:00.000000'));
      final custom = await pending.withTimeout(
        Duration.zero,
        onTimeout: () => const Ok(9),
      );
      expect(custom.unwrap(), 9);
    });
  });

  group('FutureResultFactory and FutureResultList', () {
    test('creates successful and failed futures', () async {
      expect(await FutureResultFactory.ok(1).unwrap(), 1);
      expect(await FutureResultFactory.err<int>(failure).isFail(), isTrue);
    });

    test('zips values and accumulates failures', () async {
      expect(
        await FutureResultList.zipAccumulate([success(1), success()]).unwrap(),
        [1, 2],
      );
      final result = await FutureResultList.zipAccumulate([success(), error()]);
      expect((result as Err<List<int>>).failure, isA<AccumulatedFailure>());
    });
  });
}

final class const _Failure(super.failureReason) extends Failure {}
