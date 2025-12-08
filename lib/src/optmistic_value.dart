import 'dart:async';

import 'result.dart';

typedef OptimisticTask<R> = Task<R> Function();
typedef OptimisticUpdater<T> = T Function(T currentState);

/// Wraps a stream with optimistic updates that emit immediately while tasks complete.
///
/// This class allows you to update UI optimistically before a server request completes.
/// If the request fails, the previous state is automatically restored.
///
/// Example:
/// ```dart
/// final userStream = Stream.fromIterable([initialUser]);
/// final optimisticUser = OptimisticValue(userStream);
///
/// // Listen to changes
/// optimisticUser.stream.listen((user) {
///   print('Current user: ${user.name}');
/// });
///
/// // Update optimistically
/// await optimisticUser.update(
///   () => updateUserOnServer(newUser),
///   (currentUser) => newUser, // Immediate UI update
/// );
/// ```
class OptimisticValue<T> {
  Stream<T> source;

  OptimisticValue(this.source);

  final _optimisticController = StreamController<T>.broadcast();
  T? _state;

  /// Closes the internal stream controller.
  ///
  /// Call this when you're done using this [OptimisticValue] to free resources.
  void dispose() {
    _optimisticController.close();
  }

  /// Returns a stream that emits both source values and optimistic updates.
  ///
  /// The stream combines data from the original [source] and any optimistic
  /// updates made via [update]. Subscribe to this stream to react to changes.
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

  /// Performs an optimistic update by applying [updater] immediately, then executing [task].
  ///
  /// The [updater] function receives the current state and returns the new state.
  /// The new state is emitted immediately for optimistic UI updates.
  ///
  /// The [task] is then executed asynchronously. If it returns an [Error],
  /// the state is rolled back to the previous value.
  ///
  /// Returns the [Result] from the [task] execution.
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

/// Helper to replace or append items in a list based on a predicate match.
///
/// Use this to update an item in a list if it exists, or add it if it doesn't.
///
/// Example:
/// ```dart
/// final items = [User(id: '1', name: 'Alice'), User(id: '2', name: 'Bob')];
/// final replacer = ListReplacer(items);
///
/// final updatedItems = replacer.replace(
///   User(id: '2', name: 'Bobby'),
///   (user) => user.id == '2',
/// );
/// // Result: [User(id: '1', name: 'Alice'), User(id: '2', name: 'Bobby')]
/// ```
class ListReplacer<T> {
  final List<T> _items;

  ListReplacer(this._items);

  /// Replaces the first item matching [predicate] with [item], or appends [item] if no match.
  ///
  /// Returns a new list with the item replaced or appended.
  List<T> replace(T item, bool Function(T) predicate) {
    final index = _items.indexWhere(predicate);
    if (index >= 0) {
      _items[index] = item;
      return _items;
    }
    return [..._items, item];
  }
}
