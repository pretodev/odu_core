import 'package:odu_core/odu_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final invalidState = AsyncError(
  StateError('Not called yet'),
  StackTrace.current,
);

mixin CommandMixin<T> on $Notifier<AsyncValue<T>> {
  Result<T> setError<E extends Exception>(E error, [StackTrace? stackTrace]) {
    if (ref.mounted) {
      state = AsyncError(error, stackTrace ?? StackTrace.current);
    }
    return Err(error, stackTrace);
  }

  Result<T> setData(T data) {
    if (ref.mounted) {
      state = AsyncData(data);
    }
    return Ok(data);
  }

  void setLoading() {
    if (ref.mounted) {
      state = const AsyncLoading();
    }
  }
}
