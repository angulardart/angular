import 'dart:async';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular/src/source_gen/common/url_resolver.dart';
import 'package:angular_compiler/cli.dart';

import 'code_builder.dart';
import 'template_processor.dart';

/// Executes the AngularDart code generator for the provided inputs.
Future<String> generate(
  LibraryReader library,
  BuildStep buildStep,
  CompilerFlags flags,
) {
  return processTemplates(library.element, buildStep, flags).then((outputs) {
    if (outputs == null) {
      // This will be tree-shaken (100% pure no-op).
      return 'void initReflector() {}';
    }
    return buildGeneratedCode(
      library.element,
      outputs,
      fileName(buildStep.inputId),
      library.element.name,
      flags,
    );
  });
}
