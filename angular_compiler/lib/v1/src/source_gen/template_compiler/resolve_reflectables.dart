import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:angular_compiler/v1/angular_compiler.dart';
import 'package:angular_compiler/v1/cli.dart';

/// Given the provided library, returns the [ReflectableOutput].
///
/// This is a combination of classes, functions, and libraries that need to
/// be referenced and linked in the generator `initReflector()` function in each
/// `.template.dart` file.
Future<ReflectableOutput> resolveReflectables({
  required LibraryElement from,
  required CompilerFlags flags,
  required BuildStep buildStep,
}) {
  // Resolves the URI in the context of [buildStep].
  //
  // Returns null if the URI is unsupported.
  AssetId? tryResolvedAsset(String uri) {
    try {
      return AssetId.resolve(Uri.parse(uri), from: buildStep.inputId);
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
      final placeholder = tryResolvedAsset(_ngPlaceholderName(uri));
      if (placeholder == null) {
        return false;
      }
      return buildStep.canRead(placeholder);
    },
    // For a given import or export directive, return whether a generated
    // .template.dart file already exists. If it does we will need to link
    // to it and call initReflector().
    isLibrary: (uri) {
      final assetId = tryResolvedAsset(uri);
      if (assetId == null) {
        return Future.value(false);
      }
      return buildStep.resolver.isLibrary(assetId);
    },
  );

  return reader.resolve(from);
}

/// Given `a.dart` returns `a.ng_placeholder`.
String _ngPlaceholderName(String uri) {
  return p.setExtension(uri, '.ng_placeholder');
}
