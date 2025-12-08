import 'package:odu_core/odu_core.dart' hide equals;
import 'package:test/test.dart';

// Test specifications
class IsPositive implements Specification<int> {
  @override
  bool isSatisfiedBy(int entity) => entity > 0;
}

class IsEven implements Specification<int> {
  @override
  bool isSatisfiedBy(int entity) => entity % 2 == 0;
}

class IsGreaterThan implements Specification<int> {
  final int threshold;
  IsGreaterThan(this.threshold);

  @override
  bool isSatisfiedBy(int entity) => entity > threshold;
}

class IsLessThan implements Specification<int> {
  final int threshold;
  IsLessThan(this.threshold);

  @override
  bool isSatisfiedBy(int entity) => entity < threshold;
}

// Complex object specification
class User {
  final String name;
  final int age;
  final bool isActive;

  User({required this.name, required this.age, required this.isActive});
}

class IsAdult implements Specification<User> {
  @override
  bool isSatisfiedBy(User entity) => entity.age >= 18;
}

class IsActive implements Specification<User> {
  @override
  bool isSatisfiedBy(User entity) => entity.isActive;
}

class HasName implements Specification<User> {
  final String name;
  HasName(this.name);

  @override
  bool isSatisfiedBy(User entity) => entity.name == name;
}

void main() {
  group('Specification', () {
    group('Basic specification', () {
      test('isSatisfiedBy returns true when condition met', () {
        final spec = IsPositive();
        expect(spec.isSatisfiedBy(5), isTrue);
        expect(spec.isSatisfiedBy(1), isTrue);
      });

      test('isSatisfiedBy returns false when condition not met', () {
        final spec = IsPositive();
        expect(spec.isSatisfiedBy(-5), isFalse);
        expect(spec.isSatisfiedBy(0), isFalse);
      });

      test('works with different data types', () {
        final spec = IsEven();
        expect(spec.isSatisfiedBy(2), isTrue);
        expect(spec.isSatisfiedBy(4), isTrue);
        expect(spec.isSatisfiedBy(3), isFalse);
      });

      test('can be parameterized', () {
        final spec = IsGreaterThan(10);
        expect(spec.isSatisfiedBy(15), isTrue);
        expect(spec.isSatisfiedBy(5), isFalse);
      });
    });

    group('And specification', () {
      test('returns true when both specifications satisfied', () {
        final spec = IsPositive().and(IsEven());
        expect(spec.isSatisfiedBy(4), isTrue);
        expect(spec.isSatisfiedBy(2), isTrue);
      });

      test('returns false when first specification not satisfied', () {
        final spec = IsPositive().and(IsEven());
        expect(spec.isSatisfiedBy(-2), isFalse);
      });

      test('returns false when second specification not satisfied', () {
        final spec = IsPositive().and(IsEven());
        expect(spec.isSatisfiedBy(3), isFalse);
      });

      test('returns false when neither specification satisfied', () {
        final spec = IsPositive().and(IsEven());
        expect(spec.isSatisfiedBy(-3), isFalse);
      });

      test('can chain multiple and operations', () {
        final spec = IsPositive().and(IsEven()).and(IsGreaterThan(5));
        expect(spec.isSatisfiedBy(8), isTrue);
        expect(spec.isSatisfiedBy(4), isFalse); // Not > 5
        expect(spec.isSatisfiedBy(7), isFalse); // Not even
      });
    });

    group('Or specification', () {
      test('returns true when both specifications satisfied', () {
        final spec = IsPositive().or(IsEven());
        expect(spec.isSatisfiedBy(4), isTrue);
      });

      test('returns true when first specification satisfied', () {
        final spec = IsPositive().or(IsEven());
        expect(spec.isSatisfiedBy(3), isTrue); // Positive but not even
      });

      test('returns true when second specification satisfied', () {
        final spec = IsPositive().or(IsEven());
        expect(spec.isSatisfiedBy(-2), isTrue); // Even but not positive
      });

      test('returns false when neither specification satisfied', () {
        final spec = IsPositive().or(IsEven());
        expect(spec.isSatisfiedBy(-3), isFalse);
      });

      test('can chain multiple or operations', () {
        final spec = IsGreaterThan(10).or(IsLessThan(0)).or(IsEven());
        expect(spec.isSatisfiedBy(15), isTrue); // > 10
        expect(spec.isSatisfiedBy(-5), isTrue); // < 0
        expect(spec.isSatisfiedBy(6), isTrue); // Even
        expect(spec.isSatisfiedBy(7), isFalse); // None satisfied
      });
    });

    group('Not specification', () {
      test('returns true when specification not satisfied', () {
        final spec = IsPositive().not();
        expect(spec.isSatisfiedBy(-5), isTrue);
        expect(spec.isSatisfiedBy(0), isTrue);
      });

      test('returns false when specification satisfied', () {
        final spec = IsPositive().not();
        expect(spec.isSatisfiedBy(5), isFalse);
      });

      test('double negation returns to original', () {
        final spec = IsPositive().not().not();
        expect(spec.isSatisfiedBy(5), isTrue);
        expect(spec.isSatisfiedBy(-5), isFalse);
      });

      test('can be combined with and', () {
        final spec = IsPositive().not().and(IsEven());
        expect(spec.isSatisfiedBy(-2), isTrue); // Not positive AND even
        expect(spec.isSatisfiedBy(2), isFalse); // Positive
        expect(spec.isSatisfiedBy(-3), isFalse); // Not even
      });

      test('can be combined with or', () {
        final spec = IsPositive().not().or(IsEven());
        expect(spec.isSatisfiedBy(-3), isTrue); // Not positive
        expect(spec.isSatisfiedBy(4), isTrue); // Even
        expect(spec.isSatisfiedBy(3), isFalse); // Positive and not even
      });
    });

    group('Complex combinations', () {
      test('combines and, or, not', () {
        // (positive AND even) OR (less than -5)
        final spec = IsPositive().and(IsEven()).or(IsLessThan(-5));
        expect(spec.isSatisfiedBy(4), isTrue); // Positive and even
        expect(spec.isSatisfiedBy(-10), isTrue); // Less than -5
        expect(spec.isSatisfiedBy(3), isFalse); // Positive but not even
        expect(spec.isSatisfiedBy(-3), isFalse); // Not less than -5
      });

      test('De Morgan\'s law: NOT (A AND B) = (NOT A) OR (NOT B)', () {
        final spec1 = IsPositive().and(IsEven()).not();
        final spec2 = IsPositive().not().or(IsEven().not());

        // Both should give same results
        for (final value in [-5, -2, 0, 3, 4]) {
          expect(spec1.isSatisfiedBy(value), equals(spec2.isSatisfiedBy(value)),
              reason: 'De Morgan\'s law failed for $value');
        }
      });

      test('De Morgan\'s law: NOT (A OR B) = (NOT A) AND (NOT B)', () {
        final spec1 = IsPositive().or(IsEven()).not();
        final spec2 = IsPositive().not().and(IsEven().not());

        for (final value in [-5, -2, 0, 3, 4]) {
          expect(spec1.isSatisfiedBy(value), equals(spec2.isSatisfiedBy(value)),
              reason: 'De Morgan\'s law failed for $value');
        }
      });

      test('nested specifications', () {
        // ((positive AND even) OR (less than -5)) AND (less than or equal to -10)
        // This means: values that are either (positive and even) or (less than -5),
        // but only if they're also <= -10. So only values <= -10 and < -5 will satisfy.
        final spec = IsPositive()
            .and(IsEven())
            .or(IsLessThan(-5))
            .and(IsGreaterThan(-10).not());

        expect(spec.isSatisfiedBy(4), isFalse); // Positive and even, but > -10
        expect(spec.isSatisfiedBy(-15), isTrue); // < -5 and <= -10
        expect(spec.isSatisfiedBy(-8), isFalse); // < -5 but > -10
      });
    });

    group('Complex object specifications', () {
      test('works with custom objects', () {
        final user = User(name: 'Alice', age: 25, isActive: true);
        final spec = IsAdult();

        expect(spec.isSatisfiedBy(user), isTrue);
      });

      test('combines specifications for objects', () {
        final adult = User(name: 'Alice', age: 25, isActive: true);
        final minor = User(name: 'Bob', age: 15, isActive: true);
        final inactive = User(name: 'Charlie', age: 30, isActive: false);

        final spec = IsAdult().and(IsActive());

        expect(spec.isSatisfiedBy(adult), isTrue);
        expect(spec.isSatisfiedBy(minor), isFalse);
        expect(spec.isSatisfiedBy(inactive), isFalse);
      });

      test('filters list of objects', () {
        final users = [
          User(name: 'Alice', age: 25, isActive: true),
          User(name: 'Bob', age: 15, isActive: true),
          User(name: 'Charlie', age: 30, isActive: false),
          User(name: 'Dave', age: 20, isActive: true),
        ];

        final spec = IsAdult().and(IsActive());
        final filtered = users.where(spec.isSatisfiedBy).toList();

        expect(filtered.length, equals(2));
        expect(filtered[0].name, equals('Alice'));
        expect(filtered[1].name, equals('Dave'));
      });

      test('parameterized object specifications', () {
        final users = [
          User(name: 'Alice', age: 25, isActive: true),
          User(name: 'Bob', age: 15, isActive: true),
          User(name: 'Alice', age: 30, isActive: false),
        ];

        final spec = HasName('Alice');
        final filtered = users.where(spec.isSatisfiedBy).toList();

        expect(filtered.length, equals(2));
        expect(filtered.every((u) => u.name == 'Alice'), isTrue);
      });
    });

    group('Real-world scenarios', () {
      test('business rule validation', () {
        // Rule: User can access premium features if they are adult AND active
        final canAccessPremium = IsAdult().and(IsActive());

        final validUser = User(name: 'Alice', age: 25, isActive: true);
        final minorUser = User(name: 'Bob', age: 15, isActive: true);
        final inactiveUser = User(name: 'Charlie', age: 30, isActive: false);

        expect(canAccessPremium.isSatisfiedBy(validUser), isTrue);
        expect(canAccessPremium.isSatisfiedBy(minorUser), isFalse);
        expect(canAccessPremium.isSatisfiedBy(inactiveUser), isFalse);
      });

      test('filtering with multiple criteria', () {
        final numbers = List.generate(20, (i) => i - 10);

        // Filter: (positive AND even) OR (less than -5)
        final spec = IsPositive().and(IsEven()).or(IsLessThan(-5));
        final filtered = numbers.where(spec.isSatisfiedBy).toList();

        expect(filtered, equals([-10, -9, -8, -7, -6, 2, 4, 6, 8]));
      });

      test('reusable specifications', () {
        final activeAdultSpec = IsAdult().and(IsActive());

        final users1 = [
          User(name: 'Alice', age: 25, isActive: true),
          User(name: 'Bob', age: 15, isActive: true),
        ];

        final users2 = [
          User(name: 'Charlie', age: 30, isActive: false),
          User(name: 'Dave', age: 20, isActive: true),
        ];

        // Same specification can be reused
        expect(users1.where(activeAdultSpec.isSatisfiedBy).length, equals(1));
        expect(users2.where(activeAdultSpec.isSatisfiedBy).length, equals(1));
      });

      test('dynamic specification building', () {
        Specification<int> buildRangeSpec(int min, int max) {
          return IsGreaterThan(min).and(IsLessThan(max));
        }

        final inRange = buildRangeSpec(0, 10);
        expect(inRange.isSatisfiedBy(5), isTrue);
        expect(inRange.isSatisfiedBy(-1), isFalse);
        expect(inRange.isSatisfiedBy(10), isFalse);
      });
    });
  });
}
