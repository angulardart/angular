import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/compiler/compile_metadata.dart';
import 'package:angular2/src/compiler/config.dart';
import 'package:angular2/src/compiler/offline_compiler.dart';
import 'package:angular2/src/source_gen/common/logging.dart';
import 'package:angular2/src/source_gen/common/ng_compiler.dart';
import 'package:angular2/src/transform/common/options.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'find_components.dart';
import 'find_injectable_modules.dart';

/// Generates `.template.dart` files to initialize the Angular2 system.
///
/// - Processes the input element using `findComponents`.
/// - Passes the resulting `NormalizedComponentWithViewDirectives` instance(s)
///   to the `TemplateCompiler` to generate compiled template(s) as a
///   `SourceModule`.
/// - [Eventually]Uses the resulting `NgDeps` object to generate code which
///   initializes the Angular2 reflective system.
class TemplateGenerator extends Generator {
  @override
  Future<String> generate(Element element, BuildStep buildStep) async {
    if (element is! LibraryElement) return null;
    var outputs = await processTemplates(element, buildStep);
    return outputs?.templatesSource?.source;
  }
}

Future<Outputs> processTemplates(Element element, BuildStep buildStep,
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
  if (compileComponentsData.isEmpty) return new Outputs._(null);
  await Future.forEach(compileComponentsData, (component) async {
    component.component =
        await templateCompiler.normalizeDirectiveMetadata(component.component);
  });
  List<CompileInjectorModuleMetadata> injectorDefinitions = logElapsedSync(
      () => findInjectableModules(buildStep, element),
      operationName: 'findInjectableModules',
      assetId: buildStep.input.id,
      log: buildStep.logger);
  final compiledTemplates = logElapsedSync(() {
    return templateCompiler.compile(compileComponentsData, injectorDefinitions);
  }, operationName: 'compile', assetId: buildStep.input.id);
  return new Outputs._(compiledTemplates);
}

class Outputs {
  final SourceModule templatesSource;

  Outputs._(this.templatesSource);
}
