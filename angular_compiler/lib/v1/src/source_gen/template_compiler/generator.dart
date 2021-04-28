import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular_compiler/v1/cli.dart';
import 'package:angular_compiler/v1/src/source_gen/common/url_resolver.dart';

import 'code_builder.dart';
import 'template_processor.dart';

/// Given an input [library] `a.dart`, returns the code for `a.template.dart`.
Future<String> generate(
  LibraryReader library,
  BuildStep buildStep,
  CompilerFlags flags,
) {
  // Read the library and determine the outputs of `*.template.dart`.
  return processTemplates(library.element, buildStep, flags).then((outputs) {
    // Writes the output to disk (as a text file).
    return buildGeneratedCode(
      library.element,
      outputs,
      fileName(buildStep.inputId),
      flags,
    );
  });
}
