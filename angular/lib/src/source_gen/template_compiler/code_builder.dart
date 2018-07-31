import 'package:analyzer/dart/element/element.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:angular_compiler/cli.dart';
import 'package:source_gen/source_gen.dart' show LibraryReader;
import 'package:code_builder/code_builder.dart';

import 'template_compiler_outputs.dart';

const _ignoredProblems = <String>[
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
  CompilerFlags flags,
) {
  final buffer = StringBuffer();

  // Avoid strong-mode warnings that are not solvable quite yet.
  if (_ignoredProblems.isNotEmpty) {
    var problems = _ignoredProblems.join(',');
    buffer.writeln('// ignore_for_file: $problems');
  }

  // Generated code.
  final allocator = Allocator.simplePrefixing();
  final compilerOutput = outputs.templatesSource?.source ?? '';
  final reflectableOutput = ReflectableEmitter(
    outputs.reflectableOutput,
    LibraryReader(element),
    allocator: allocator,
    deferredModules: outputs.templatesSource != null
        ? outputs.templatesSource.deferredModules.keys.toList()
        : const [],
    deferredModuleSource: outputs.templatesSource?.moduleUrl,
  );

  // Write the input file as an import and an export.
  buffer.writeln("import '$sourceFile';");
  if (flags.exportUserCodeFromTemplate) {
    buffer.writeln("export '$sourceFile';");
  }

  // TODO(matanl): Add this as a helper function in angular_compiler.
  // Write all other imports out directly.
  for (final d in element.imports) {
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
              return const [];
            })
            .expand((i) => i)
            .join(', ');
      }
      buffer.writeln('$directive;');
    }
  }

  // Write imports required for initReflector.
  buffer.writeln(reflectableOutput.emitImports());

  if (outputs.injectorsOutput.isNotEmpty) {
    final imports = StringBuffer();
    final body = StringBuffer();
    final file = LibraryBuilder();
    final dart = SplitDartEmitter(imports, allocator);

    for (final injector in outputs.injectorsOutput) {
      final emitter = InjectorEmitter();
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
