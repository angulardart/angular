import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/compiler/config.dart';
import 'package:angular2/src/compiler/offline_compiler.dart';
import 'package:angular2/src/source_gen/common/logging.dart';
import 'package:angular2/src/source_gen/common/ng_compiler.dart';
import 'package:build/build.dart';

import 'find_components.dart';
import 'ng_deps_visitor.dart';
import 'template_compiler_outputs.dart';

// Because buildStep.hasInput() does not currently work as needed, we instead
// track the inputs ourselves. Thus, we await for all of the inputs to be
// collected, before continuing. This only works because of implementation
// details in package:build which will probably change, so it is recommended
// that you do not copy this.
final Set<AssetId> assets = new Set();

Future<TemplateCompilerOutputs> processTemplates(
    LibraryElement element, BuildStep buildStep, CompilerConfig config,
    {bool collectAssets: true}) async {
  final templateCompiler = createTemplateCompiler(buildStep, config);
  final resolver = await buildStep.resolver;
  final ngDepsModel = await logElapsedAsync(
    () => resolveNgDepsFor(element,
        // For a given import or export directive, return whether we have the
        // Dart file's URI in our inputs (for Bazel, it will be in the srcs =
        // [ ... ]).
        //
        // For example, if the template processor is running on an input set
        // of generate_for = [a.dart, b.dart], and we are currently running on
        // a.dart, and a.dart imports b.dart, we can assume that there will be
        // a generated b.template.dart that we need to import/initReflector().
        hasInput: (uri) async {
          final asset = new AssetId.resolve(uri, from: buildStep.inputId);
          return collectAssets
              ? assets.contains(asset)
              : await buildStep.hasInput(asset);
        },
        // For a given import or export directive, return whether a generated
        // .template.dart file already exists. If it does we will need to link
        // to it and call initReflector().
        isLibrary: (uri) => resolver
            .isLibrary(new AssetId.resolve(uri, from: buildStep.inputId))),
    operationName: 'extractNgDepsModel',
    assetId: buildStep.inputId,
    log: log,
  );

  final List<NormalizedComponentWithViewDirectives> compileComponentsData =
      logElapsedSync(() => findComponents(element),
          operationName: 'findComponents',
          assetId: buildStep.inputId,
          log: log);
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
