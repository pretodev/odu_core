import 'package:odu_core/odu_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

// Test entity implementation
class TestEntity extends Entity<String> {
  final String name;
  final int value;

  TestEntity._({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.name,
    required this.value,
  });

  factory TestEntity({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    required String name,
    required int value,
  }) {
    final now = DateTime.now();
    return TestEntity._(
      id: id ?? const Uuid().v4(),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      name: name,
      value: value,
    );
  }

  @override
  List<Object?> get props => [name, value];

  TestEntity copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    int? value,
  }) {
    return TestEntity._(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }
}

// Entity with nested collections
class ComplexEntity extends Entity<String> {
  final List<String> tags;
  final Map<String, int> scores;
  final Set<String> categories;

  ComplexEntity._({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.tags,
    required this.scores,
    required this.categories,
  });

  factory ComplexEntity({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    required List<String> tags,
    required Map<String, int> scores,
    required Set<String> categories,
  }) {
    final now = DateTime.now();
    return ComplexEntity._(
      id: id ?? const Uuid().v4(),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      tags: tags,
      scores: scores,
      categories: categories,
    );
  }

  @override
  List<Object?> get props => [tags, scores, categories];
}

void main() {
  group('Entity', () {
    group('ID generation', () {
      test('generates UUID v4 when no ID provided', () {
        final entity = TestEntity(name: 'test', value: 42);
        expect(entity.id, isNotEmpty);
        expect(entity.id.length, equals(36)); // UUID v4 format
      });

      test('uses provided ID when given', () {
        const customId = 'custom-id-123';
        final entity = TestEntity(id: customId, name: 'test', value: 42);
        expect(entity.id, equals(customId));
      });

      test('generates different IDs for different instances', () {
        final entity1 = TestEntity(name: 'test', value: 42);
        final entity2 = TestEntity(name: 'test', value: 42);
        expect(entity1.id, isNot(equals(entity2.id)));
      });
    });

    group('Timestamps', () {
      test('sets createdAt to now when not provided', () {
        final before = DateTime.now();
        final entity = TestEntity(name: 'test', value: 42);
        final after = DateTime.now();

        expect(
          entity.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          entity.createdAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );
      });

      test('sets updatedAt to now when not provided', () {
        final before = DateTime.now();
        final entity = TestEntity(name: 'test', value: 42);
        final after = DateTime.now();

        expect(
          entity.updatedAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          entity.updatedAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );
      });

      test('uses provided timestamps when given', () {
        final created = DateTime(2024, 1, 1);
        final updated = DateTime(2024, 1, 2);
        final entity = TestEntity(
          name: 'test',
          value: 42,
          createdAt: created,
          updatedAt: updated,
        );

        expect(entity.createdAt, equals(created));
        expect(entity.updatedAt, equals(updated));
      });
    });

    group('Change tracking', () {
      test('hasChanged is false when createdAt equals updatedAt', () {
        final now = DateTime.now();
        final entity = TestEntity(
          name: 'test',
          value: 42,
          createdAt: now,
          updatedAt: now,
        );
        expect(entity.hasChanged, isFalse);
      });

      test('hasChanged is true when updatedAt is after createdAt', () {
        final created = DateTime(2024, 1, 1);
        final updated = DateTime(2024, 1, 2);
        final entity = TestEntity(
          name: 'test',
          value: 42,
          createdAt: created,
          updatedAt: updated,
        );
        expect(entity.hasChanged, isTrue);
      });

      test('hasChanged is false when updatedAt is before createdAt', () {
        final created = DateTime(2024, 1, 2);
        final updated = DateTime(2024, 1, 1);
        final entity = TestEntity(
          name: 'test',
          value: 42,
          createdAt: created,
          updatedAt: updated,
        );
        expect(entity.hasChanged, isFalse);
      });
    });

    group('Equality', () {
      test('entities with same properties are equal', () {
        const id = 'same-id';
        final created = DateTime(2024, 1, 1);
        final updated = DateTime(2024, 1, 2);

        final entity1 = TestEntity(
          id: id,
          createdAt: created,
          updatedAt: updated,
          name: 'test',
          value: 42,
        );

        final entity2 = TestEntity(
          id: id,
          createdAt: created,
          updatedAt: updated,
          name: 'test',
          value: 42,
        );

        expect(entity1, equals(entity2));
        expect(entity1 == entity2, isTrue);
      });

      test('entities with different IDs are not equal', () {
        final created = DateTime(2024, 1, 1);
        final entity1 = TestEntity(
          id: 'id1',
          createdAt: created,
          name: 'test',
          value: 42,
        );
        final entity2 = TestEntity(
          id: 'id2',
          createdAt: created,
          name: 'test',
          value: 42,
        );

        expect(entity1, isNot(equals(entity2)));
      });

      test('entities with same ID but different props are equal', () {
        const id = 'same-id';
        final created = DateTime(2024, 1, 1);

        final entity1 = TestEntity(
          id: id,
          createdAt: created,
          name: 'test1',
          value: 42,
        );

        final entity2 = TestEntity(
          id: id,
          createdAt: created,
          name: 'test2',
          value: 42,
        );

        // Entities are equal based on ID only (DDD identity)
        expect(entity1, equals(entity2));
      });

      test('identical entities are equal', () {
        final entity = TestEntity(name: 'test', value: 42);
        expect(entity, equals(entity));
        expect(identical(entity, entity), isTrue);
      });

      test('entities with same ID are equal regardless of nested collections', () {
        const id = 'same-id';
        final created = DateTime(2024, 1, 1);
        final updated = DateTime(2024, 1, 2);

        final entity1 = ComplexEntity(
          id: id,
          createdAt: created,
          updatedAt: updated,
          tags: ['a', 'b', 'c'],
          scores: {'x': 1, 'y': 2},
          categories: {'cat1', 'cat2'},
        );

        final entity2 = ComplexEntity(
          id: id,
          createdAt: created,
          updatedAt: updated,
          tags: ['d', 'e', 'f'],
          scores: {'m': 99},
          categories: {'cat3'},
        );

        // Entities are equal based on ID only (DDD identity)
        expect(entity1 == entity2, isTrue);
      });

      test('entities with different IDs are not equal even with same nested lists', () {
        const id1 = 'id-1';
        const id2 = 'id-2';
        final created = DateTime(2024, 1, 1);
        final updated = DateTime(2024, 1, 2);

        final entity1 = ComplexEntity(
          id: id1,
          createdAt: created,
          updatedAt: updated,
          tags: ['a', 'b', 'c'],
          scores: {},
          categories: {},
        );

        final entity2 = ComplexEntity(
          id: id2,
          createdAt: created,
          updatedAt: updated,
          tags: ['a', 'b', 'c'],
          scores: {},
          categories: {},
        );

        expect(entity1, isNot(equals(entity2)));
      });
    });

    group('HashCode', () {
      test('equal entities have same hashCode', () {
        const id = 'same-id';
        final created = DateTime(2024, 1, 1);
        final updated = DateTime(2024, 1, 2);

        final entity1 = TestEntity(
          id: id,
          createdAt: created,
          updatedAt: updated,
          name: 'test',
          value: 42,
        );

        final entity2 = TestEntity(
          id: id,
          createdAt: created,
          updatedAt: updated,
          name: 'test',
          value: 42,
        );

        expect(entity1.hashCode, equals(entity2.hashCode));
      });

      test('different entities have different hashCodes', () {
        final entity1 = TestEntity(name: 'test1', value: 42);
        final entity2 = TestEntity(name: 'test2', value: 43);

        expect(entity1.hashCode, isNot(equals(entity2.hashCode)));
      });

      test('hashCode is consistent across calls', () {
        final entity = TestEntity(name: 'test', value: 42);
        final hash1 = entity.hashCode;
        final hash2 = entity.hashCode;

        expect(hash1, equals(hash2));
      });

      test('entities can be used in Sets', () {
        const id1 = 'id1';
        const id2 = 'id2';
        final created = DateTime(2024, 1, 1);
        final updated = DateTime(2024, 1, 2);

        final entity1a = TestEntity(
          id: id1,
          createdAt: created,
          updatedAt: updated,
          name: 'test',
          value: 42,
        );

        final entity1b = TestEntity(
          id: id1,
          createdAt: created,
          updatedAt: updated,
          name: 'test',
          value: 42,
        );

        final entity2 = TestEntity(
          id: id2,
          createdAt: created,
          updatedAt: updated,
          name: 'test',
          value: 42,
        );

        final set = {entity1a, entity1b, entity2};
        expect(set.length, equals(2)); // entity1a and entity1b are equal
      });

      test('entities can be used as Map keys', () {
        const id = 'same-id';
        final created = DateTime(2024, 1, 1);
        final updated = DateTime(2024, 1, 2);

        final entity1 = TestEntity(
          id: id,
          createdAt: created,
          updatedAt: updated,
          name: 'test',
          value: 42,
        );

        final entity2 = TestEntity(
          id: id,
          createdAt: created,
          updatedAt: updated,
          name: 'test',
          value: 42,
        );

        final map = {entity1: 'value1'};
        map[entity2] = 'value2';

        expect(map.length, equals(1)); // Same key
        expect(map[entity1], equals('value2'));
      });
    });

    group('toString', () {
      test('includes runtime type and properties', () {
        final entity = TestEntity(id: 'test-id', name: 'test', value: 42);
        final str = entity.toString();

        expect(str, contains('TestEntity'));
        expect(str, contains('test-id'));
        expect(str, contains('test'));
        expect(str, contains('42'));
      });
    });
  });
}
