import 'package:odu_core/odu_core.dart' hide equals;
import 'package:test/test.dart';

void main() {
  group('Result', () {
    group('Done', () {
      test('creates successful result with data', () {
        const result = Result<int>.data(42);
        expect(result, isA<Done<int>>());
      });

      test('stores the correct value', () {
        const result = Result<int>.data(42);
        switch (result) {
          case Done(:final data):
            expect(data, equals(42));
          case Error():
            fail('Expected Done but got Error');
        }
      });

      test('works with different data types', () {
        const stringResult = Result<String>.data('hello');
        const intResult = Result<int>.data(42);
        const boolResult = Result<bool>.data(true);

        expect(stringResult, isA<Done<String>>());
        expect(intResult, isA<Done<int>>());
        expect(boolResult, isA<Done<bool>>());
      });

      test('can store null values', () {
        const result = Result<String?>.data(null);
        switch (result) {
          case Done(:final data):
            expect(data, isNull);
          case Error():
            fail('Expected Done but got Error');
        }
      });

      test('can store complex objects', () {
        final list = [1, 2, 3];
        final result = Result<List<int>>.data(list);

        switch (result) {
          case Done(:final data):
            expect(data, equals([1, 2, 3]));
          case Error():
            fail('Expected Done but got Error');
        }
      });

      test('toString includes type and value', () {
        const result = Result<int>.data(42);
        expect(result.toString(), contains('Result<int>'));
        expect(result.toString(), contains('42'));
      });
    });

    group('Error', () {
      test('creates error result', () {
        final error = Exception('test error');
        final result = Result<int>.error(error);
        expect(result, isA<Error<int>>());
      });

      test('stores the correct error', () {
        final error = Exception('test error');
        final result = Result<int>.error(error);

        switch (result) {
          case Done():
            fail('Expected Error but got Done');
          case Error(:final error):
            expect(error.toString(), contains('test error'));
        }
      });

      test('can include stack trace', () {
        final error = Exception('test error');
        final stackTrace = StackTrace.current;
        final result = Result<int>.error(error, stackTrace);

        switch (result) {
          case Done():
            fail('Expected Error but got Done');
          case Error(:final stackTrace):
            expect(stackTrace, isNotNull);
        }
      });

      test('stack trace is optional', () {
        final error = Exception('test error');
        final result = Result<int>.error(error);

        switch (result) {
          case Done():
            fail('Expected Error but got Done');
          case Error(:final stackTrace):
            expect(stackTrace, isNull);
        }
      });

      test('toString includes type and error', () {
        final error = Exception('test error');
        final result = Result<int>.error(error);
        expect(result.toString(), contains('Result<int>'));
        expect(result.toString(), contains('test error'));
      });
    });

    group('Unit', () {
      test('Result.done creates Result<Unit>', () {
        final result = Result.done;
        expect(result, isA<Done<Unit>>());
      });

      test('Result.done is always the same instance', () {
        final result1 = Result.done;
        final result2 = Result.done;
        expect(identical(result1, result2), isTrue);
      });

      test('unit constant is the only Unit value', () {
        expect(unit, isA<Unit>());
      });

      test('can create custom Unit results', () {
        const result = Result<Unit>.data(unit);
        expect(result, isA<Done<Unit>>());
      });
    });

    group('Pattern matching', () {
      test('can match Done case', () {
        const result = Result<int>.data(42);
        var matched = false;

        switch (result) {
          case Done():
            matched = true;
          case Error():
            break;
        }

        expect(matched, isTrue);
      });

      test('can match Error case', () {
        final result = Result<int>.error(Exception('test'));
        var matched = false;

        switch (result) {
          case Done():
            break;
          case Error():
            matched = true;
        }

        expect(matched, isTrue);
      });

      test('can extract data using pattern matching', () {
        const result = Result<int>.data(42);
        int? extractedValue;

        switch (result) {
          case Done(data: final value):
            extractedValue = value;
          case Error():
            break;
        }

        expect(extractedValue, equals(42));
      });

      test('can extract error using pattern matching', () {
        final error = Exception('test error');
        final result = Result<int>.error(error);
        Exception? extractedError;

        switch (result) {
          case Done():
            break;
          case Error(error: final e):
            extractedError = e;
        }

        expect(extractedError, equals(error));
      });
    });

    group('Task', () {
      test('Task is alias for Future<Result>', () {
        expect(Task<int>, equals(Future<Result<int>>));
      });

      test('async function can return Task', () async {
        Task<int> fetchData() async {
          return const Result.data(42);
        }

        final result = await fetchData();
        expect(result, isA<Done<int>>());
      });

      test('Task can return error', () async {
        Task<int> fetchData() async {
          return Result.error(Exception('fetch failed'));
        }

        final result = await fetchData();
        expect(result, isA<Error<int>>());
      });

      test('Task can perform async operations', () async {
        Task<int> fetchData() async {
          await Future.delayed(Duration(milliseconds: 10));
          return const Result.data(42);
        }

        final result = await fetchData();
        switch (result) {
          case Done(:final data):
            expect(data, equals(42));
          case Error():
            fail('Expected Done but got Error');
        }
      });

      test('Task can chain operations', () async {
        Task<int> fetchData() async {
          return const Result.data(42);
        }

        Task<String> processData(int value) async {
          return Result.data('Value: $value');
        }

        final result1 = await fetchData();
        switch (result1) {
          case Done(:final data):
            final result2 = await processData(data);
            switch (result2) {
              case Done(:final data):
                expect(data, equals('Value: 42'));
              case Error():
                fail('Expected Done but got Error');
            }
          case Error():
            fail('Expected Done but got Error');
        }
      });
    });

    group('Real-world scenarios', () {
      test('parsing with validation', () {
        Result<int> parseAge(String input) {
          final age = int.tryParse(input);
          if (age == null) {
            return Result.error(Exception('Invalid age format'));
          }
          if (age < 0 || age > 150) {
            return Result.error(Exception('Age out of range'));
          }
          return Result.data(age);
        }

        final validResult = parseAge('25');
        expect(validResult, isA<Done<int>>());

        final invalidFormatResult = parseAge('abc');
        expect(invalidFormatResult, isA<Error<int>>());

        final outOfRangeResult = parseAge('200');
        expect(outOfRangeResult, isA<Error<int>>());
      });

      test('database operation simulation', () async {
        Task<String> fetchUser(int id) async {
          if (id <= 0) {
            return Result.error(Exception('Invalid user ID'));
          }
          await Future.delayed(Duration(milliseconds: 10));
          if (id == 999) {
            return Result.error(Exception('User not found'));
          }
          return Result.data('User $id');
        }

        final success = await fetchUser(1);
        expect(success, isA<Done<String>>());

        final notFound = await fetchUser(999);
        expect(notFound, isA<Error<String>>());

        final invalid = await fetchUser(-1);
        expect(invalid, isA<Error<String>>());
      });

      test('void operations with Unit', () {
        Result<Unit> deleteRecord(int id) {
          if (id <= 0) {
            return Result.error(Exception('Invalid ID'));
          }
          // Perform deletion
          return Result.done;
        }

        final success = deleteRecord(1);
        expect(success, isA<Done<Unit>>());

        final failure = deleteRecord(-1);
        expect(failure, isA<Error<Unit>>());
      });
    });
  });
}
