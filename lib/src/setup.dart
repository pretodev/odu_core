import 'result.dart';
import 'task.dart';

abstract interface class SetupTask {
  Task<Unit> call();
}

Future<void> setup(List<SetupTask> tasks) async {
  final results = await TaskList.waitAll(tasks.map((e) => e()));
  if (results.any((e) => e is Error)) {
    throw SetupException('Setup failed', results.first as Error);
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
