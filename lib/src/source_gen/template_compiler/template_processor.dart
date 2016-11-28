import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/compiler/config.dart';
import 'package:angular2/src/source_gen/common/logging.dart';
import 'package:angular2/src/source_gen/common/ng_compiler.dart';
import 'package:angular2/src/source_gen/common/ng_deps_model.dart';
import 'package:angular2/src/source_gen/template_compiler/find_components.dart';
import 'package:angular2/src/source_gen/template_compiler/template_compiler_outputs.dart';
import 'package:angular2/src/transform/common/options.dart';
import 'package:build/build.dart';

Future<TemplateCompilerOutputs> processTemplates(
    Element element, BuildStep buildStep,
    {String codegenMode: '',
    bool reflectPropertiesAsAttributes: false,
    List<String> platformDirectives,
    List<String> platformPipes,
    Map<String, String> resolvedIdentifiers}) async {
  final templateCompiler = createTemplateCompiler(
    buildStep,
    compilerConfig: new CompilerConfig(codegenMode == CODEGEN_DEBUG_MODE,
        reflectPropertiesAsAttributes, false),
  );

  final compileComponentsData = logElapsedSync(
      () => findComponents(buildStep, element),
      operationName: 'findComponents',
      assetId: buildStep.input.id,
      log: buildStep.logger);
  if (compileComponentsData.isEmpty) return null;
  await Future.forEach(compileComponentsData, (component) async {
    component.component =
        await templateCompiler.normalizeDirectiveMetadata(component.component);
  });
  final compiledTemplates = logElapsedSync(() {
    return templateCompiler.compile(compileComponentsData);
  }, operationName: 'compile', assetId: buildStep.input.id);
  return new TemplateCompilerOutputs(compiledTemplates, new NgDepsModel());
}
