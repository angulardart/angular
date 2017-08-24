import 'dart:async';

import 'package:barback/barback.dart';
import 'package:angular/src/transform/common/names.dart';
import 'package:angular/src/transform/common/zone.dart' as zone;
import 'package:angular_compiler/angular_compiler.dart';

import 'processor.dart';

/// Pre-compiles CSS stylesheet files to Dart code for Angular 2.
class StylesheetCompiler extends Transformer implements LazyTransformer {
  final CompilerFlags _flags;

  StylesheetCompiler(this._flags);

  @override
  bool isPrimary(AssetId id) {
    return id.path.endsWith(CSS_EXTENSION);
  }

  @override
  declareOutputs(DeclaringTransform transform) {
    // Note: we check this assumption below.
    _getExpectedOutputs(transform.primaryId).forEach(transform.declareOutput);
  }

  List<AssetId> _getExpectedOutputs(AssetId cssId) =>
      [shimmedStylesheetAssetId(cssId), nonShimmedStylesheetAssetId(cssId)];

  @override
  Future apply(Transform transform) async {
    final reader = new NgAssetReader.fromBarback(transform);
    return zone.exec(() async {
      var primaryId = transform.primaryInput.id;
      var outputs = await processStylesheet(reader, primaryId, _flags);
      var expectedIds = _getExpectedOutputs(primaryId);
      outputs.forEach((Asset compiledStylesheet) {
        var id = compiledStylesheet.id;
        if (!expectedIds.contains(id)) {
          throw new StateError(
              'Unexpected output for css processing of $primaryId: $id');
        }
        transform.addOutput(compiledStylesheet);
      });
    }, log: transform.logger);
  }
}
