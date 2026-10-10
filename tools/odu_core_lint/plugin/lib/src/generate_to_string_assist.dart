import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:odu_props_assist/src/class_fields.dart';

final class GenerateToStringAssist extends ResolvedCorrectionProducer {
  static const _kind = AssistKind(
    'odu.assist.generateToString',
    29,
    'Generate toString',
  );

  GenerateToStringAssist({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    final element = declaration?.declaredFragment?.element;
    final className = element?.name;
    if (declaration == null || element == null || className == null) return;

    final body = declaration.body;
    final existing = classMembers(body)
        .whereType<MethodDeclaration>()
        .where((method) => !method.isGetter && method.name.lexeme == 'toString')
        .firstOrNull;
    final source = toStringSource(
      className,
      declaredInstanceFields(declaration).map((field) => field.name).nonNulls,
    );

    await builder.addDartFileEdit(file, (fileBuilder) {
      if (existing != null) {
        fileBuilder.addSimpleReplacement(
          range.node(existing),
          source.trimRight(),
        );
      } else if (body is BlockClassBody) {
        fileBuilder.addSimpleInsertion(body.rightBracket.offset, '\n$source');
      } else if (body is EmptyClassBody) {
        fileBuilder.addSimpleReplacement(
          range.token(body.semicolon),
          '{\n$source}',
        );
      }
    });
  }
}

String toStringSource(String className, Iterable<String> fields) {
  final values = fields.map((field) => '$field: \$$field').join(', ');
  return "  @override\n  String toString() => '$className($values)';\n";
}
