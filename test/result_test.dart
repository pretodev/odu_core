import 'package:odu_core/odu_core.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    group('Ok', () {
      test('creates successful result with value', () {
        final result = const Ok<int>(42);
        expect(result, isA<Ok<int>>());
      });

      test('stores the correct value', () {
        final result = const Ok<int>(42);
        switch (result) {
          case Ok(:final value):
            expect(value, equals(42));
        }
      });

      test('works with different data types', () {
        final stringResult = const Ok<String>('hello');
        final intResult = const Ok<int>(42);
        final boolResult = const Ok<bool>(true);

        expect(stringResult, isA<Ok<String>>());
        expect(intResult, isA<Ok<int>>());
        expect(boolResult, isA<Ok<bool>>());
      });

      test('can store null values', () {
        final result = const Ok<String?>(null);
        switch (result) {
          case Ok(:final value):
            expect(value, isNull);
        }
      });

      test('can store complex objects', () {
        final list = [1, 2, 3];
        final result = Ok<List<int>>(list);

        switch (result) {
          case Ok(:final value):
            expect(value, equals([1, 2, 3]));
        }
      });

      test('toString includes type and value', () {
        final result = const Ok<int>(42);
        expect(result.toString(), contains('Result<int>'));
        expect(result.toString(), contains('42'));
      });
    });

    group('Err', () {
      test('creates error result', () {
        final error = Exception('test error');
        final result = Err<int>(error);
        expect(result, isA<Err<int>>());
      });

      test('stores the correct error', () {
        final error = Exception('test error');
        final result = Err<int>(error);

        switch (result) {
          case Err(:final value):
            expect(value.toString(), contains('test error'));
        }
      });

      test('can include stack trace', () {
        final error = Exception('test error');
        final stackTrace = StackTrace.current;
        final result = Err<int>(error, stackTrace);

        switch (result) {
          case Err(:final stackTrace):
            expect(stackTrace, isNotNull);
        }
      });

      test('stack trace is optional', () {
        final error = Exception('test error');
        final result = Err<int>(error);

        switch (result) {
          case Err(:final stackTrace):
            expect(stackTrace, isNull);
        }
      });

      test('toString includes type and error', () {
        final error = Exception('test error');
        final result = Err<int>(error);
        expect(result.toString(), contains('Result<int>'));
        expect(result.toString(), contains('test error'));
      });
    });

    group('Unit', () {
      test('ok constant creates Result<Unit>', () {
        expect(ok, isA<Ok<Unit>>());
      });

      test('ok is always the same instance', () {
        final result1 = ok;
        final result2 = ok;
        expect(identical(result1, result2), isTrue);
      });

      test('unit constant is the only Unit value', () {
        expect(unit, isA<Unit>());
      });

      test('can create custom Unit results', () {
        final result = const Ok<Unit>(unit);
        expect(result, isA<Ok<Unit>>());
      });
    });

    group('Pattern matching', () {
      test('can match Ok case', () {
        final result = const Ok<int>(42);
        var matched = false;

        switch (result) {
          case Ok():
            matched = true;
        }

        expect(matched, isTrue);
      });

      test('can match Err case', () {
        final result = Err<int>(Exception('test'));
        var matched = false;

        switch (result) {
          case Err():
            matched = true;
        }

        expect(matched, isTrue);
      });

      test('can extract value using pattern matching', () {
        final result = const Ok<int>(42);
        int? extractedValue;

        switch (result) {
          case Ok(value: final v):
            extractedValue = v;
        }

        expect(extractedValue, equals(42));
      });

      test('can extract error using pattern matching', () {
        final error = Exception('test error');
        final result = Err<int>(error);
        Exception? extractedError;

        switch (result) {
          case Err(value: final e):
            extractedError = e;
        }

        expect(extractedError, equals(error));
      });
    });

    group('FutureResult (formerly Task)', () {
      test('FutureResult is alias for Future<Result>', () {
        expect(FutureResult<int>, equals(Future<Result<int>>));
      });

      test('async function can return FutureResult', () async {
        FutureResult<int> fetchData() async {
          return const Ok(42);
        }

        final result = await fetchData();
        expect(result, isA<Ok<int>>());
      });

      test('FutureResult can return error', () async {
        FutureResult<int> fetchData() async {
          return Err(Exception('fetch failed'));
        }

        final result = await fetchData();
        expect(result, isA<Err<int>>());
      });

      test('FutureResult can perform async operations', () async {
        FutureResult<int> fetchData() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return const Ok(42);
        }

        final result = await fetchData();
        switch (result) {
          case Ok(:final value):
            expect(value, equals(42));
          case Err():
            fail('Expected Ok but got Err');
        }
      });

      test('FutureResult can chain operations', () async {
        FutureResult<int> fetchData() async {
          return const Ok(42);
        }

        FutureResult<String> processData(int value) async {
          return Ok('Value: $value');
        }

        final result1 = await fetchData();
        switch (result1) {
          case Ok(:final value):
            final result2 = await processData(value);
            switch (result2) {
              case Ok(:final value):
                expect(value, equals('Value: 42'));
              case Err():
                fail('Expected Ok but got Err');
            }
          case Err():
            fail('Expected Ok but got Err');
        }
      });
    });

    group('Real-world scenarios', () {
      test('parsing with validation', () {
        Result<int> parseAge(String input) {
          final age = int.tryParse(input);
          if (age == null) {
            return Err(Exception('Invalid age format'));
          }
          if (age < 0 || age > 150) {
            return Err(Exception('Age out of range'));
          }
          return Ok(age);
        }

        final validResult = parseAge('25');
        expect(validResult, isA<Ok<int>>());

        final invalidFormatResult = parseAge('abc');
        expect(invalidFormatResult, isA<Err<int>>());

        final outOfRangeResult = parseAge('200');
        expect(outOfRangeResult, isA<Err<int>>());
      });

      test('database operation simulation', () async {
        FutureResult<String> fetchUser(int id) async {
          if (id <= 0) {
            return Err(Exception('Invalid user ID'));
          }
          await Future.delayed(const Duration(milliseconds: 10));
          if (id == 999) {
            return Err(Exception('User not found'));
          }
          return Ok('User $id');
        }

        final success = await fetchUser(1);
        expect(success, isA<Ok<String>>());

        final notFound = await fetchUser(999);
        expect(notFound, isA<Err<String>>());

        final invalid = await fetchUser(-1);
        expect(invalid, isA<Err<String>>());
      });

      test('void operations with Unit', () {
        Result<Unit> deleteRecord(int id) {
          if (id <= 0) {
            return Err(Exception('Invalid ID'));
          }
          // Perform deletion
          return ok;
        }

        final success = deleteRecord(1);
        expect(success, isA<Ok<Unit>>());

        final failure = deleteRecord(-1);
        expect(failure, isA<Err<Unit>>());
      });
    });
  });
}
