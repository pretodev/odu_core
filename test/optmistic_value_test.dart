import 'dart:async';

import 'package:odu_core/odu_core.dart' hide equals;
import 'package:test/test.dart';

void main() {
  group('OptimisticValue', () {
    group('Stream behavior', () {
      test('emits source stream values', () async {
        final controller = StreamController<int>();
        final optimistic = OptimisticValue(controller.stream);

        final values = <int>[];
        final subscription = optimistic.stream.listen(values.add);

        controller.add(1);
        controller.add(2);
        controller.add(3);

        await Future.delayed(const Duration(milliseconds: 50));
        await subscription.cancel();
        await controller.close();

        expect(values, equals([1, 2, 3]));
      });

      test('updates internal state from source stream', () async {
        final controller = StreamController<int>();
        final optimistic = OptimisticValue(controller.stream);

        // Start listening to initialize
        final subscription = optimistic.stream.listen((_) {});

        controller.add(42);
        await Future.delayed(const Duration(milliseconds: 50));

        // Verify state is updated by checking update function works
        final result = await optimistic.update<Unit>(
          () async => Result.done,
          (current) => current + 1,
        );

        expect(result, isA<Done<Unit>>());

        await subscription.cancel();
        await controller.close();
      });

      test('supports multiple listeners', () async {
        final controller = StreamController<int>.broadcast();
        final optimistic = OptimisticValue(controller.stream);

        final values1 = <int>[];
        final values2 = <int>[];

        final sub1 = optimistic.stream.listen(values1.add);
        final sub2 = optimistic.stream.listen(values2.add);

        controller.add(1);
        controller.add(2);

        await Future.delayed(const Duration(milliseconds: 50));

        expect(values1, equals([1, 2]));
        expect(values2, equals([1, 2]));

        await sub1.cancel();
        await sub2.cancel();
        await controller.close();
      });

      test('can be disposed', () {
        final controller = StreamController<int>();
        final optimistic = OptimisticValue(controller.stream);

        expect(() => optimistic.dispose(), returnsNormally);
        controller.close();
      });
    });

    group('Optimistic updates', () {
      test('applies optimistic update immediately', () async {
        final controller = StreamController<int>();
        final optimistic = OptimisticValue(controller.stream);

        final values = <int>[];
        final subscription = optimistic.stream.listen(values.add);

        // Initialize state
        controller.add(10);
        await Future.delayed(const Duration(milliseconds: 50));

        // Perform optimistic update
        final updateFuture = optimistic.update<Unit>(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return Result.done;
        }, (current) => current + 5);

        // Check that optimistic value is emitted immediately
        await Future.delayed(const Duration(milliseconds: 50));
        expect(values.last, equals(15)); // 10 + 5

        await updateFuture;
        await subscription.cancel();
        await controller.close();
      });

      test('keeps optimistic value on successful task', () async {
        final controller = StreamController<int>();
        final optimistic = OptimisticValue(controller.stream);

        final values = <int>[];
        final subscription = optimistic.stream.listen(values.add);

        controller.add(10);
        await Future.delayed(const Duration(milliseconds: 50));

        await optimistic.update<Unit>(
          () async => Result.done,
          (current) => current + 5,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Should still have the optimistic value
        expect(values.last, equals(15));

        await subscription.cancel();
        await controller.close();
      });

      test('returns task result', () async {
        final controller = StreamController<int>();
        final optimistic = OptimisticValue(controller.stream);

        final subscription = optimistic.stream.listen((_) {});

        controller.add(10);
        await Future.delayed(const Duration(milliseconds: 50));

        final result = await optimistic.update<String>(
          () async => const Result.data('success'),
          (current) => current + 5,
        );

        expect(result, isA<Done<String>>());
        switch (result) {
          case Done(:final data):
            expect(data, equals('success'));
          case Error():
            fail('Expected Done');
        }

        await subscription.cancel();
        await controller.close();
      });
    });

    group('Rollback on error', () {
      test('rolls back to previous state on error', () async {
        final controller = StreamController<int>();
        final optimistic = OptimisticValue(controller.stream);

        final values = <int>[];
        final subscription = optimistic.stream.listen(values.add);

        controller.add(10);
        await Future.delayed(const Duration(milliseconds: 50));
        values.clear(); // Clear initial value

        await optimistic.update<Unit>(
          () async => Result.error(Exception('task failed')),
          (current) => current + 5,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Should have: optimistic value (15), then rollback (10)
        expect(values, equals([15, 10]));

        await subscription.cancel();
        await controller.close();
      });

      test('returns error result on failure', () async {
        final controller = StreamController<int>();
        final optimistic = OptimisticValue(controller.stream);

        final subscription = optimistic.stream.listen((_) {});

        controller.add(10);
        await Future.delayed(const Duration(milliseconds: 50));

        final error = Exception('task failed');
        final result = await optimistic.update<Unit>(
          () async => Result.error(error),
          (current) => current + 5,
        );

        expect(result, isA<Error<Unit>>());
        switch (result) {
          case Done():
            fail('Expected Error');
          case Error(:final error):
            expect(error.toString(), contains('task failed'));
        }

        await subscription.cancel();
        await controller.close();
      });

      test('preserves state after rollback', () async {
        final controller = StreamController<int>();
        final optimistic = OptimisticValue(controller.stream);

        final subscription = optimistic.stream.listen((_) {});

        controller.add(10);
        await Future.delayed(const Duration(milliseconds: 50));

        // First update fails
        await optimistic.update<Unit>(
          () async => Result.error(Exception('failed')),
          (current) => current + 5,
        );

        // Second update succeeds
        final result = await optimistic.update<Unit>(
          () async => Result.done,
          (current) => current + 3,
        );

        expect(result, isA<Done<Unit>>());

        await subscription.cancel();
        await controller.close();
      });
    });

    group('Error handling', () {
      test('returns error when state not initialized', () async {
        final controller = StreamController<int>();
        final optimistic = OptimisticValue(controller.stream);

        // Start listening but don't add any values to initialize state
        final subscription = optimistic.stream.listen((_) {});
        await Future.delayed(const Duration(milliseconds: 10));

        final result = await optimistic.update<Unit>(
          () async => Result.done,
          (current) => current + 1,
        );

        expect(result, isA<Error<Unit>>());

        await subscription.cancel();
        await controller.close();
      });
    });

    group('Complex scenarios', () {
      test('handles multiple rapid updates', () async {
        final controller = StreamController<int>();
        final optimistic = OptimisticValue(controller.stream);

        final subscription = optimistic.stream.listen((_) {});

        controller.add(0);
        await Future.delayed(const Duration(milliseconds: 50));

        // Perform multiple updates in sequence
        await optimistic.update<Unit>(
          () async => Result.done,
          (current) => current + 1,
        );

        await optimistic.update<Unit>(
          () async => Result.done,
          (current) => current + 2,
        );

        await optimistic.update<Unit>(
          () async => Result.done,
          (current) => current + 3,
        );

        await subscription.cancel();
        await controller.close();
      });

      test('handles concurrent source and optimistic updates', () async {
        final controller = StreamController<int>();
        final optimistic = OptimisticValue(controller.stream);

        final values = <int>[];
        final subscription = optimistic.stream.listen(values.add);

        controller.add(10);
        await Future.delayed(const Duration(milliseconds: 50));

        // Start optimistic update
        final updateFuture = optimistic.update<Unit>(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return Result.done;
        }, (current) => current + 5);

        // Add source value while update is in progress
        await Future.delayed(const Duration(milliseconds: 50));
        controller.add(20);

        await updateFuture;
        await Future.delayed(const Duration(milliseconds: 50));

        // Should receive values from both source and optimistic streams
        expect(values.length, greaterThan(1));

        await subscription.cancel();
        await controller.close();
      });
    });
  });

  group('ListReplacer', () {
    test('replaces item when predicate matches', () {
      final list = [1, 2, 3, 4, 5];
      final replacer = ListReplacer(list);

      final result = replacer.replace(99, (item) => item == 3);

      expect(result, equals([1, 2, 99, 4, 5]));
    });

    test('adds item when predicate does not match', () {
      final list = [1, 2, 3];
      final replacer = ListReplacer(list);

      final result = replacer.replace(99, (item) => item == 5);

      expect(result, equals([1, 2, 3, 99]));
    });

    test('replaces first matching item only', () {
      final list = [1, 2, 3, 2, 5];
      final replacer = ListReplacer(list);

      final result = replacer.replace(99, (item) => item == 2);

      expect(result, equals([1, 99, 3, 2, 5]));
    });

    test('works with empty list', () {
      final list = <int>[];
      final replacer = ListReplacer(list);

      final result = replacer.replace(99, (item) => item == 1);

      expect(result, equals([99]));
    });

    test('works with complex objects', () {
      final items = [
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
        {'id': 3, 'name': 'Charlie'},
      ];

      final replacer = ListReplacer(items);
      final newItem = {'id': 2, 'name': 'Robert'};

      final result = replacer.replace(newItem, (item) => item['id'] == 2);

      expect(result[1], equals(newItem));
      expect(result[1]['name'], equals('Robert'));
    });

    test('modifies original list', () {
      final list = [1, 2, 3];
      final replacer = ListReplacer(list);

      replacer.replace(99, (item) => item == 2);

      expect(list[1], equals(99)); // Original list is modified
    });

    test('returns same list reference when replacing', () {
      final list = [1, 2, 3];
      final replacer = ListReplacer(list);

      final result = replacer.replace(99, (item) => item == 2);

      expect(identical(result, list), isTrue);
    });

    test('returns new list with added item when not found', () {
      final list = [1, 2, 3];
      final replacer = ListReplacer(list);

      final result = replacer.replace(99, (item) => item == 5);

      expect(identical(result, list), isFalse);
      expect(result, equals([1, 2, 3, 99]));
    });

    test('use case: updating entities in list', () {
      final entities = [
        {'id': 'a', 'value': 1},
        {'id': 'b', 'value': 2},
        {'id': 'c', 'value': 3},
      ];

      final replacer = ListReplacer(entities);
      final updated = {'id': 'b', 'value': 200};

      final result = replacer.replace(updated, (entity) => entity['id'] == 'b');

      expect(result.length, equals(3));
      expect(result[1]['value'], equals(200));
    });
  });
}
