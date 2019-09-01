import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:angular_compiler/cli.dart';
import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'analyzer.dart';
import 'outliner/collect_type_parameters.dart';

const _angularImports = '''
import 'dart:html' as _html;
import 'package:angular/angular.dart' as _ng;
import 'package:angular/src/core/change_detection/directive_change_detector.dart' as _ng;
import 'package:angular/src/core/linker/views/component_view.dart' as _ng;
import 'package:angular/src/core/linker/views/render_view.dart' as _ng;
import 'package:angular/src/core/linker/views/view.dart' as _ng;
''';

const _analyzerIgnores =
    '// ignore_for_file: library_prefixes,unused_import,strict_raw_type,'
    'no_default_super_constructor_explicit,undefined_hidden_name';

String _typeArgumentsFor(ClassElement element) {
  if (element.typeParameters.isEmpty) {
    return '';
  }
  final buffer = StringBuffer('<')
    ..writeAll(element.typeParameters.map((t) => t.name), ', ')
    ..write('>');
  return buffer.toString();
}

/// Generates an _outline_ of the public API of a `.template.dart` file.
///
/// Used as part of some compile processes in order to speed up incremental
/// builds by taking the full compile (actual generation of `.template.dart`
/// off the critical path).
class TemplateOutliner implements Builder {
  final String _extension;

  final bool exportUserCodeFromTemplate;

  TemplateOutliner({
    @required String extension,
    @required this.exportUserCodeFromTemplate,
  })  : _extension = extension,
        buildExtensions = {
          '.dart': [extension],
        };

  @override
  Future<Null> build(BuildStep buildStep) async {
    if (!await buildStep.resolver.isLibrary(buildStep.inputId)) {
      await buildStep.writeAsString(
        buildStep.inputId.changeExtension(_extension),
        'external void initReflector();',
      );
      return;
    }
    final library = await buildStep.inputLibrary;
    final components = <ClassElement>[];
    final directives = <ClassElement>[];
    final injectors = <String>[];
    var units = [library.definingCompilationUnit]..addAll(library.parts);
    var types = units.expand((unit) => unit.types);
    var fields = units.expand((unit) => unit.topLevelVariables);
    for (final clazz in types) {
      final component = $Component.firstAnnotationOfExact(
        clazz,
        throwOnUnresolved: false,
      );
      if (component != null) {
        components.add(clazz);
      } else {
        final directive = $Directive.firstAnnotationOfExact(
          clazz,
          throwOnUnresolved: false,
        );
        if (directive != null) {
          directives.add(clazz);
        }
      }
    }
    for (final field in fields) {
      if ($GenerateInjector.hasAnnotationOfExact(
        field,
        throwOnUnresolved: false,
      )) {
        injectors.add('${field.name}\$Injector');
      }
    }
    final output = StringBuffer('$_analyzerIgnores\n');
    if (exportUserCodeFromTemplate) {
      output
        ..writeln('// The .template.dart files also export the user code.')
        ..writeln("export '${p.basename(buildStep.inputId.path)}';")
        ..writeln();
    }
    if (components.isNotEmpty ||
        directives.isNotEmpty ||
        injectors.isNotEmpty) {
      output
        ..writeln('// Required for referencing runtime code.')
        ..writeln(_angularImports);
      final userLandCode = p.basename(buildStep.inputId.path);
      output
        ..writeln('// Required for specifically referencing user code.')
        ..writeln("import '$userLandCode';")
        ..writeln();
    }

    // TODO(matanl): Add this as a helper function in angular_compiler.
    output.writeln('// Required for "type inference" (scoping).');
    for (final d in library.imports) {
      if (!d.isDeferred && d.uri != null) {
        var directive = "import '${d.uri}'";
        if (d.prefix != null) {
          directive += ' as ${d.prefix.name}';
        }
        if (d.combinators.isNotEmpty) {
          final isShow = d.combinators.first is ShowElementCombinator;
          directive += isShow ? ' show ' : ' hide ';
          directive += d.combinators
              .map((c) {
                if (c is ShowElementCombinator) {
                  return c.shownNames;
                }
                if (c is HideElementCombinator) {
                  return c.hiddenNames;
                }
                return const <Object>[];
              })
              .expand((i) => i)
              .join(', ');
        }
        output.writeln('$directive;');
      }
    }
    output.writeln();
    final directiveTypeParameters = await collectTypeParameters(
        components.followedBy(directives), buildStep);
    if (components.isNotEmpty) {
      for (final component in components) {
        final componentName = component.name;
        final typeArguments = _typeArgumentsFor(component);
        final typeParameters = directiveTypeParameters[component.name];
        final componentType = '$componentName$typeArguments';
        final viewName = 'View${componentName}0';
        output.write('''
// For @Component class $componentName.
external List<dynamic> get styles\$$componentName;
external _ng.ComponentFactory<$componentName> get ${componentName}NgFactory;
class $viewName$typeParameters extends _ng.ComponentView<$componentType> {
  external $viewName(_ng.View parentView, int parentIndex);
}
''');
      }
    }
    if (directives.isNotEmpty) {
      for (final directive in directives) {
        final directiveName = directive.name;
        final changeDetectorName = '${directiveName}NgCd';
        final typeArguments = _typeArgumentsFor(directive);
        final typeParameters = directiveTypeParameters[directive.name];
        final directiveType = '$directiveName$typeArguments';
        output.write('''
// For @Directive class $directiveName.
class $changeDetectorName$typeParameters extends _ng.DirectiveChangeDetector {
  external $directiveType get instance;
  external void deliverChanges();
  external $changeDetectorName($directiveType instance);
  external void detectHostChanges(_ng.RenderView view, _html.Element hostElement);
}
''');
      }
    }
    if (injectors.isNotEmpty) {
      for (final injector in injectors) {
        output
            .writeln('external _ng.Injector $injector([_ng.Injector parent]);');
      }
    }
    output..writeln()..writeln('external void initReflector();');
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension(_extension),
      output.toString(),
    );
  }

  @override
  final Map<String, List<String>> buildExtensions;
}
