import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

final class GeneratePropsAssist extends ResolvedCorrectionProducer {
  static const _kind = AssistKind(
    'odu.assist.generateProps',
    30,
    'Generate props',
  );

  GeneratePropsAssist({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null || !_supportsProps(declaration)) {
      return;
    }

    final fieldNames = declaredPropsFields(declaration);
    final body = declaration.body;
    final members = switch (body) {
      BlockClassBody(:final members) => members,
      EmptyClassBody() => const <ClassMember>[],
    };
    final getter = members
        .whereType<MethodDeclaration>()
        .where((member) => member.isGetter && member.name.lexeme == 'props')
        .firstOrNull;
    final generated = propsGetterSource(fieldNames);

    await builder.addDartFileEdit(file, (fileBuilder) {
      if (getter != null) {
        fileBuilder.addSimpleReplacement(
          range.node(getter),
          generated.trimRight(),
        );
      } else if (body is BlockClassBody) {
        fileBuilder.addSimpleInsertion(
          body.rightBracket.offset,
          '\n$generated',
        );
      } else if (body is EmptyClassBody) {
        fileBuilder.addSimpleReplacement(
          range.token(body.semicolon),
          '{\n$generated}',
        );
      }
    });
  }

  bool _supportsProps(ClassDeclaration declaration) {
    final element = declaration.declaredFragment?.element;
    if (element == null) {
      return false;
    }
    if (_supportedTypes.contains(element.name)) {
      return true;
    }
    return element.allSupertypes.any(
      (type) => _supportedTypes.contains(type.element.name),
    );
  }

  static const _supportedTypes = {'Equatable', 'Entity', 'ViewModelState'};
}

/// Returns declared instance fields in source order.
///
/// Reading fields from the resolved element model covers body fields and every
/// Dart 3.13 primary-constructor form, including positional, named, `final`,
/// `var`, constant, named, and private primary constructors.
List<String> declaredPropsFields(ClassDeclaration declaration) {
  final fields = declaration.declaredFragment!.element.fields
      .where((field) => !field.isStatic && !field.isOriginEnumValues)
      .toList();
  fields.sort(
    (left, right) =>
        left.firstFragment.offset.compareTo(right.firstFragment.offset),
  );
  return fields.map((field) => field.name).nonNulls.toList();
}

/// Builds Dart 3.13 source for a `props` getter.
String propsGetterSource(List<String> fields) {
  final expression = fields.isEmpty
      ? 'const <Object?>[]'
      : '.unmodifiable([${fields.join(', ')}])';
  return '  @override\n  List<Object?> get props => $expression;\n';
}
