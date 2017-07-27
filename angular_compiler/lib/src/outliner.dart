import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'analyzer.dart';

const _angularPkg = 'package:angular/angular.dart';

/// Generates an _outline_ of the public API of a `.template.dart` file.
///
/// Used as part of some compile processes in order to speed up incremental
/// builds by taking the full compile (actual generation of `.template.dart`
/// off the critical path).
class TemplateOutliner implements Builder {
  final String _extension;

  const TemplateOutliner({
    String extension: '.outline.template.dart',
  })
      : _extension = extension;

  @override
  Future<Null> build(BuildStep buildStep) async {
    final library = await buildStep.inputLibrary;
    final components = <String>[];
    final directives = <String>[];
    for (final clazz in library.definingCompilationUnit.types) {
      if ($Component.firstAnnotationOfExact(clazz) != null) {
        components.add(clazz.name);
      } else if ($Directive.firstAnnotationOfExact(clazz) != null) {
        directives.add(clazz.name);
      }
    }
    final output = new StringBuffer();
    if (components.isNotEmpty) {
      output.writeln("import '$_angularPkg';\n");
    }
    if (components.isNotEmpty || directives.isNotEmpty) {
      final userLandCode = p.basename(buildStep.inputId.path);
      output.writeln("import '$userLandCode' as _user;");
    }
    if (components.isNotEmpty) {
      for (final component in components) {
        final name = '${component}NgFactory';
        output.writeln('const List<dynamic> styles\$$component = const [];');
        output.writeln('external ComponentFactory get $name;');
        output.writeln(
            'external AppView<_user.$component> viewFactory_${component}0(AppView<dynamic> parentView, num parentIndex);');
        output.writeln(
            'class View${component}0 extends AppView<_user.$component> {');
        output.writeln(
            '  external factory View${component}0(AppView<dynamic> parentView, num parentIndex);');
        output.writeln('}');
      }
    }
    if (directives.isNotEmpty) {
      for (final directive in directives) {
        final name = '${directive}NgCd';
        output.writeln('class $name {');
        output.writeln('  external get _user.$directive instance;');
        output.writeln(
            '  external factory ${directive}Cd(_user.$directive instance);');
        for (final input in _findInputs(library.getType(directive))) {
          output.writeln('  external void ngSet\$$input(dynamic value);');
        }
        output.writeln('}');
      }
    }
    output.writeln('external void initReflector();');
    buildStep.writeAsString(
      buildStep.inputId.changeExtension(_extension),
      output.toString(),
    );
  }

  Iterable<String> _findInputs(ClassElement element) {
    final inputs = new Set<String>();
    for (final interface in getInheritanceHierarchy(element.type)) {
      for (final accessor in interface.accessors) {
        final input = $Input.firstAnnotationOfExact(accessor);
        if (input != null) {
          inputs.add(accessor.name);
        }
      }
      for (final field in interface.element.fields) {
        final input = $Input.firstAnnotationOfExact(field);
        if (input != null) {
          inputs.add(field.name);
        }
      }
    }
    return inputs;
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': [_extension],
      };
}
