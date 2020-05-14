import 'dart:async';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular_compiler/v1/src/source_gen/common/url_resolver.dart';
import 'package:angular_compiler/v1/cli.dart';

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
    // If there is no output, for any reason, emit an "empty" .template.dart
    // file, that if linked to, is effectively a no-op and is eliminated by
    // Dart2JS during optimizations.
    if (outputs == null) {
      return 'void initReflector() {}';
    }
    // Writes the output to disk (as a text file).
    return buildGeneratedCode(
      library.element,
      outputs,
      fileName(buildStep.inputId),
      library.element.name,
      flags,
    );
  });
}
