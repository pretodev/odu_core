import 'dart:async';

import 'option.dart';
import 'result.dart';

/// Type alias for [Future<Option<T>>] providing a concise type for async options.
///
/// Example:
/// ```dart
/// FutureOption<User> findUserByEmail(String email) async {
///   final users = await database.query(
///     'SELECT * FROM users WHERE email = ?',
///     [email],
///   );
///   if (users.isEmpty) {
///     return const None();
///   }
///   return Some(User.fromRow(users.first));
/// }
///
/// // Convert to Result
/// FutureResult<User> getUserOrError(String email) {
///   return findUserByEmail(email)
///     .okOr(Exception('User not found'));
/// }
///
/// // Filter pattern
/// FutureOption<User> findActiveUser(String email) {
///   return findUserByEmail(email)
///     .filter((user) => user.isActive);
/// }
/// ```
typedef FutureOption<T> = Future<Option<T>>;

/// Extension methods for [Future<Option<T>>] providing ergonomic async utilities.
extension FutureOptionExtension<T> on Future<Option<T>> {
  /// Transforms the [Some] value using [transform].
  ///
  /// If this is [Some], applies [transform] to the value and returns [Some]
  /// with the transformed value. If this is [None], returns [None].
  Future<Option<U>> map<U>(U Function(T value) transform) async {
    final option = await this;
    return option.map(transform);
  }

  /// Asynchronously transforms the [Some] value using [transform].
  ///
  /// Similar to [map] but [transform] returns a [Future].
  Future<Option<U>> mapAsync<U>(Future<U> Function(T value) transform) async {
    final option = await this;
    return switch (option) {
      Some(value: final v) => Some(await transform(v)),
      None() => const None(),
    };
  }

  /// Applies [transform] to the [Some] value and flattens the result.
  ///
  /// If this is [Some], applies [transform] to the value (which returns an
  /// [Option]) and returns that option. If this is [None], returns [None].
  Future<Option<U>> flatMap<U>(Option<U> Function(T value) transform) async {
    final option = await this;
    return switch (option) {
      Some(value: final v) => transform(v),
      None() => const None(),
    };
  }

  /// Asynchronously applies [transform] to the [Some] value and flattens.
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

  /// Asynchronously extracts the value or computes a default.
  ///
  /// If this is [Some], returns the value. If this is [None], applies [orElse]
  /// and returns the result.
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

  /// Calls [inspector] with the [Some] value without modifying the option.
  ///
  /// If this is [Some], calls [inspector] with the value and returns [Some]
  /// with the same value. If this is [None], returns [None] unchanged.
  Future<Option<T>> inspect(void Function(T value) inspector) async {
    final option = await this;
    if (option case Some(value: final v)) {
      inspector(v);
    }
    return option;
  }

  /// Converts this [FutureOption] to a [Future<Result<T>>].
  ///
  /// [Some] becomes [Ok] and [None] becomes [Err] with the provided [error].
  Future<Result<T>> okOr(Exception error) async {
    final option = await this;
    return option.okOr(error);
  }

  /// Converts this [FutureOption] to a [Future<Result<T>>] with a lazy error.
  ///
  /// Similar to [okOr] but [errorProvider] is only called if this is [None].
  Future<Result<T>> okOrElse(Exception Function() errorProvider) async {
    final option = await this;
    return switch (option) {
      Some(value: final v) => Ok(v),
      None() => Err(errorProvider()),
    };
  }

  /// Converts this [FutureOption] to a [Future<T?>].
  ///
  /// [Some] becomes the value and [None] becomes null.
  Future<T?> toNullable() async {
    final option = await this;
    return switch (option) {
      Some(value: final v) => v,
      None() => null,
    };
  }

  /// Filters the [Some] value using [predicate].
  ///
  /// If this is [Some] and [predicate] returns true, returns [Some] with the
  /// value. Otherwise, returns [None].
  Future<Option<T>> filter(bool Function(T value) predicate) async {
    final option = await this;
    return switch (option) {
      Some(value: final v) when predicate(v) => Some(v),
      _ => const None(),
    };
  }

  /// Asynchronously filters the [Some] value using [predicate].
  ///
  /// Similar to [filter] but [predicate] returns a [Future].
  Future<Option<T>> filterAsync(
    Future<bool> Function(T value) predicate,
  ) async {
    final option = await this;
    return switch (option) {
      Some(value: final v) when await predicate(v) => Some(v),
      _ => const None(),
    };
  }

  /// Adds a timeout to this [FutureOption].
  ///
  /// If the future doesn't complete within [duration], returns the result of
  /// [onTimeout] (or [None] if not provided).
  Future<Option<T>> withTimeout(
    Duration duration, {
    Option<T> Function()? onTimeout,
  }) {
    return timeout(
      duration,
      onTimeout: onTimeout ?? () => const None(),
    );
  }
}

/// Factory methods for creating [FutureOption]s.
extension FutureOptionFactory on Future<Never> {
  /// Creates a [FutureOption] with a [Some] value.
  static Future<Option<T>> some<T>(T value) => Future.value(Some(value));

  /// Creates a [FutureOption] with a [None] value.
  static Future<Option<T>> none<T>() {
    return Future.value(None<T>());
  }

  /// Converts a [Future<T?>] to a [FutureOption].
  ///
  /// If the future completes with a non-null value, returns [Some] with that
  /// value. If it completes with null, returns [None].
  static Future<Option<T>> from<T>(Future<T?> future) async {
    final value = await future;
    return value != null ? Some(value) : const None();
  }
}
