import 'dart:async';

import 'future_result.dart';
import 'result.dart';

/// Type alias for a future that resolves to a [Result].
///
/// **Deprecated:** Use [FutureResult] instead.
///
/// ```dart
/// FutureResult<int> fetchData() async {
///   return Ok(42);
/// }
/// ```
@Deprecated('Use FutureResult instead. Will be removed in a future version.')
typedef Task<T> = FutureResult<T>;

/// Utility class to wait for multiple tasks to complete.
///
/// **Deprecated:** Use [FutureResultList] instead.
@Deprecated('Use FutureResultList instead. Will be removed in a future version.')
abstract class TaskList {
  const TaskList._();

  /// Waits for all tasks to complete and returns a list of results.
  ///
  /// If any task throws an error, the returned future completes with an error.
  ///
  /// **Deprecated:** Use [FutureResultList.waitAll] instead.
  @Deprecated('Use FutureResultList.waitAll instead.')
  static Future<List<Result<T>>> waitAll<T>(Iterable<Task<T>> tasks) {
    return FutureResultList.waitAll(tasks);
  }

  /// Waits for all tasks to complete and returns a list of results.
  ///
  /// If any task throws an error, the returned future completes with an error.
  ///
  /// **Deprecated:** Use [FutureResultList.waitAllOrError] instead.
  @Deprecated('Use FutureResultList.waitAllOrError instead.')
  static Task<List<T>> waitAllOrError<T>(Iterable<Task<T>> tasks) {
    return FutureResultList.waitAllOrError(tasks);
  }
}
