import 'dart:async';

import 'package:barback/barback.dart';
import 'package:angular/src/transform/common/zone.dart' as zone;
import 'package:angular_compiler/angular_compiler.dart';

import 'remove_reflection_capabilities.dart';

/// Transformer responsible for removing the import and instantiation of
/// {@link ReflectionCapabilities}.
///
/// The goal of this is to break the app's dependency on dart:mirrors.
///
/// This transformer assumes that {@link DirectiveProcessor} and {@link DirectiveLinker}
/// have already been run and that a .template.dart file has been generated for
/// {@link options.entryPoint}. The instantiation of {@link ReflectionCapabilities} is
/// replaced by calling `initReflector` in that .template.dart file.
class ReflectionRemover extends Transformer implements LazyTransformer {
  final CompilerFlags _flags;

  ReflectionRemover(this._flags);

  /// Ctor which tells pub that this can be run as a standalone transformer.
  factory ReflectionRemover.asPlugin(BarbackSettings settings) =>
      new ReflectionRemover(new CompilerFlags.parseBarback(settings));

  @override
  bool isPrimary(AssetId id) =>
      _flags.entryPoints != null &&
      _flags.entryPoints.any((g) => g.matches(id.path));

  @override
  declareOutputs(DeclaringTransform transform) {
    transform.declareOutput(transform.primaryId);
  }

  @override
  Future apply(Transform transform) async {
    return zone.exec(() async {
      var primaryId = transform.primaryInput.id;
      var transformedCode = await removeReflectionCapabilities(
        new NgAssetReader.fromBarback(transform),
        primaryId,
      );
      transform.addOutput(new Asset.fromString(primaryId, transformedCode));
    }, log: transform.logger);
  }
}
