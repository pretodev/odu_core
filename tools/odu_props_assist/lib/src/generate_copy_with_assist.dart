import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:odu_props_assist/src/class_fields.dart';

final class GenerateCopyWithAssist extends ResolvedCorrectionProducer {
  static const _kind = AssistKind(
    'odu.assist.generateCopyWith',
    28,
    'Generate copyWith',
  );

  GenerateCopyWithAssist({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    final element = declaration?.declaredFragment?.element;
    if (declaration == null || element == null || element.isAbstract) return;

    final constructor = _copyConstructor(element);
    if (constructor == null || !_parametersAreReadable(element, constructor)) {
      return;
    }

    final body = declaration.body;
    final existing = classMembers(body)
        .whereType<MethodDeclaration>()
        .where((method) => !method.isGetter && method.name.lexeme == 'copyWith')
        .firstOrNull;
    final source = copyWithSource(
      element.thisType.getDisplayString(),
      constructor,
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

  ConstructorElement? _copyConstructor(InterfaceElement element) {
    final generative = element.constructors.where((item) => item.isGenerative);
    return generative.where((item) => item.isPrimary).firstOrNull ??
        generative.where((item) => item.name == 'new').firstOrNull ??
        generative.singleOrNull;
  }

  bool _parametersAreReadable(
    InterfaceElement element,
    ConstructorElement constructor,
  ) {
    final readable = <String>{
      ...element.fields
          .where((field) => !field.isStatic)
          .map((field) => field.name)
          .nonNulls,
      for (final type in element.allSupertypes)
        ...type.element.fields
            .where((field) => !field.isStatic)
            .map((field) => field.name)
            .nonNulls,
    };
    return constructor.formalParameters.every(
      (parameter) =>
          parameter.name != null && readable.contains(parameter.name),
    );
  }
}

String copyWithSource(String classType, ConstructorElement constructor) {
  final parameters = constructor.formalParameters;
  final declarations = parameters
      .map((parameter) {
        final name = parameter.name;
        if (name == null) throw StateError('Unnamed constructor parameter');
        final type = parameter.type.getDisplayString();
        final nullableType = type.endsWith('?') || type == 'dynamic'
            ? type
            : '$type?';
        return '$nullableType $name';
      })
      .join(', ');
  final arguments = parameters
      .map((parameter) {
        final name = parameter.name;
        if (name == null) throw StateError('Unnamed constructor parameter');
        final value = '$name ?? this.$name';
        return parameter.isNamed ? '$name: $value' : value;
      })
      .join(', ');
  final constructorName = constructor.name ?? 'new';
  return '  $classType copyWith({$declarations}) =>\n'
      '      .$constructorName($arguments);\n';
}
