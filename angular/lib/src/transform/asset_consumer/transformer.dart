library angular2.transform.asset_consumer.transformer;

import 'package:barback/barback.dart';
import 'package:angular/src/transform/common/names.dart';

/// Transformer which deletes all pre-existing generated angular code.
class AssetConsumer extends Transformer {
  AssetConsumer();

  /// Ctor which tells pub that this can be run as a standalone transformer.
  AssetConsumer.asPlugin(BarbackSettings _);

  @override
  dynamic isPrimary(AssetId id) => isGenerated(id.path);

  @override
  apply(Transform transform) {
    transform.consumePrimary();
  }
}
