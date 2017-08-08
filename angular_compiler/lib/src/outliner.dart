import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'analyzer.dart';
import 'flags.dart';

const _angularImport = "import 'package:angular/angular.dart';";
const _appViewImport =
    "import 'package:angular/src/core/linker/app_view.dart';";
const _debugAppViewImport =
    "import 'package:angular/src/debug/debug_app_view.dart';";
const _directiveChangeImport =
    "import 'package:angular/src/core/change_detection/directive_change_detector.dart';";

/// Generates an _outline_ of the public API of a `.template.dart` file.
///
/// Used as part of some compile processes in order to speed up incremental
/// builds by taking the full compile (actual generation of `.template.dart`
/// off the critical path).
class TemplateOutliner implements Builder {
  final String _extension;
  final CompilerFlags _compilerFlags;

  String get _angularImports {
    var appViewImport =
        _compilerFlags.genDebugInfo ? _debugAppViewImport : _appViewImport;
    return '$_angularImport\n$_directiveChangeImport\n$appViewImport';
  }

  String get _appViewClass =>
      _compilerFlags.genDebugInfo ? 'DebugAppView' : 'AppView';

  TemplateOutliner(
    this._compilerFlags, {
    String extension: '.outline.template.dart',
  })
      : _extension = extension,
        buildExtensions = {
          '.dart': [extension],
        };

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
    output
      ..writeln('// The .template.dart files also export the user code.')
      ..writeln("export '${p.basename(buildStep.inputId.path)}';")
      ..writeln();
    if (components.isNotEmpty) {
      output
        ..writeln('// Required for implementing $_appViewClass.')
        ..writeln(_angularImports)
        ..writeln();
    }
    if (components.isNotEmpty || directives.isNotEmpty) {
      final userLandCode = p.basename(buildStep.inputId.path);
      output
        ..writeln('// Required for specifically referencing user code.')
        ..writeln("import '$userLandCode' as _user;")
        ..writeln();
    }
    output.writeln('// Required for "type inference" (scoping).');
    for (final d in library.definingCompilationUnit.computeNode().directives) {
      if (d is ImportDirective) {
        output.writeln(d.toSource());
      }
    }
    output.writeln();
    if (components.isNotEmpty) {
      for (final component in components) {
        final name = '${component}NgFactory';
        output
          ..writeln('// For @Component class $component.')
          ..writeln('const List<dynamic> styles\$$component = const [];')
          ..writeln('external ComponentFactory get $name;')
          ..writeln(
              'external $_appViewClass<_user.$component> viewFactory_${component}0($_appViewClass<dynamic> parentView, num parentIndex);')
          ..writeln(
              'class View${component}0 extends $_appViewClass<_user.$component> {')
          ..writeln(
              '  external View${component}0($_appViewClass<dynamic> parentView, num parentIndex);')
          ..writeln('}');
      }
    }
    if (directives.isNotEmpty) {
      directives.forEach((directive, annotation) {
        final name = '${directive}NgCd';
        output
          ..writeln('// For @Directive class $directive.')
          ..writeln('class $name extends DirectiveChangeDetector {')
          ..writeln('  external _user.$directive get instance;')
          ..writeln('  external $name(_user.$directive instance);');
        _findInputs(library.getType(directive), annotation).forEach((
          name,
          type,
        ) {
          output.writeln('  external void ngSet\$$name($type value);');
        });
        output.writeln('}');
      });
    }
    output..writeln()..writeln('external void initReflector();');
    buildStep.writeAsString(
      buildStep.inputId.changeExtension(_extension),
      output.toString(),
    );
  }

  static String _inferTypeField(FieldElement element) {
    final node = element.computeNode();
    TypeAnnotation type;
    if (node is VariableDeclaration) {
      type = (node.parent as VariableDeclarationList).type;
    } else {
      // Failed to "infer" type.
      return '/* FAILED TO INFER: ${node.runtimeType} from $element */ dynamic';
    }
    return '$type';
  }

  static String _inferTypeMethod(PropertyAccessorElement element) {
    final node = element.computeNode();
    TypeAnnotation type;
    if (node is MethodDeclaration) {
      final parameter = node.parameters.parameters.first;
      if (parameter is SimpleFormalParameter) {
        type = parameter.type;
      } else {
        // Failed to "infer" type.
        return '/* FAILED TO INFER: ${parameter.runtimeType} from $element */ dynamic';
      }
    } else {
      // Failed to "infer" type.
      return '/* FAILED TO INFER: ${node.runtimeType} from $element */ dynamic';
    }
    return '$type';
  }

  static String _normalize(String n) =>
      n.endsWith('=') ? n.substring(0, n.length - 1) : n;

  Map<String, String> _findInputs(ClassElement element, DartObject annotation) {
    final inputs = <String, String>{};
    for (final interface in getInheritanceHierarchy(element.type)) {
      for (final accessor in interface.accessors) {
        final input = $Input.firstAnnotationOfExact(
          accessor,
          throwOnUnresolved: false,
        );
        if (input != null) {
          inputs[_normalize(accessor.name)] = _inferTypeMethod(accessor);
        }
      }
      for (final field in interface.element.fields) {
        final input = $Input.firstAnnotationOfExact(
          field,
          throwOnUnresolved: false,
        );
        if (input != null) {
          inputs[field.name] = _inferTypeField(field);
        }
      }
    }
    final onClass = annotation.getField('inputs')?.toListValue() ?? const [];
    for (final classInput in onClass) {
      final inputName = classInput.toStringValue();
      // These are specifically not typed (dynamic), because we'd have to walk
      // the hierarchy and "find" the type, which isn't doable in the outliner.
      const canNotInfer = '/* CAN NOT INFER: Class level. */ dynamic';
      if (inputName.contains(':')) {
        inputs[inputName.split(':').first.trim()] = canNotInfer;
      } else {
        inputs[inputName.trim()] = canNotInfer;
      }
    }
    return inputs;
  }

  @override
  final Map<String, List<String>> buildExtensions;
}
