import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:angular_compiler/v1/angular_compiler.dart';
import 'package:angular_compiler/v1/cli.dart';
import 'package:angular_compiler/v1/src/compiler/module/ng_compiler_module.dart';

import 'resolve_reflectables.dart';
import 'template_compiler_outputs.dart';

/// Given an input [element] `a.dart`, returns output for `a.template.dart`.
///
/// "Output" here is defined in terms of [TemplateCompilerOutput], or an
/// abstract collection of elements that need to be emitted into the
/// corresponding `.template.dart` file. See [TemplateCompilerOutput].
Future<TemplateCompilerOutputs> processTemplates(
  LibraryElement element,
  BuildStep buildStep,
  CompilerFlags flags,
) async {
  // Collect the elements that will be emitted into `initReflector()`.
  final reflectables = await resolveReflectables(
    buildStep: buildStep,
    from: element,
    flags: flags,
  );

  // Collect the elements to implement `@GeneratedInjector`(s).
  final injectors = InjectorReader.findInjectors(element);

  // Collect the elements to implement views for `@Component`(s).
  final compiler = createTemplateCompiler(buildStep, flags);
  final sourceModule = await compiler.compile(element);

  // Return them to be emitted to disk as generated code in the future.
  return TemplateCompilerOutputs(
    sourceModule,
    reflectables,
    injectors,
  );
}
