import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:angular_compiler/cli.dart';
import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'analyzer.dart';

const _htmlImport = "import 'dart:html';";
const _angularImport = "import 'package:angular/angular.dart';";
const _appViewImport =
    "import 'package:angular/src/core/linker/app_view.dart';";
const _directiveChangeImport =
    "import 'package:angular/src/core/change_detection/directive_change_detector.dart';";

const _analyzerIgnores =
    '// ignore_for_file: library_prefixes,unused_import,no_default_super_constructor_explicit,duplicate_import,unused_shown_name';

String _typeParametersOf(ClassElement element) {
  // TODO(b/111800117): generics with bounds aren't yet supported.
  if (element.typeParameters.isEmpty ||
      element.typeParameters.any((t) => t.bound != null)) {
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

  String get _angularImports {
    return '$_htmlImport\n$_angularImport\n$_directiveChangeImport\n$_appViewImport';
  }

  String get _appViewClass => 'AppView';

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
      buildStep.writeAsString(
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
        ..writeln(_angularImports)
        ..writeln();
      final userLandCode = p.basename(buildStep.inputId.path);
      output
        ..writeln('// Required for specifically referencing user code.')
        ..writeln("import '$userLandCode' as _user;")
        ..writeln();
    }

    // TODO(matanl): Add this as a helper function in angular_compiler.
    output.writeln('// Required for "type inference" (scoping).');
    for (final d in library.imports) {
      if (d is ImportDirective && !d.isDeferred && d.uri != null) {
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
                return const [];
              })
              .expand((i) => i)
              .join(', ');
        }
        output.writeln('$directive;');
      }
    }
    output.writeln();
    if (components.isNotEmpty) {
      for (final component in components) {
        final componentName = component.name;
        // Note that until type parameter bounds are supported, there's no
        // difference between a type parameter and its use as a type argument,
        // so we reuse the type parameters for both.
        final typeParameters = _typeParametersOf(component);
        final componentType = '_user.$componentName$typeParameters';
        final baseType = '$_appViewClass<$componentType>';
        final viewArgs = '$_appViewClass<dynamic> parentView, int parentIndex';
        final viewName = 'View${componentName}0';
        output.write('''
// For @Component class $componentName.
external List<dynamic> get styles\$$componentName;
external ComponentFactory<_user.$componentName> get ${componentName}NgFactory;
external $baseType viewFactory_${componentName}0$typeParameters($viewArgs);
class $viewName$typeParameters extends $baseType {
  external $viewName($viewArgs);
}
''');
      }
    }
    if (directives.isNotEmpty) {
      for (final directive in directives) {
        final directiveName = directive.name;
        final changeDetectorName = '${directiveName}NgCd';
        // Note that until type parameter bounds are supported, there's no
        // difference between a type parameter and its use as a type argument,
        // so we reuse the type parameters for both.
        final typeParameters = _typeParametersOf(directive);
        final directiveType = '_user.$directiveName$typeParameters';
        output.write('''
// For @Directive class $directiveName.
class $changeDetectorName$typeParameters extends DirectiveChangeDetector {
  external $directiveType get instance;
  external void deliverChanges();
  external $changeDetectorName($directiveType instance);
  external void detectHostChanges(AppView view, Element node);
}
''');
      }
    }
    if (injectors.isNotEmpty) {
      for (final injector in injectors) {
        output.writeln('external Injector $injector([Injector parent]);');
      }
    }
    output..writeln()..writeln('external void initReflector();');
    buildStep.writeAsString(
      buildStep.inputId.changeExtension(_extension),
      output.toString(),
    );
  }

  @override
  final Map<String, List<String>> buildExtensions;
}
