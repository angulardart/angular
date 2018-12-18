import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:angular/src/source_gen/common/ng_compiler.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:angular_compiler/cli.dart';

import 'template_compiler_outputs.dart';

Future<TemplateCompilerOutputs> processTemplates(
  LibraryElement element,
  BuildStep buildStep,
  CompilerFlags flags,
) async {
  final reflectables = await _resolveReflectables(flags, buildStep, element);
  final injectors = InjectorReader.findInjectors(element);

  final compiler = createAngularCompiler(buildStep, flags);
  final sourceModule = await compiler.compile(element);

  return TemplateCompilerOutputs(
    sourceModule,
    reflectables,
    injectors,
  );
}

Future<ReflectableOutput> _resolveReflectables(
    CompilerFlags flags, BuildStep buildStep, LibraryElement element) {
  final reader = ReflectableReader(
    recordInjectableFactories: flags.emitInjectableFactories,
    recordComponentFactories: flags.emitComponentFactories,
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
          AssetId.resolve(uri, from: buildStep.inputId),
        );
      }
      final placeholder = ''
          '${uri.substring(0, uri.length - '.dart'.length)}'
          '.ng_placeholder';
      return buildStep.canRead(
        AssetId.resolve(placeholder, from: buildStep.inputId),
      );
    },
    // For a given import or export directive, return whether a generated
    // .template.dart file already exists. If it does we will need to link
    // to it and call initReflector().
    isLibrary: (uri) => buildStep.resolver
        .isLibrary(AssetId.resolve(uri, from: buildStep.inputId)),
  );

  return reader.resolve(element);
}
