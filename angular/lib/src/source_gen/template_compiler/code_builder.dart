import 'package:analyzer/dart/element/element.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:angular_compiler/cli.dart';
import 'package:source_gen/source_gen.dart' show LibraryReader;
import 'package:code_builder/code_builder.dart';

import 'template_compiler_outputs.dart';

String buildGeneratedCode(
  LibraryElement element,
  TemplateCompilerOutputs outputs,
  String sourceFile,
  String libraryName,
  CompilerFlags flags,
) {
  final buffer = StringBuffer();

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
