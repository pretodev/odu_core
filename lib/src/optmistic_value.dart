import 'dart:async';

import 'result.dart';

typedef OptimisticTask<R> = Task<R> Function();
typedef OptimisticUpdater<T> = T Function(T currentState);

class OptimisticValue<T> {
  Stream<T> source;

  OptimisticValue(this.source);

  final _optimisticController = StreamController<T>.broadcast();
  T? _state;

  void dispose() {
    _optimisticController.close();
  }

  Stream<T> get stream {
    source = source.map((data) {
      _state = data;
      return data;
    });
    return Stream.multi((controller) {
      final sourceSubscription = source.listen(
        (data) => controller.add(data),
        onError: (error, stackTrace) => controller.addError(error, stackTrace),
      );

      final optimisticSubscription = _optimisticController.stream.listen(
        (data) => controller.add(data),
        onError: (error, stackTrace) => controller.addError(error, stackTrace),
      );

      controller.onCancel = () {
        sourceSubscription.cancel();
        optimisticSubscription.cancel();
      };
    });
  }

  Task<R> update<R>(
    OptimisticTask<R> task,
    OptimisticUpdater<T> updater,
  ) async {
    if (_state == null) {
      return .error(Exception('Estado não inicializado'), .current);
    }

    final previousState = _state as T;
    final newState = updater(previousState);

    _state = newState;
    _optimisticController.add(newState);

    final result = await task();
    if (result is Error) {
      _state = previousState;
      _optimisticController.add(previousState);
    }
    return result;
  }
}

class ListReplacer<T> {
  final List<T> _items;

  ListReplacer(this._items);

  List<T> replace(T item, bool Function(T) predicate) {
    final index = _items.indexWhere(predicate);
    if (index >= 0) {
      _items[index] = item;
      return _items;
    }
    return [..._items, item];
  }
}