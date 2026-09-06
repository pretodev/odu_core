import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:odu_props_assist/src/generate_copy_with_assist.dart';
import 'package:odu_props_assist/src/generate_props_assist.dart';
import 'package:odu_props_assist/src/generate_to_string_assist.dart';
import 'package:test/test.dart';

void main() {
  test(
    'discovers fields from all Dart 3.13 primary constructor forms',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'odu_props_assist_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      File('${directory.path}/pubspec.yaml').writeAsStringSync(
        'name: primary_constructor_fixture\n'
        'environment:\n'
        '  sdk: ^3.13.2\n',
      );
      File('${directory.path}/analysis_options.yaml').writeAsStringSync(
        'analyzer:\n'
        '  enable-experiment:\n'
        '    - declaring-constructors\n',
      );
      final source = File('${directory.path}/models.dart');
      source.writeAsStringSync(_primaryConstructorSource);
      final collection = AnalysisContextCollection(
        includedPaths: [source.path],
      );
      final result = await collection
          .contextFor(source.path)
          .currentSession
          .getResolvedUnit(source.path);

      expect(result, isA<ResolvedUnitResult>());
      final unit = (result as ResolvedUnitResult).unit;
      final classes = {
        for (final declaration
            in unit.declarations.whereType<ClassDeclaration>())
          declaration.declaredFragment!.element.name: declaredPropsFields(
            declaration,
          ),
      };

      expect(classes['Positional'], ['id', 'name']);
      expect(classes['Named'], ['id', 'name']);
      expect(classes['Private'], ['id']);
      expect(classes['Constant'], ['id']);
      expect(classes['Mixed'], ['id', 'bodyField']);
      expect(classes['Child'], ['label']);

      final declarations = unit.declarations.whereType<ClassDeclaration>();
      final constructors = {
        for (final declaration in declarations)
          declaration.declaredFragment!.element.name:
              declaration.declaredFragment!.element.constructors,
      };
      expect(
        copyWithSource('Positional', constructors['Positional']!.single),
        '  Positional copyWith({int? id, String? name}) =>\n'
        '      .new(id ?? this.id, name ?? this.name);\n',
      );
      expect(
        copyWithSource('Named', constructors['Named']!.single),
        '  Named copyWith({int? id, String? name}) =>\n'
        '      .new(id: id ?? this.id, name: name ?? this.name);\n',
      );
      expect(
        copyWithSource('Private', constructors['Private']!.single),
        '  Private copyWith({int? id}) =>\n'
        '      ._(id ?? this.id);\n',
      );
    },
  );

  test('generates contextual dot shorthand and a const empty list', () {
    expect(
      propsGetterSource(['id', 'name']),
      '  @override\n'
      '  List<Object?> get props => .unmodifiable([id, name]);\n',
    );
    expect(
      propsGetterSource([]),
      '  @override\n'
      '  List<Object?> get props => const <Object?>[];\n',
    );
  });

  test('generates labeled toString methods', () {
    expect(
      toStringSource('Person', ['id', 'name']),
      "  @override\n  String toString() => 'Person(id: \$id, name: \$name)';\n",
    );
    expect(
      toStringSource('Empty', const []),
      "  @override\n  String toString() => 'Empty()';\n",
    );
  });
}

const _primaryConstructorSource = '''
abstract class Equatable {
  List<Object?> get props;
}

class Positional(final int id, var String name) extends Equatable;

class Named({required final int id, final String? name}) extends Equatable;

class Private._(final int id) extends Equatable;

class const Constant(final int id) extends Equatable;

class Mixed(String transient, final int id) extends Equatable {
  static const ignored = 1;
  final String bodyField = transient;
}

class Parent(final int id) extends Equatable;

class Child(super.id, final String label) extends Parent;
''';
