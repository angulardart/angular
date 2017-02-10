import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/compiler/config.dart';
import 'package:angular2/src/compiler/offline_compiler.dart';
import 'package:angular2/src/source_gen/common/logging.dart';
import 'package:angular2/src/source_gen/common/ng_compiler.dart';
import 'package:angular2/src/source_gen/template_compiler/find_components.dart';
import 'package:angular2/src/source_gen/template_compiler/ng_deps_visitor.dart';
import 'package:angular2/src/source_gen/template_compiler/template_compiler_outputs.dart';
import 'package:angular2/src/transform/common/options.dart';
import 'package:build/build.dart';

Future<TemplateCompilerOutputs> processTemplates(
    LibraryElement element, BuildStep buildStep,
    {String codegenMode: '', bool reflectPropertiesAsAttributes: false}) async {
  final templateCompiler = createTemplateCompiler(
    buildStep,
    compilerConfig: new CompilerConfig(
        codegenMode == CODEGEN_DEBUG_MODE, reflectPropertiesAsAttributes),
  );

  final ngDepsModel = logElapsedSync(
      () => extractNgDepsModel(element, buildStep),
      operationName: 'extractNgDepsModel',
      assetId: buildStep.inputId,
      log: buildStep.logger);

  final List<NormalizedComponentWithViewDirectives> compileComponentsData =
      logElapsedSync(() => findComponents(buildStep, element),
          operationName: 'findComponents',
          assetId: buildStep.inputId,
          log: buildStep.logger);
  if (compileComponentsData.isEmpty) {
    return new TemplateCompilerOutputs(null, ngDepsModel);
  }
  for (final component in compileComponentsData) {
    final normalizedComp = await templateCompiler.normalizeDirectiveMetadata(
      component.component,
    );
    final normalizedDirs = await Future.wait(component.directives.map((d) {
      return templateCompiler.normalizeDirectiveMetadata(d);
    }));
    component
      ..component = normalizedComp
      ..directives = normalizedDirs;
  }
  final compiledTemplates = logElapsedSync(() {
    return templateCompiler.compile(compileComponentsData);
  }, operationName: 'compile', assetId: buildStep.inputId);

  return new TemplateCompilerOutputs(compiledTemplates, ngDepsModel);
}
