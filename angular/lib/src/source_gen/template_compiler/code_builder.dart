import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:source_gen/source_gen.dart' show LibraryReader;
import 'package:code_builder/code_builder.dart';

import 'template_compiler_outputs.dart';

const _ignoredProblems = const <String>[
  'cancel_subscriptions',
  'constant_identifier_names',
  'duplicate_import',
  'non_constant_identifier_names',
  'library_prefixes',
  'UNUSED_IMPORT',
  'UNUSED_SHOWN_NAME',
];

String buildGeneratedCode(
  LibraryElement element,
  TemplateCompilerOutputs outputs,
  String sourceFile,
  String libraryName,
) {
  final buffer = new StringBuffer();

  // Avoid strong-mode warnings that are not solvable quite yet.
  if (_ignoredProblems.isNotEmpty) {
    var problems = _ignoredProblems.join(',');
    buffer.writeln('// ignore_for_file: $problems');
  }

  // Generated code.
  final allocator = new Allocator.simplePrefixing();
  final compilerOutput = outputs.templatesSource?.source ?? '';
  final reflectableOutput = new ReflectableEmitter(
    outputs.reflectableOutput,
    new LibraryReader(element),
    allocator: allocator,
    deferredModules: outputs.templatesSource != null
        ? outputs.templatesSource.deferredModules.keys.toList()
        : const [],
    deferredModuleSource: outputs.templatesSource?.moduleUrl,
  );

  // Write the input file as an import and an export.
  buffer.writeln("import '$sourceFile';");
  buffer.writeln("export '$sourceFile';");

  // Write all other imports and exports out directly.
  final astLibrary = element.definingCompilationUnit.computeNode();
  for (final directive in astLibrary.directives) {
    if ((directive is ImportDirective && directive.deferredKeyword == null) ||
        buffer is ExportDirective) {
      buffer.writeln(directive.toSource());
    }
  }

  // Write imports required for initReflector.
  buffer.writeln(reflectableOutput.emitImports());

  if (outputs.injectorsOutput.isNotEmpty) {
    final imports = new StringBuffer();
    final body = new StringBuffer();
    final file = new LibraryBuilder();
    final dart = new SplitDartEmitter(imports, allocator);

    for (final injector in outputs.injectorsOutput) {
      final emitter = new InjectorEmitter();
      injector.accept(emitter);
      file.body.addAll([
        emitter.createFactory(),
        emitter.createClass(),
      ]);
    }

    // Write imports AND backing code required for generated injectors.
    file.build().accept(dart, body);

    // ... in a specific order, so we don't put inputs before classes, etc.
    buffer.writeln(imports);
    buffer.writeln(compilerOutput);
    buffer.writeln(body);
  } else {
    // Write generated code.
    buffer.writeln(compilerOutput);
  }

  // Write initReflector.
  buffer.writeln(reflectableOutput.emitInitReflector());

  return buffer.toString();
}
