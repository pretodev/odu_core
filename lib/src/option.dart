import 'package:odu_core/odu_core.dart';

sealed class Option<T> {
  const Option();

  bool get isSome => this is Some<T>;
  bool get isNone => this is None<T>;

  T unwrap() => switch (this) {
    Some(value: final v) => v,
    None() => throw StateError('Chamou unwrap em None'),
  };

  T unwrapOr(T defaultValue) => switch (this) {
    Some(value: final v) => v,
    None() => defaultValue,
  };

  Option<U> map<U>(U Function(T value) transform) => switch (this) {
    Some(value: final v) => Some(transform(v)),
    None() => const None(),
  };

  Result<T> okOr(Exception error) => switch (this) {
    Some(value: final v) => Ok(v),
    None() => Err(error),
  };
}

final class Some<T> extends Option<T> {
  final T value;
  const Some(this.value);

  @override
  String toString() => 'Some($value)';
}

final class None<T> extends Option<T> {
  const None();

  @override
  String toString() => 'None';
}
