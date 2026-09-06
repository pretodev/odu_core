part of 'fp.dart';

/// Type alias for [Future<Option<T>>] providing a concise type for async options.
///
/// Example:
/// ```dart
/// FutureOption<User> findUser(String id) async {
///   final user = await database.query('SELECT * FROM users WHERE id = ?', [id]);
///   if (user != null) {
///     return Some(User.fromJson(user));
///   }
///   return const None();
/// }
///
/// // Chaining operations
/// FutureOption<String> getUserName(String id) {
///   return findUser(id).map((user) => user.name);
/// }
/// ```
typedef FutureOption<T> = Future<Option<T>>;

/// Extension methods for [Future<Option<T>>] providing ergonomic async utilities.
extension FutureOptionExtension<T> on Future<Option<T>> {
  /// Transforms the value using [transform].
  ///
  /// If this is [Some], applies [transform] to the value and returns [Some] with
  /// the transformed value. If this is [None], returns [None] unchanged.
  Future<Option<U>> map<U>(U Function(T value) transform) async {
    final option = await this;
    return option.map(transform);
  }

  /// Asynchronously transforms the value using [transform].
  ///
  /// Similar to [map] but [transform] returns a [Future].
  Future<Option<U>> mapAsync<U>(Future<U> Function(T value) transform) async {
    final option = await this;
    return await switch (option) {
      Some(value: final v) => Some(await transform(v)),
      None() => const None(),
    };
  }

  /// Applies [transform] to the value and flattens the result.
  ///
  /// If this is [Some], applies [transform] to the value (which returns an
  /// [Option]) and returns that option. If this is [None], returns [None].
  Future<Option<U>> flatMap<U>(Option<U> Function(T value) transform) async {
    final option = await this;
    return option.flatMap(transform);
  }

  /// Asynchronously applies [transform] to the value and flattens.
  ///
  /// Similar to [flatMap] but [transform] returns a [Future<Option<U>>].
  Future<Option<U>> flatMapAsync<U>(
    Future<Option<U>> Function(T value) transform,
  ) async {
    final option = await this;
    return switch (option) {
      Some(value: final v) => await transform(v),
      None() => const None(),
    };
  }

  /// Extracts the value from [Some] or throws a [StateError] if [None].
  Future<T> unwrap() async {
    final option = await this;
    return option.unwrap();
  }

  /// Extracts the value from [Some] or returns [defaultValue] if [None].
  Future<T> unwrapOr(T defaultValue) async {
    final option = await this;
    return option.unwrapOr(defaultValue);
  }

  /// Extracts the value from [Some] or computes a value.
  ///
  /// If this is [Some], returns the value. If this is [None], applies [orElse]
  /// and returns the result.
  Future<T> unwrapOrElse(T Function() orElse) async {
    final option = await this;
    return option.unwrapOrElse(orElse);
  }

  /// Asynchronously extracts the value or computes a value.
  ///
  /// Similar to [unwrapOrElse] but [orElse] returns a [Future].
  Future<T> unwrapOrElseAsync(Future<T> Function() orElse) async {
    final option = await this;
    return switch (option) {
      Some(value: final v) => v,
      None() => await orElse(),
    };
  }

  /// Returns whether this is [Some].
  Future<bool> isSome() async {
    final option = await this;
    return option.isSome;
  }

  /// Returns whether this is [None].
  Future<bool> isNone() async {
    final option = await this;
    return option.isNone;
  }

  /// Calls [inspector] with the value without modifying the option.
  ///
  /// If this is [Some], calls [inspector] with the value and returns [Some] with
  /// the same value. If this is [None], returns [None] unchanged.
  Future<Option<T>> inspect(void Function(T value) inspector) async {
    final option = await this;
    if (option case Some(value: final v)) {
      inspector(v);
    }
    return option;
  }

  /// Filters the option based on a predicate.
  ///
  /// If this is [Some] and [predicate] returns true, returns [Some] with the
  /// value. Otherwise, returns [None].
  Future<Option<T>> filter(bool Function(T value) predicate) async {
    final option = await this;
    return await switch (option) {
      Some(value: final v) => predicate(v) ? option : const None(),
      None() => option,
    };
  }

  /// Asynchronously filters the option based on a predicate.
  ///
  /// Similar to [filter] but [predicate] returns a [Future].
  Future<Option<T>> filterAsync(
    Future<bool> Function(T value) predicate,
  ) async {
    final option = await this;
    return await switch (option) {
      Some(value: final v) => (await predicate(v)) ? option : const None(),
      None() => option,
    };
  }

  /// Converts the option to a nullable value.
  Future<T?> toNullable() async {
    final option = await this;
    return option.toNullable();
  }

  /// Adds a timeout to this [FutureOption].
  ///
  /// If the future doesn't complete within [duration], returns the result of
  /// [onTimeout] (or [None] if not provided).
  Future<Option<T>> withTimeout(
    Duration duration, {
    Option<T> Function()? onTimeout,
  }) => timeout(duration, onTimeout: onTimeout ?? () => const None());
}

/// Factory methods for creating [FutureOption]s.
extension FutureOptionFactory on Future<Never> {
  /// Creates a [FutureOption] with a value.
  static Future<Option<T>> some<T>(T value) => Future.value(Some(value));

  /// Creates a [FutureOption] with no value.
  static Future<Option<T>> none<T>() => Future.value(const None());

  /// Creates a [FutureOption] from a nullable value.
  static Future<Option<T>> fromNullable<T>(T? value) =>
      Future.value(Option.fromNullable(value));
}

/// Utility class for working with collections of [FutureOption]s.
abstract final class const FutureOptionList._() {
  /// Waits for all [FutureOption]s to complete and returns a list of options.
  ///
  /// Similar to [Future.wait], this waits for all futures to complete and
  /// returns their options (both [Some] and [None] values).
  static Future<List<Option<T>>> waitAll<T>(
    Iterable<Future<Option<T>>> futureOptions,
  ) => Future.wait(futureOptions);

  /// Waits for all [FutureOption]s and returns [Some] with list if all have values.
  ///
  /// If all options are [Some], returns [Some] with a list of all values.
  /// If any option is [None], returns [None].
  static Future<Option<List<T>>> waitAllOrNone<T>(
    Iterable<Future<Option<T>>> futureOptions,
  ) async {
    if (futureOptions.isEmpty) {
      return const Some([]);
    }

    final options = await waitAll(futureOptions);
    final values = <T>[];

    for (final option in options) {
      switch (option) {
        case Some(value: final v):
          values.add(v);
        case None():
          return const None();
      }
    }

    return Some(values);
  }

  /// Returns the first [FutureOption] that completes with [Some].
  ///
  /// If all futures complete with [None], returns [None].
  static Future<Option<T>> any<T>(
    Iterable<Future<Option<T>>> futureOptions,
  ) async {
    final futures = futureOptions.toList();
    if (futures.isEmpty) {
      return const None();
    }

    for (final future in futures) {
      final option = await future;
      if (option case Some()) {
        return option;
      }
    }

    return const None();
  }

  /// Filters [FutureOption]s to collect only the [Some] values.
  ///
  /// Waits for all futures to complete and returns a list containing only
  /// the values from [Some] results, ignoring [None] results.
  static Future<List<T>> collectSome<T>(
    Iterable<Future<Option<T>>> futureOptions,
  ) async {
    final options = await waitAll(futureOptions);
    final values = <T>[];

    for (final option in options) {
      if (option case Some(value: final v)) {
        values.add(v);
      }
    }

    return values;
  }
}
