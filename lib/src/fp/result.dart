part of 'fp.dart';

/// Utility class to wrap result data
///
/// Evaluate the result using a switch statement:
/// ```dart
/// switch (result) {
///   case Ok(): {
///     print(result.value);
///   }
///   case Err(): {
///     print(result.failure);
///   }
/// }
/// ```
sealed class const Result<T>() {
  bool get isOk => this is Ok<T>;

  bool get isFail => this is Err<T>;

  T unwrap() => switch (this) {
    Ok(:final value) => value,
    Err(:final failure) => throw StateError('Chamou unwrap em Err: $failure'),
  };

  T unwrapOr(T defaultValue) => switch (this) {
    Ok(:final value) => value,
    Err() => defaultValue,
  };

  T unwrapOrElse(T Function(Failure failure) orElse) => switch (this) {
    Ok(:final value) => value,
    Err(:final failure) => orElse(failure),
  };

  Result<U> map<U>(U Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure, :final stackTrace) => Err(failure, stackTrace),
  };

  Result<T> mapErr(Failure Function(Failure failure) transform) =>
      switch (this) {
        Ok(:final value) => Ok(value),
        Err(:final failure, :final stackTrace) => Err(
          transform(failure),
          stackTrace,
        ),
      };

  Result<U> flatMap<U>(Result<U> Function(T value) transform) => switch (this) {
    Ok(:final value) => transform(value),
    Err(:final failure, :final stackTrace) => Err(failure, stackTrace),
  };
}

/// Aggregates multiple failures produced while zipping results.
final class AccumulatedFailure._(
  /// Failures collected while evaluating a batch of results.
  final List<Failure> failures, {
  required super.debugDetails,
}) extends Failure {
  factory(Iterable<Failure> failures) {
    final list = List<Failure>.unmodifiable(failures);
    return AccumulatedFailure._(list, debugDetails: _summarizeFailures(list));
  }
  this : super('Uma ou mais operações falharam.');
}

String _summarizeFailures(List<Failure> failures) =>
    failures.map((failure) => failure.toString()).join(' | ');

/// Subclass of Result for values
final class const Ok<T>(final T value) extends Result<T> {
  @override
  String toString() => 'Result<$T>.ok($value)';
}

const ok = Ok(unit);

/// Subclass of Result for failures
final class const Err<T>(final Failure failure, [final StackTrace? stackTrace])
    extends Result<T> {
  @override
  String toString() => 'Result<$T>.err($failure, $stackTrace)';
}

extension ResultValueExtension<T> on T {
  Result<T> get ok => Ok(this);
}

/// Utilities for working with collections of [Result] values.
abstract final class const ResultList._() {
  /// Collects all successful values or accumulates all failures.
  ///
  /// The input is evaluated fully, so every [Err] contributes to the returned
  /// failure set instead of short-circuiting at the first one.
  static Result<List<T>> zipAccumulate<T>(
    Iterable<Result<T>> results, {
    Failure Function(List<Failure> failures)? onFailure,
  }) {
    final values = <T>[];
    final failures = <Failure>[];

    for (final result in results) {
      switch (result) {
        case Ok(:final value):
          values.add(value);
        case Err(:final failure):
          failures.add(failure);
      }
    }

    if (failures.isEmpty) {
      return Ok(values);
    }

    return Err(
      onFailure?.call(failures) ?? AccumulatedFailure(failures),
    );
  }
}
