import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
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
const _debugAppViewImport =
    "import 'package:angular/src/debug/debug_app_view.dart';";
const _directiveChangeImport =
    "import 'package:angular/src/core/change_detection/directive_change_detector.dart';";

const _analyzerIgnores =
    '// ignore_for_file: library_prefixes,unused_import,no_default_super_constructor_explicit,duplicate_import,unused_shown_name';

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
    return '$_htmlImport\n$_angularImport\n$_directiveChangeImport\n$appViewImport';
  }

  String get _appViewClass =>
      _compilerFlags.genDebugInfo ? 'DebugAppView' : 'AppView';

  TemplateOutliner(
    this._compilerFlags, {
    @required String extension,
  })
      : _extension = extension,
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
    final components = <String>[];
    final directives = <String, DartObject>{};
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
    for (final field in fields) {
      if ($GenerateInjector.hasAnnotationOfExact(
        field,
        throwOnUnresolved: false,
      )) {
        injectors.add('${field.name}\$Injector');
      }
    }
    final output = new StringBuffer('$_analyzerIgnores\n');
    output
      ..writeln('// The .template.dart files also export the user code.')
      ..writeln("export '${p.basename(buildStep.inputId.path)}';")
      ..writeln();
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
          ..writeln('  external void deliverChanges();')
          ..writeln('  external $name(_user.$directive instance);')
          ..writeln('  external void detectHostChanges(AppView view, '
              'Element node);');
        output.writeln('}');
      });
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
