import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular/src/compiler/offline_compiler.dart';
import 'package:angular/src/source_gen/common/logging.dart';
import 'package:angular/src/source_gen/common/ng_compiler.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:angular_compiler/cli.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'find_components.dart';
import 'template_compiler_outputs.dart';

Future<TemplateCompilerOutputs> processTemplates(
  LibraryElement element,
  BuildStep buildStep,
  CompilerFlags flags,
) async {
  final templateCompiler = createTemplateCompiler(buildStep, flags);
  final resolver = buildStep.resolver;
  final reflectables = await new ReflectableReader(
    // For a given import or export directive, return whether we have the
    // Dart file's URI in our inputs (for Bazel, it will be in the srcs =
    // [ ... ]).
    //
    // For example, if the template processor is running on an input set
    // of generate_for = [a.dart, b.dart], and we are currently running on
    // a.dart, and a.dart imports b.dart, we can assume that there will be
    // a generated b.template.dart that we need to import/initReflector().
    hasInput: (uri) async {
      if (flags.ignoreNgPlaceholderForGoldens) {
        return buildStep.canRead(
          new AssetId.resolve(uri, from: buildStep.inputId),
        );
      }
      final placeholder = ''
          '${uri.substring(0, uri.length - '.dart'.length)}'
          '.ng_placeholder';
      return buildStep.canRead(
        new AssetId.resolve(placeholder, from: buildStep.inputId),
      );
    },
    // For a given import or export directive, return whether a generated
    // .template.dart file already exists. If it does we will need to link
    // to it and call initReflector().
    isLibrary: (uri) =>
        resolver.isLibrary(new AssetId.resolve(uri, from: buildStep.inputId)),
  ).resolve(element);
  final AngularArtifacts compileComponentsData = logElapsedSync(
      () => findComponentsAndDirectives(new LibraryReader(element)),
      operationName: 'findComponents',
      assetId: buildStep.inputId,
      log: log);
  if (compileComponentsData.isEmpty) {
    return new TemplateCompilerOutputs(
      null,
      reflectables,
      InjectorReader.findInjectors(element),
    );
  }

  // Normalize directive meta data for component and directives.
  for (final component in compileComponentsData.components) {
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
  }, operationName: 'compile', assetId: buildStep.inputId, log: log);

  return new TemplateCompilerOutputs(
    compiledTemplates,
    reflectables,
    InjectorReader.findInjectors(element),
  );
}
