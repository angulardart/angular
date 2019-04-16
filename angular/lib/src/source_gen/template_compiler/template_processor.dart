import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:angular/src/compiler/module/ng_compiler_module.dart';
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
  /// Resolves the URI in the context of [buildStep]. Returns null if the
  /// URI is unsupported.
  AssetId tryResolvedAsset(String uri) {
    try {
      return AssetId.resolve(uri, from: buildStep.inputId);
    } on UnsupportedError catch (_) {
      return null;
    }
  }

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
        final AssetId assetId = tryResolvedAsset(uri);
        if (_assetNotResolved(assetId)) {
          return false;
        }
        return buildStep.canRead(assetId);
      }
      final placeholder = tryResolvedAsset(''
          '${uri.substring(0, uri.length - '.dart'.length)}'
          '.ng_placeholder');
      if (_assetNotResolved(placeholder)) {
        return false;
      }
      return buildStep.canRead(placeholder);
    },
    // For a given import or export directive, return whether a generated
    // .template.dart file already exists. If it does we will need to link
    // to it and call initReflector().
    isLibrary: (uri) {
      final AssetId assetId = tryResolvedAsset(uri);
      if (_assetNotResolved(assetId)) {
        return Future.value(false);
      }
      return buildStep.resolver.isLibrary(assetId);
    },
  );

  return reader.resolve(element);
}

bool _assetNotResolved(AssetId id) => id == null;
