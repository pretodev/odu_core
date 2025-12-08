import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

part 'equatable.dart';

/// Base class for domain entities with identity and change tracking.
///
/// Domain entities have a unique identity and lifecycle timestamps.
/// Extend this class and populate `uniqueProps` with properties that define
/// uniqueness beyond the ID.
///
/// Example:
/// ```dart
/// class User extends Entity {
///   final String email;
///   final String name;
///
///   User({super.id, required this.email, required this.name}) {
///     uniqueProps = [email, name];
///   }
/// }
///
/// final user1 = User(email: 'alice@example.com', name: 'Alice');
/// final user2 = User(id: user1.id, email: 'alice@example.com', name: 'Alice');
/// print(user1 == user2); // true - same id and properties
/// ```
abstract class Entity {
  final String id;
  final DateTime? _createdAt;
  final DateTime? _updatedAt;

  Entity({String? id, DateTime? createdAt, DateTime? updatedAt})
    : id = id ?? const Uuid().v4(),
      _createdAt = createdAt ?? DateTime.now(),
      _updatedAt = updatedAt ?? DateTime.now();

  bool _changed = false;

  /// Indicates whether this entity has been marked as changed.
  ///
  /// Returns `true` if [markAsChanged] has been called, `false` otherwise.
  bool get hasChanged => _changed;

  /// The timestamp when this entity was created.
  ///
  /// Throws a [StateError] if createdAt was not set during construction.
  DateTime get createdAt {
    if (_createdAt == null) {
      throw StateError('Entity does not have createdAt set');
    }
    return _createdAt;
  }

  /// The timestamp when this entity was last updated.
  ///
  /// Throws a [StateError] if updatedAt was not set during construction.
  DateTime get updatedAt {
    if (_updatedAt == null) {
      throw StateError('Entity does not have updatedAt set');
    }
    return _updatedAt;
  }

  /// Marks this entity as changed.
  ///
  /// Use this to track when an entity has been modified during its lifecycle.
  /// After calling this, [hasChanged] will return `true`.
  void markAsChanged() {
    _changed = true;
  }

  /// Properties that define uniqueness for this entity beyond the [id].
  ///
  /// Populate this list in your subclass constructor with properties that
  /// should be considered when comparing entities for equality.
  List<Object?> uniqueProps = [];

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Entity &&
            runtimeType == other.runtimeType &&
            iterableEquals(
              [id, _createdAt, _updatedAt, ...uniqueProps],
              [
                other.id,
                other._createdAt,
                other._updatedAt,
                ...other.uniqueProps,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([id, _createdAt, _updatedAt, ...uniqueProps]);

  @override
  String toString() {
    final props = [id, ...uniqueProps];
    return '$runtimeType(${props.map((prop) => prop.toString()).join(', ')})';
  }
}
