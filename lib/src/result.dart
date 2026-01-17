/// Used instead of `void` as a return statement for a function
/// when no value is to be returned.
///
/// There is only one value of type [Unit].
final class Unit {
  const Unit._();
}

const unit = Unit._();

const ok = Ok(unit);

/// Utility class to wrap result data
///
/// Evaluate the result using a switch statement:
/// ```dart
/// switch (result) {
///   case Ok(): {
///     print(result.value);
///   }
///   case Err(): {
///     print(result.value);
///   }
/// }
/// ```
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  bool get isFail => this is Err<T>;

  T unwrap() {
    return switch (this) {
      Ok(value: final v) => v,
      Err(value: final e) => throw StateError('Chamou unwrap em Fail: $e'),
    };
  }

  T unwrapOr(T defaultValue) {
    return switch (this) {
      Ok(value: final v) => v,
      Err() => defaultValue,
    };
  }

  T unwrapOrElse(T Function(Exception error) orElse) {
    return switch (this) {
      Ok(value: final v) => v,
      Err(value: final e) => orElse(e),
    };
  }

  Result<U> map<U>(U Function(T value) transform) {
    return switch (this) {
      Ok(value: final v) => Ok(transform(v)),
      Err(value: final e) => Err(e),
    };
  }

  Result<T> mapErr(Exception Function(Exception error) transform) {
    return switch (this) {
      Ok(value: final v) => Ok(v),
      Err(value: final e) => Err(transform(e)),
    };
  }

  Result<U> flatMap<U>(Result<U> Function(T value) transform) {
    return switch (this) {
      Ok(value: final v) => transform(v),
      Err(value: final e) => Err(e),
    };
  }
}

/// Subclass of Result for values
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  /// Returned value in result
  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// Subclass of Result for errors
final class Err<T> extends Result<T> {
  const Err(this.value, [this.stackTrace]);

  /// Returned error in result
  final Exception value;

  /// The stack trace associated with the error, if available.
  final StackTrace? stackTrace;

  @override
  String toString() => 'Result<$T>.error($value, $stackTrace)';
}
