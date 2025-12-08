/// Used instead of `void` as a return statement for a function
/// when no value is to be returned.
///
/// There is only one value of type [Unit].
final class Unit {
  const Unit._();
}

const unit = Unit._();

/// Type alias for a future that resolves to a [Result].
///
/// ```dart
/// Task<int> fetchData() async {
///   return Result.data(42);
/// }
/// ```
typedef Task<T> = Future<Result<T>>;

/// Utility class to wrap result data
///
/// Evaluate the result using a switch statement:
/// ```dart
/// switch (result) {
///   case Done(): {
///     print(result.value);
///   }
///   case Error(): {
///     print(result.error);
///   }
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Creates a successful [Result] with a [Unit] value.
  static Result<Unit> get done => const Result.data(Unit._());

  /// Creates a successful [Result], completed with the specified [value].
  const factory Result.data(T value) = Done._;

  /// Creates an error [Result], completed with the specified [error].
  const factory Result.error(Exception error, [StackTrace? stackTrace]) =
      Error._;
}

/// Subclass of Result for values
final class Done<T> extends Result<T> {
  const Done._(this.data);

  /// Returned value in result
  final T data;

  @override
  String toString() => 'Result<$T>.ok($data)';
}

/// Subclass of Result for errors
final class Error<T> extends Result<T> {
  const Error._(this.error, [this.stackTrace]);

  /// Returned error in result
  final Exception error;

  final StackTrace? stackTrace;

  @override
  String toString() => 'Result<$T>.error($error, $stackTrace)';
}
