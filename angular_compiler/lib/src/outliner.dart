import 'dart:async';
import 'package:build/build.dart';

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
    for (final clazz in library.definingCompilationUnit.types) {
      if ($Component.annotationsOfExact(clazz) != null) {
        components.add(clazz.name);
      }
    }
    final output = new StringBuffer();
    if (components.isNotEmpty) {
      output.writeln("import '$_angularPkg';\n");
      for (final component in components) {
        final name = '${component}NgFactory';
        output.writeln('external ComponentFactory get $name;');
      }
    }
    output.writeln('external void initReflector();');
    buildStep.writeAsString(
      buildStep.inputId.changeExtension(_extension),
      output.toString(),
    );
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': [_extension],
      };
}
