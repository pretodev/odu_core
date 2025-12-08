import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

part 'equatable.dart';

abstract class Entity {
  final String id;
  final DateTime? _createdAt;
  final DateTime? _updatedAt;

  Entity({String? id, DateTime? createdAt, DateTime? updatedAt})
    : id = id ?? const Uuid().v4(),
      _createdAt = createdAt ?? DateTime.now(),
      _updatedAt = updatedAt ?? DateTime.now();

  bool _changed = false;
  bool get hasChanged => _changed;

  DateTime get createdAt {
    if (_createdAt == null) {
      throw StateError('Entity does not have createdAt set');
    }
    return _createdAt;
  }

  DateTime get updatedAt {
    if (_updatedAt == null) {
      throw StateError('Entity does not have updatedAt set');
    }
    return _updatedAt;
  }

  void markAsChanged() {
    _changed = true;
  }

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
