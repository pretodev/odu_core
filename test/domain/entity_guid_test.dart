import 'package:odu_core/odu_core.dart';
import 'package:test/test.dart';

void main() {
  group('GuidId', () {
    test('generates a valid UUID when no value is supplied', () {
      final id = GuidId();

      expect(id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(GuidId(id), id);
    });

    test('rejects an invalid UUID', () {
      expect(() => GuidId('invalid'), throwsArgumentError);
    });

    test('creates deterministic seeded identifiers', () {
      expect(GuidId.seeded('customer-1'), GuidId.seeded('customer-1'));
      expect(GuidId.seeded('customer-1'), isNot(GuidId.seeded('customer-2')));
    });
  });

  group('Entity', () {
    test('uses its identifier for value equality', () {
      final id = GuidId.seeded('same-entity');

      expect(_Entity(id, 'first'), _Entity(id, 'second'));
      expect(
        _Entity(id, 'first'),
        isNot(_Entity(GuidId.seeded('other-entity'), 'first')),
      );
    });
  });
}

final class const _Entity(GuidId id, final String name) extends Entity {
  this : super(id: id);
}
