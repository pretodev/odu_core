import 'package:odu_core/odu_core.dart';
import 'package:test/test.dart';

void main() {
  const failure = _Failure('failed', debugDetails: 'details');

  group('Failure', () {
    test('formats user and debug information', () {
      expect(failure.toString(), '_Failure: failed | details');
      expect(const _Failure('failed').toString(), '_Failure: failed');
    });
  });

  group('Result', () {
    test('reports success and failure states', () {
      expect(const Ok(1).isOk, isTrue);
      expect(const Ok(1).isFail, isFalse);
      expect(const Err<int>(failure).isOk, isFalse);
      expect(const Err<int>(failure).isFail, isTrue);
    });

    test('unwrap returns Ok value and throws for Err', () {
      expect(const Ok(1).unwrap(), 1);
      expect(const Err<int>(failure).unwrap, throwsStateError);
    });

    test('fallback methods transform only Err', () {
      expect(const Ok(1).unwrapOr(2), 1);
      expect(const Err<int>(failure).unwrapOr(2), 2);
      expect(const Ok(1).unwrapOrElse((_) => 2), 1);
      expect(
        const Err<int>(failure).unwrapOrElse(
          (value) => value.failureReason.length,
        ),
        6,
      );
    });

    test('map, mapErr, and flatMap affect the matching branch', () {
      final stackTrace = StackTrace.current;
      expect(const Ok(2).map((value) => value * 2).unwrap(), 4);
      expect(
        Err<int>(failure, stackTrace).map((value) => value * 2),
        isA<Err<int>>().having(
          (value) => value.stackTrace,
          'stackTrace',
          stackTrace,
        ),
      );
      expect(const Ok(1).mapErr((_) => const _Failure('other')).unwrap(), 1);
      expect(
        const Err<int>(failure).mapErr((_) => const _Failure('other')),
        isA<Err<int>>().having(
          (value) => value.failure.failureReason,
          'reason',
          'other',
        ),
      );
      expect(const Ok(2).flatMap((value) => Ok('$value')).unwrap(), '2');
      expect(const Err<int>(failure).flatMap(Ok.new), isA<Err<int>>());
    });

    test('supports value and Unit success helpers', () {
      expect(1.ok.unwrap(), 1);
      expect(ok.unwrap(), unit);
    });
  });

  group('ResultList.zipAccumulate', () {
    test('collects all values in input order', () {
      final result = ResultList.zipAccumulate([const Ok(1), const Ok(2)]);

      expect(result.unwrap(), [1, 2]);
    });

    test('accumulates every failure in an immutable list', () {
      const other = _Failure('other');
      final result = ResultList.zipAccumulate<int>([
        const Ok(1),
        const Err(failure),
        const Err(other),
      ]);
      final accumulated =
          (result as Err<List<int>>).failure as AccumulatedFailure;

      expect(accumulated.failures, [failure, other]);
      expect(() => accumulated.failures.add(failure), throwsUnsupportedError);
      expect(accumulated.debugDetails, contains('failed'));
      expect(accumulated.debugDetails, contains('other'));
    });

    test('uses a custom failure aggregator', () {
      final result = ResultList.zipAccumulate<int>(
        [const Err(failure)],
        onFailure: (failures) => _Failure('${failures.length} errors'),
      );

      expect((result as Err<List<int>>).failure.failureReason, '1 errors');
    });
  });
}

final class const _Failure(
  super.failureReason, {
  super.debugDetails,
}) extends Failure {}
