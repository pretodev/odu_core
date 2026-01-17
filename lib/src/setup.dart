import 'future_result.dart';
import 'result.dart';

abstract interface class SetupTask {
  FutureResult<Unit> call();
}

class ParallelSetup implements SetupTask {
  const ParallelSetup(this.tasks);

  final Iterable<SetupTask> tasks;

  @override
  FutureResult<Unit> call() async {
    final results = await FutureResultList.waitAll<Unit>(tasks.map((e) => e()));
    for (final result in results) {
      if (result is Err) {
        return result;
      }
    }
    return ok;
  }
}

Future<void> setup(List<SetupTask> tasks) async {
  for (final task in tasks) {
    final result = await task();
    if (result is Err) {
      throw SetupException('Setup failed', result as Error);
    }
  }
}

class SetupException implements Exception {
  const SetupException(this.message, [this.error]);

  final String message;
  final Error? error;

  @override
  String toString() =>
      'SetupException: $message${error != null ? '\n$error' : ''}';
}
