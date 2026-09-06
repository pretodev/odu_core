import 'package:odu_core/odu_core.dart';

/// Contract for evaluating whether an entity satisfies a rule.
///
/// Implement this interface to define business rules that can be composed
/// using `and()`, `or()`, and `not()` extension methods.
///
/// Example:
/// ```dart
/// class IsAdult implements Specification<Person> {
///   @override
///   bool isSatisfiedBy(Person entity) => entity.age >= 18;
/// }
///
/// class HasLicense implements Specification<Person> {
///   @override
///   bool isSatisfiedBy(Person entity) => entity.hasDriverLicense;
/// }
///
/// final canDrive = IsAdult().and(HasLicense());
/// if (canDrive.isSatisfiedBy(person)) {
///   print('Can drive!');
/// }
/// ```
abstract interface class Specification<T extends Entity>() {
  /// Evaluates whether the given [entity] satisfies this specification.
  ///
  /// Returns `true` if the entity meets the rule, `false` otherwise.
  bool isSatisfiedBy(T entity);
}

extension SpecificationExtension<T extends Entity> on Specification<T> {
  /// Combines this specification with [specification] using logical AND.
  ///
  /// Returns a new specification that is satisfied only when both
  /// specifications are satisfied.
  Specification<T> and(Specification<T> specification) =>
      AndSpecification(this, specification);

  /// Combines this specification with [specification] using logical OR.
  ///
  /// Returns a new specification that is satisfied when either
  /// specification is satisfied.
  Specification<T> or(Specification<T> specification) =>
      OrSpecification(this, specification);

  /// Negates this specification.
  ///
  /// Returns a new specification that is satisfied when this
  /// specification is not satisfied.
  Specification<T> not() => NotSpecification(this);
}

/// Combines two specifications and requires both to be satisfied.
class AndSpecification<T extends Entity>(
  final Specification<T> _right,
  final Specification<T> _left,
) implements Specification<T> {
  @override
  bool isSatisfiedBy(T entity) =>
      _right.isSatisfiedBy(entity) && _left.isSatisfiedBy(entity);
}

/// Combines two specifications and requires either to be satisfied.
class OrSpecification<T extends Entity>(
  final Specification<T> _right,
  final Specification<T> _left,
) implements Specification<T> {
  @override
  bool isSatisfiedBy(T entity) =>
      _right.isSatisfiedBy(entity) || _left.isSatisfiedBy(entity);
}

/// Negates the result of a specification.
class NotSpecification<T extends Entity>(
  final Specification<T> _specification,
) implements Specification<T> {
  @override
  bool isSatisfiedBy(T entity) => !_specification.isSatisfiedBy(entity);
}
