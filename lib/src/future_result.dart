import 'dart:async';

import 'future_option.dart';
import 'option.dart';
import 'result.dart';

/// Type alias for [Future<Result<T>>] providing a concise type for async results.
///
/// Example:
/// ```dart
/// FutureResult<User> fetchUser(String id) async {
///   try {
///     final response = await http.get('/users/$id');
///     if (response.statusCode == 200) {
///       return Ok(User.fromJson(response.body));
///     }
///     return Err(Exception('User not found'));
///   } catch (e, stackTrace) {
///     return Err(e is Exception ? e : Exception(e.toString()), stackTrace);
///   }
/// }
///
/// // Chaining operations
/// FutureResult<String> getUserName(String id) {
///   return fetchUser(id)
///     .map((user) => user.name)
///     .recover((error) => 'Unknown User');
/// }
/// ```
typedef FutureResult<T> = Future<Result<T>>;

/// Extension methods for [Future<Result<T>>] providing ergonomic async utilities.
extension FutureResultExtension<T> on Future<Result<T>> {
  /// Transforms the success value using [transform].
  ///
  /// If this is [Ok], applies [transform] to the value and returns [Ok] with
  /// the transformed value. If this is [Err], returns the error unchanged.
  Future<Result<U>> map<U>(U Function(T value) transform) async {
    final result = await this;
    return result.map(transform);
  }

  /// Asynchronously transforms the success value using [transform].
  ///
  /// Similar to [map] but [transform] returns a [Future].
  Future<Result<U>> mapAsync<U>(Future<U> Function(T value) transform) async {
    final result = await this;
    return switch (result) {
      Ok(value: final v) => Ok(await transform(v)),
      Err(value: final e, stackTrace: final s) => Err(e, s),
    };
  }

  /// Transforms the error using [transform].
  ///
  /// If this is [Err], applies [transform] to the error and returns [Err] with
  /// the transformed error. If this is [Ok], returns the value unchanged.
  Future<Result<T>> mapErr(
    Exception Function(Exception error) transform,
  ) async {
    final result = await this;
    return result.mapErr(transform);
  }

  /// Asynchronously transforms the error using [transform].
  ///
  /// Similar to [mapErr] but [transform] returns a [Future].
  Future<Result<T>> mapErrAsync(
    Future<Exception> Function(Exception error) transform,
  ) async {
    final result = await this;
    return switch (result) {
      Ok(value: final v) => Ok(v),
      Err(value: final e, stackTrace: final s) => Err(await transform(e), s),
    };
  }

  /// Applies [transform] to the success value and flattens the result.
  ///
  /// If this is [Ok], applies [transform] to the value (which returns a
  /// [Result]) and returns that result. If this is [Err], returns the error.
  Future<Result<U>> flatMap<U>(Result<U> Function(T value) transform) async {
    final result = await this;
    return result.flatMap(transform);
  }

  /// Asynchronously applies [transform] to the success value and flattens.
  ///
  /// Similar to [flatMap] but [transform] returns a [Future<Result<U>>].
  Future<Result<U>> flatMapAsync<U>(
    Future<Result<U>> Function(T value) transform,
  ) async {
    final result = await this;
    return switch (result) {
      Ok(value: final v) => await transform(v),
      Err(value: final e, stackTrace: final s) => Err(e, s),
    };
  }

  /// Extracts the value from [Ok] or throws a [StateError] if [Err].
  Future<T> unwrap() async {
    final result = await this;
    return result.unwrap();
  }

  /// Extracts the value from [Ok] or returns [defaultValue] if [Err].
  Future<T> unwrapOr(T defaultValue) async {
    final result = await this;
    return result.unwrapOr(defaultValue);
  }

  /// Extracts the value from [Ok] or computes a value from the error.
  ///
  /// If this is [Ok], returns the value. If this is [Err], applies [orElse]
  /// to the error and returns the result.
  Future<T> unwrapOrElse(T Function(Exception error) orElse) async {
    final result = await this;
    return result.unwrapOrElse(orElse);
  }

  /// Asynchronously extracts the value or computes a value from the error.
  ///
  /// Similar to [unwrapOrElse] but [orElse] returns a [Future].
  Future<T> unwrapOrElseAsync(
    Future<T> Function(Exception error) orElse,
  ) async {
    final result = await this;
    return switch (result) {
      Ok(value: final v) => v,
      Err(value: final e) => await orElse(e),
    };
  }

  /// Returns whether this is [Ok].
  Future<bool> isOk() async {
    final result = await this;
    return result.isOk;
  }

  /// Returns whether this is [Err].
  Future<bool> isFail() async {
    final result = await this;
    return result.isFail;
  }

  /// Calls [inspector] with the success value without modifying the result.
  ///
  /// If this is [Ok], calls [inspector] with the value and returns [Ok] with
  /// the same value. If this is [Err], returns the error unchanged.
  Future<Result<T>> inspect(void Function(T value) inspector) async {
    final result = await this;
    if (result case Ok(value: final v)) {
      inspector(v);
    }
    return result;
  }

  /// Calls [inspector] with the error without modifying the result.
  ///
  /// If this is [Err], calls [inspector] with the error and returns [Err] with
  /// the same error. If this is [Ok], returns the value unchanged.
  Future<Result<T>> inspectErr(
    void Function(Exception error) inspector,
  ) async {
    final result = await this;
    if (result case Err(value: final e)) {
      inspector(e);
    }
    return result;
  }

  /// Converts this [FutureResult] to a [FutureOption].
  ///
  /// [Ok] becomes [Some] and [Err] becomes [None].
  Future<Option<T>> toOption() async {
    final result = await this;
    return switch (result) {
      Ok(value: final v) => Some(v),
      Err() => const None(),
    };
  }

  /// Recovers from an error by providing a replacement value.
  ///
  /// If this is [Ok], returns the value unchanged. If this is [Err], applies
  /// [recovery] to the error and returns [Ok] with the result.
  Future<Result<T>> recover(T Function(Exception error) recovery) async {
    final result = await this;
    return switch (result) {
      Ok() => result,
      Err(value: final e) => Ok(recovery(e)),
    };
  }

  /// Asynchronously recovers from an error by providing a replacement value.
  ///
  /// Similar to [recover] but [recovery] returns a [Future].
  Future<Result<T>> recoverAsync(
    Future<T> Function(Exception error) recovery,
  ) async {
    final result = await this;
    return switch (result) {
      Ok() => result,
      Err(value: final e) => Ok(await recovery(e)),
    };
  }

  /// Recovers from an error by providing a replacement [Result].
  ///
  /// If this is [Ok], returns the value unchanged. If this is [Err], applies
  /// [recovery] to the error and returns the resulting [Result].
  Future<Result<T>> recoverWith(
    Result<T> Function(Exception error) recovery,
  ) async {
    final result = await this;
    return switch (result) {
      Ok() => result,
      Err(value: final e) => recovery(e),
    };
  }

  /// Asynchronously recovers from an error with a replacement [Result].
  ///
  /// Similar to [recoverWith] but [recovery] returns a [Future<Result<T>>].
  Future<Result<T>> recoverWithAsync(
    Future<Result<T>> Function(Exception error) recovery,
  ) async {
    final result = await this;
    return switch (result) {
      Ok() => result,
      Err(value: final e) => await recovery(e),
    };
  }

  /// Adds a timeout to this [FutureResult].
  ///
  /// If the future doesn't complete within [duration], returns the result of
  /// [onTimeout] (or a default timeout error if not provided).
  Future<Result<T>> withTimeout(
    Duration duration, {
    Result<T> Function()? onTimeout,
  }) {
    return timeout(
      duration,
      onTimeout: onTimeout ?? () => Err(Exception('Operation timed out')),
    );
  }
}

/// Factory methods for creating [FutureResult]s.
extension FutureResultFactory on Future<Never> {
  /// Creates a [FutureResult] with a successful value.
  static Future<Result<T>> ok<T>(T value) => Future.value(Ok(value));

  /// Creates a [FutureResult] with an error.
  static Future<Result<T>> err<T>(Exception error, [StackTrace? stackTrace]) =>
      Future.value(Err<T>(error, stackTrace));

  /// Wraps a [Future] in a try-catch and converts it to a [FutureResult].
  ///
  /// If the future completes successfully, returns [Ok] with the value.
  /// If it throws an exception, returns [Err] with the exception.
  static Future<Result<T>> from<T>(Future<T> future) async {
    try {
      final value = await future;
      return Ok(value);
    } catch (e, stackTrace) {
      return Err(e is Exception ? e : Exception(e.toString()), stackTrace);
    }
  }
}

/// Utility class for working with collections of [FutureResult]s.
abstract class FutureResultList {
  const FutureResultList._();

  /// Waits for all [FutureResult]s to complete and returns a list of results.
  ///
  /// Similar to [Future.wait], this waits for all futures to complete and
  /// returns their results (both [Ok] and [Err] values).
  static Future<List<Result<T>>> waitAll<T>(
    Iterable<Future<Result<T>>> futureResults,
  ) {
    return Future.wait(futureResults);
  }

  /// Waits for all [FutureResult]s and returns [Ok] with list if all succeed.
  ///
  /// If all results are [Ok], returns [Ok] with a list of all values.
  /// If any result is [Err], immediately returns that first error.
  static Future<Result<List<T>>> waitAllOrError<T>(
    Iterable<Future<Result<T>>> futureResults,
  ) async {
    if (futureResults.isEmpty) return const Ok([]);

    final results = await waitAll(futureResults);
    final values = <T>[];

    for (final result in results) {
      switch (result) {
        case Ok(value: final v):
          values.add(v);
        case Err(:final value, :final stackTrace):
          return Err(value, stackTrace);
      }
    }

    return Ok(values);
  }

  /// Returns the first [FutureResult] that completes with [Ok].
  ///
  /// If all futures complete with [Err], returns an [Err] containing
  /// information about all failures.
  static Future<Result<T>> any<T>(
    Iterable<Future<Result<T>>> futureResults,
  ) async {
    final futures = futureResults.toList();
    if (futures.isEmpty) {
      return Err(Exception('No future results provided'));
    }

    final errors = <Exception>[];

    for (final future in futures) {
      try {
        final result = await future;
        if (result case Ok()) {
          return result;
        } else if (result case Err(value: final e)) {
          errors.add(e);
        }
      } catch (e) {
        errors.add(e is Exception ? e : Exception(e.toString()));
      }
    }

    return Err(Exception('All futures failed: ${errors.join(", ")}'));
  }
}
