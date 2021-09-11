import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';

part 'model.g.dart';

@SerializersFor([
  InspectorNode,
  InspectorDirective,
])
final Serializers serializers = _$serializers;

/// The data model for a node with Angular artifacts.
abstract class InspectorNode
    implements Built<InspectorNode, InspectorNodeBuilder> {
  static Serializer<InspectorNode> get serializer => _$inspectorNodeSerializer;

  factory InspectorNode([void Function(InspectorNodeBuilder) updates]) =
      _$InspectorNode;
  InspectorNode._();

  /// The component hosted on this node, if one exists.
  ///
  /// Null if this node doesn't host a component.
  InspectorDirective? get component;

  /// The directives applied to this node.
  BuiltList<InspectorDirective> get directives;

  /// The direct children of this node.
  ///
  /// This contains both view (template) and content (projected) children.
  BuiltList<InspectorNode> get children;
}

/// The data model for a directive instance.
abstract class InspectorDirective
    implements Built<InspectorDirective, InspectorDirectiveBuilder> {
  static Serializer<InspectorDirective> get serializer =>
      _$inspectorDirectiveSerializer;

  factory InspectorDirective(
          [void Function(InspectorDirectiveBuilder) updates]) =
      _$InspectorDirective;
  InspectorDirective._();

  /// A string representation of the directive's runtime type.
  String get name;

  /// A unique identifier for the directive instance.
  int get id;

  /// Set to a non-null value in order to initialize [id] with a default value.
  ///
  /// This facilitates comparing values by equality without inadvertantly
  /// testing the implementation details of ID generation.
  @visibleForTesting
  static int? defaultIdForTesting;

  @BuiltValueHook(initializeBuilder: true)
  static void _initialize(InspectorDirectiveBuilder b) {
    if (defaultIdForTesting != null) {
      b.id = defaultIdForTesting;
    }
  }
}
