import 'package:flutter/foundation.dart';

/// Base class for value equality based on [props].
///
/// Equality is restricted to instances with the same runtime type. Nested
/// iterables, sets, and maps are compared structurally.
@immutable
abstract class const Equatable() {
  /// Values that define this object's identity.
  List<Object?> get props;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Equatable &&
          runtimeType == other.runtimeType &&
          _sequenceEquals(props, other.props);

  @override
  int get hashCode => Object.hash(runtimeType, _sequenceHash(props));

  @override
  String toString() => '$runtimeType(${props.join(', ')})';
}

bool _sequenceEquals(Iterable<Object?> left, Iterable<Object?> right) {
  final leftIterator = left.iterator;
  final rightIterator = right.iterator;
  while (true) {
    final hasLeft = leftIterator.moveNext();
    final hasRight = rightIterator.moveNext();
    if (hasLeft != hasRight) {
      return false;
    }
    if (!hasLeft) {
      return true;
    }
    if (!_valueEquals(leftIterator.current, rightIterator.current)) {
      return false;
    }
  }
}

bool _valueEquals(Object? left, Object? right) {
  if (identical(left, right)) {
    return true;
  }
  if (left is Map<Object?, Object?> && right is Map<Object?, Object?>) {
    return _mapEquals(left, right);
  }
  if (left is Set<Object?> && right is Set<Object?>) {
    return _setEquals(left, right);
  }
  if (left is Iterable<Object?> && right is Iterable<Object?>) {
    return _sequenceEquals(left, right);
  }
  return left == right;
}

bool _mapEquals(Map<Object?, Object?> left, Map<Object?, Object?> right) {
  if (left.length != right.length) {
    return false;
  }
  final unmatched = right.entries.toList();
  for (final leftEntry in left.entries) {
    final index = unmatched.indexWhere(
      (rightEntry) =>
          _valueEquals(leftEntry.key, rightEntry.key) &&
          _valueEquals(leftEntry.value, rightEntry.value),
    );
    if (index < 0) {
      return false;
    }
    unmatched.removeAt(index);
  }
  return true;
}

bool _setEquals(Set<Object?> left, Set<Object?> right) {
  if (left.length != right.length) {
    return false;
  }
  final unmatched = right.toList();
  for (final value in left) {
    final index = unmatched.indexWhere((other) => _valueEquals(value, other));
    if (index < 0) {
      return false;
    }
    unmatched.removeAt(index);
  }
  return true;
}

int _sequenceHash(Iterable<Object?> values) =>
    Object.hashAll(values.map(_valueHash));

int _valueHash(Object? value) => switch (value) {
  Map<Object?, Object?>() => Object.hashAllUnordered(
    value.entries.map(
      (entry) => Object.hash(_valueHash(entry.key), _valueHash(entry.value)),
    ),
  ),
  Set<Object?>() => Object.hashAllUnordered(value.map(_valueHash)),
  Iterable<Object?>() => _sequenceHash(value),
  _ => value.hashCode,
};
