import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/// Declared instance fields in source order.
List<FieldElement> declaredInstanceFields(ClassDeclaration declaration) {
  final fields = declaration.declaredFragment!.element.fields
      .where((field) => !field.isStatic && !field.isOriginEnumValues)
      .toList();
  fields.sort(
    (left, right) =>
        left.firstFragment.offset.compareTo(right.firstFragment.offset),
  );
  return fields;
}

List<ClassMember> classMembers(ClassBody body) => switch (body) {
  BlockClassBody(:final members) => members,
  EmptyClassBody() => const <ClassMember>[],
};
