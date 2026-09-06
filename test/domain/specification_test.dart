import 'package:odu_core/odu_core.dart';
import 'package:test/test.dart';

void main() {
  group('Specification', () {
    final even = _PredicateSpecification((entity) => entity.value.isEven);
    final positive = _PredicateSpecification((entity) => entity.value > 0);

    group('and', () {
      test('is satisfied only when both specifications are satisfied', () {
        final specification = even.and(positive);

        expect(specification.isSatisfiedBy(_entity(2)), isTrue);
        expect(specification.isSatisfiedBy(_entity(-2)), isFalse);
        expect(specification.isSatisfiedBy(_entity(1)), isFalse);
      });

      test(
        'does not evaluate the second specification after a false result',
        () {
          var evaluations = 0;
          final specification =
              _PredicateSpecification(
                (_) => false,
              ).and(
                _PredicateSpecification((_) {
                  evaluations++;
                  return true;
                }),
              );

          expect(specification.isSatisfiedBy(_entity(1)), isFalse);
          expect(evaluations, isZero);
        },
      );
    });

    group('or', () {
      test('is satisfied when either specification is satisfied', () {
        final specification = even.or(positive);

        expect(specification.isSatisfiedBy(_entity(2)), isTrue);
        expect(specification.isSatisfiedBy(_entity(1)), isTrue);
        expect(specification.isSatisfiedBy(_entity(-1)), isFalse);
      });

      test(
        'does not evaluate the second specification after a true result',
        () {
          var evaluations = 0;
          final specification =
              _PredicateSpecification(
                (_) => true,
              ).or(
                _PredicateSpecification((_) {
                  evaluations++;
                  return false;
                }),
              );

          expect(specification.isSatisfiedBy(_entity(1)), isTrue);
          expect(evaluations, isZero);
        },
      );
    });

    test('not negates the wrapped specification', () {
      final specification = positive.not();

      expect(specification.isSatisfiedBy(_entity(1)), isFalse);
      expect(specification.isSatisfiedBy(_entity(-1)), isTrue);
    });

    test('composes multiple logical operations', () {
      final specification = even.and(positive).or(positive.not());

      expect(specification.isSatisfiedBy(_entity(2)), isTrue);
      expect(specification.isSatisfiedBy(_entity(1)), isFalse);
      expect(specification.isSatisfiedBy(_entity(-1)), isTrue);
    });
  });
}

_TestEntity _entity(int value) =>
    _TestEntity(value, GuidId.seeded('test-entity-$value'));

final class const _TestEntity(final int value, GuidId id) extends Entity {
  this : super(id: id);
}

final class const _PredicateSpecification(
  final bool Function(_TestEntity entity) _predicate,
) implements Specification<_TestEntity> {
  @override
  bool isSatisfiedBy(_TestEntity entity) => _predicate(entity);
}
