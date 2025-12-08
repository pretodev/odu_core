abstract interface class Specification<T> {
  bool isSatisfiedBy(T entity);
}

extension SpecificationExtension<T> on Specification<T> {
  Specification<T> and(Specification<T> specification) {
    return AndSpecification(this, specification);
  }

  Specification<T> or(Specification<T> specification) {
    return OrSpecification(this, specification);
  }

  Specification<T> not() {
    return NotSpecification(this);
  }
}

class AndSpecification<T> implements Specification<T> {
  final Specification<T> _right;
  final Specification<T> _left;

  AndSpecification(this._right, this._left);

  @override
  bool isSatisfiedBy(T entity) {
    return _right.isSatisfiedBy(entity) && _left.isSatisfiedBy(entity);
  }
}

class OrSpecification<T> implements Specification<T> {
  final Specification<T> _right;
  final Specification<T> _left;

  OrSpecification(this._right, this._left);

  @override
  bool isSatisfiedBy(T entity) {
    return _right.isSatisfiedBy(entity) || _left.isSatisfiedBy(entity);
  }
}

class NotSpecification<T> implements Specification<T> {
  final Specification<T> _specification;

  NotSpecification(this._specification);

  @override
  bool isSatisfiedBy(T entity) {
    return !_specification.isSatisfiedBy(entity);
  }
}
