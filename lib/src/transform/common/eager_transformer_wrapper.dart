import 'package:barback/barback.dart';

abstract class EagerTransformerWrapper {
  EagerTransformerWrapper._();
  factory EagerTransformerWrapper(wrapped) {
    return wrapped is AggregateTransformer
        ? new _EagerAggregateTransformerWrapper(wrapped)
        : new _EagerTransformerWrapper(wrapped);
  }
}

class _EagerTransformerWrapper extends EagerTransformerWrapper
    implements Transformer {
  final Transformer _wrapped;
  _EagerTransformerWrapper(this._wrapped) : super._();

  @override
  String get allowedExtensions => _wrapped.allowedExtensions;

  @override
  dynamic apply(Transform transform) => _wrapped.apply(transform);

  @override
  bool isPrimary(AssetId id) => _wrapped.isPrimary(id);

  @override
  String toString() => _wrapped.toString();
}

class _EagerAggregateTransformerWrapper extends EagerTransformerWrapper
    implements AggregateTransformer {
  final AggregateTransformer _wrapped;
  _EagerAggregateTransformerWrapper(this._wrapped) : super._();

  @override
  dynamic apply(AggregateTransform transform) => _wrapped.apply(transform);

  @override
  dynamic classifyPrimary(AssetId id) => _wrapped.classifyPrimary(id);

  @override
  String toString() => _wrapped.toString();
}
