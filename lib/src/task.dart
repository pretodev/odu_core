import 'dart:async';

import 'result.dart';

/// Type alias for a future that resolves to a [Result].
///
/// ```dart
/// Task<int> fetchData() async {
///   return Result.data(42);
/// }
/// ```
typedef Task<T> = Future<Result<T>>;

/// Utility class to wait for multiple tasks to complete.
abstract class TaskList {
  const TaskList._();

  /// Waits for all tasks to complete and returns a list of results.
  ///
  /// If any task throws an error, the returned future completes with an error.
  static Future<List<Result<T>>> waitAll<T>(Iterable<Task<T>> tasks) {
    return Future.wait(tasks);
  }

  /// Waits for all tasks to complete and returns a list of results.
  ///
  /// If any task throws an error, the returned future completes with an error.
  static Task<List<T>> waitAllOrError<T>(Iterable<Task<T>> tasks) {
    if (tasks.isEmpty) return Future.value(const Ok([]));

    final completer = Completer<Result<List<T>>>();
    final results = List<T?>.filled(tasks.length, null);
    var pendingCount = tasks.length;
    var hasFailed = false;

    final taskList = tasks.toList();

    for (var i = 0; i < taskList.length; i++) {
      taskList[i].then((result) {
        if (hasFailed) return;

        switch (result) {
          case Err(value: final e, stackTrace: final s):
            hasFailed = true;
            if (!completer.isCompleted) {
              completer.complete(Err(e, s));
            }
          case Ok(value: final d):
            results[i] = d;
            pendingCount--;

            if (pendingCount == 0 && !completer.isCompleted) {
              completer.complete(Ok(results.cast<T>()));
            }
        }
      });
    }

    return completer.future;
  }
}
