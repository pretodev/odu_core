part of 'fp.dart';

/// Type alias for [Future<Result<T>>] providing a concise type for async results.
///
/// Example:
/// ```dart
/// FutureResult<User> fetchUser(String id) async {
///   final response = await http.get('/users/$id');
///   if (response.statusCode == 200) {
///     return Ok(User.fromJson(response.body));
///   }
///   return Err(UserNotFoundFailure(debugDetails: 'HTTP ${response.statusCode}'));
/// }
///
/// // Chaining operations
/// FutureResult<String> getUserName(String id) {
///   return fetchUser(id)
///     .map((user) => user.name)
///     .recover((failure) => 'Unknown User');
/// }
/// ```
typedef FutureResult<T> = Future<Result<T>>;

/// Extension methods for [Future<Result<T>>] providing ergonomic async utilities.
extension FutureResultExtension<T> on Future<Result<T>> {
  /// Transforms the success value using [transform].
  ///
  /// If this is [Ok], applies [transform] to the value and returns [Ok] with
  /// the transformed value. If this is [Err], returns the failure unchanged.
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
      Err(failure: final f, stackTrace: final s) => Err(f, s),
    };
  }

  /// Transforms the failure using [transform].
  ///
  /// If this is [Err], applies [transform] to the failure and returns [Err]
  /// with the transformed failure. If this is [Ok], returns the value unchanged.
  Future<Result<T>> mapErr(Failure Function(Failure failure) transform) async {
    final result = await this;
    return result.mapErr(transform);
  }

  /// Asynchronously transforms the failure using [transform].
  ///
  /// Similar to [mapErr] but [transform] returns a [Future].
  Future<Result<T>> mapErrAsync(
    Future<Failure> Function(Failure failure) transform,
  ) async {
    final result = await this;
    return switch (result) {
      Ok(value: final v) => Ok(v),
      Err(failure: final f, stackTrace: final s) => Err(await transform(f), s),
    };
  }

  /// Applies [transform] to the success value and flattens the result.
  ///
  /// If this is [Ok], applies [transform] to the value (which returns a
  /// [Result]) and returns that result. If this is [Err], returns the failure.
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
      Err(failure: final f, stackTrace: final s) => Err(f, s),
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

  /// Extracts the value from [Ok] or computes a value from the failure.
  ///
  /// If this is [Ok], returns the value. If this is [Err], applies [orElse]
  /// to the failure and returns the result.
  Future<T> unwrapOrElse(T Function(Failure failure) orElse) async {
    final result = await this;
    return result.unwrapOrElse(orElse);
  }

  /// Asynchronously extracts the value or computes a value from the failure.
  ///
  /// Similar to [unwrapOrElse] but [orElse] returns a [Future].
  Future<T> unwrapOrElseAsync(
    Future<T> Function(Failure failure) orElse,
  ) async {
    final result = await this;
    return switch (result) {
      Ok(value: final v) => v,
      Err(failure: final f) => await orElse(f),
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
  /// the same value. If this is [Err], returns the failure unchanged.
  Future<Result<T>> inspect(void Function(T value) inspector) async {
    final result = await this;
    if (result case Ok(value: final v)) {
      inspector(v);
    }
    return result;
  }

  /// Calls [inspector] with the failure without modifying the result.
  ///
  /// If this is [Err], calls [inspector] with the failure and returns [Err]
  /// with the same failure. If this is [Ok], returns the value unchanged.
  Future<Result<T>> inspectErr(void Function(Failure failure) inspector) async {
    final result = await this;
    if (result case Err(failure: final f)) {
      inspector(f);
    }
    return result;
  }

  /// Recovers from a failure by providing a replacement value.
  ///
  /// If this is [Ok], returns the value unchanged. If this is [Err], applies
  /// [recovery] to the failure and returns [Ok] with the result.
  Future<Result<T>> recover(T Function(Failure failure) recovery) async {
    final result = await this;
    return switch (result) {
      Ok() => result,
      Err(failure: final f) => Ok(recovery(f)),
    };
  }

  /// Asynchronously recovers from a failure by providing a replacement value.
  ///
  /// Similar to [recover] but [recovery] returns a [Future].
  Future<Result<T>> recoverAsync(
    Future<T> Function(Failure failure) recovery,
  ) async {
    final result = await this;
    return switch (result) {
      Ok() => result,
      Err(failure: final f) => Ok(await recovery(f)),
    };
  }

  /// Recovers from a failure by providing a replacement [Result].
  ///
  /// If this is [Ok], returns the value unchanged. If this is [Err], applies
  /// [recovery] to the failure and returns the resulting [Result].
  Future<Result<T>> recoverWith(
    Result<T> Function(Failure failure) recovery,
  ) async {
    final result = await this;
    return switch (result) {
      Ok() => result,
      Err(failure: final f) => recovery(f),
    };
  }

  /// Asynchronously recovers from a failure with a replacement [Result].
  ///
  /// Similar to [recoverWith] but [recovery] returns a [Future<Result<T>>].
  Future<Result<T>> recoverWithAsync(
    Future<Result<T>> Function(Failure failure) recovery,
  ) async {
    final result = await this;
    return switch (result) {
      Ok() => result,
      Err(failure: final f) => await recovery(f),
    };
  }

  /// Adds a timeout to this [FutureResult].
  ///
  /// If the future doesn't complete within [duration], returns the result of
  /// [onTimeout] (or a default timeout error if not provided).
  Future<Result<T>> withTimeout(
    Duration duration, {
    Result<T> Function()? onTimeout,
  }) => timeout(
    duration,
    onTimeout: onTimeout ?? () => Err(ResultTimeoutFailure(duration: duration)),
  );
}

/// Utilities for working with collections of [FutureResult] values.
abstract final class const FutureResultList._() {
  /// Waits for all futures and accumulates every failure.
  ///
  /// This mirrors [ResultList.zipAccumulate] for async computations.
  static Future<Result<List<T>>> zipAccumulate<T>(
    Iterable<FutureResult<T>> futureResults, {
    Failure Function(List<Failure> failures)? onFailure,
  }) async {
    final results = await Future.wait(futureResults);
    return ResultList.zipAccumulate(results, onFailure: onFailure);
  }
}

/// Factory methods for creating [FutureResult]s.
extension FutureResultFactory on Future<Never> {
  /// Creates a [FutureResult] with a successful value.
  static Future<Result<T>> ok<T>(T value) => Future.value(Ok(value));

  /// Creates a [FutureResult] with a failure.
  static Future<Result<T>> err<T>(Failure failure, [StackTrace? stackTrace]) =>
      Future.value(Err<T>(failure, stackTrace));
}

// ---------------------------------------------------------------------------
// Internal failures used only by FutureResult utilities
// ---------------------------------------------------------------------------

class ResultTimeoutFailure({required Duration duration}) extends Failure {
  this
    : super(
        'A operação excedeu o tempo limite.',
        debugDetails: 'Timeout after $duration',
      );
}
