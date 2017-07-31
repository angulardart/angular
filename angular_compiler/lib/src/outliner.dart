import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'analyzer.dart';

const _angularImports = '''
import 'package:angular/angular.dart';
import 'package:angular/src/core/linker/app_view.dart';
''';

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
    if (library == null) {
      buildStep.writeAsString(
          buildStep.inputId.changeExtension('.outline.template.dart'),
          'external void initReflector();');
      return;
    }
    final components = <String>[];
    final directives = <String, DartObject>{};
    var units = [library.definingCompilationUnit]..addAll(library.parts);
    var types = units.expand((unit) => unit.types);
    for (final clazz in types) {
      final component = $Component.firstAnnotationOfExact(
        clazz,
        throwOnUnresolved: false,
      );
      if (component != null) {
        components.add(clazz.name);
      } else {
        final directive = $Directive.firstAnnotationOfExact(
          clazz,
          throwOnUnresolved: false,
        );
        if (directive != null) {
          directives[clazz.name] = directive;
        }
      }
    }
    final output = new StringBuffer();
    output.writeln("export '${p.basename(buildStep.inputId.path)}';");
    if (components.isNotEmpty) {
      output.writeln(_angularImports);
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
      directives.forEach((directive, annotation) {
        final name = '${directive}NgCd';
        output.writeln('class $name {');
        output.writeln('  external _user.$directive get instance;');
        output.writeln('  external factory $name(_user.$directive instance);');
        for (final input in _findInputs(
          library.getType(directive),
          annotation,
        )) {
          output.writeln('  external void ngSet\$$input(dynamic value);');
        }
        output.writeln('}');
      });
    }
    output.writeln('external void initReflector();');
    buildStep.writeAsString(
      buildStep.inputId.changeExtension(_extension),
      output.toString(),
    );
  }

  Iterable<String> _findInputs(ClassElement element, DartObject annotation) {
    final inputs = new Set<String>();
    for (final interface in getInheritanceHierarchy(element.type)) {
      for (final accessor in interface.accessors) {
        final input = $Input.firstAnnotationOfExact(
          accessor,
          throwOnUnresolved: false,
        );
        if (input != null) {
          inputs.add(accessor.name);
        }
      }
      for (final field in interface.element.fields) {
        final input = $Input.firstAnnotationOfExact(
          field,
          throwOnUnresolved: false,
        );
        if (input != null) {
          inputs.add(field.name);
        }
      }
    }
    final onClass = annotation.getField('inputs')?.toListValue() ?? const [];
    for (final classInput in onClass) {
      final inputName = classInput.toStringValue();
      if (inputName.contains(':')) {
        inputs.add(inputName.split(':').last.trim());
      } else {
        inputs.add(inputName.trim());
      }
    }
    return inputs.map(
      (i) => i.endsWith('=') ? i.substring(0, i.length - 1) : i,
    );
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': [_extension],
      };
}
