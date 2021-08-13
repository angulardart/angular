import 'package:collection/collection.dart' show ListExtensions;
import 'package:meta/meta.dart';
import 'package:quiver/core.dart' show hash2, hash3, hashObjects;

/// The data model for a node with Angular artifacts.
@immutable
@sealed
class InspectorNode {
  InspectorNode({
    this.component,
    this.directives = const [],
    this.children = const [],
  });

  /// The component hosted on this node, if one exists.
  ///
  /// Null if this node doesn't host a component.
  final InspectorDirective? component;

  /// The directives applied to this node.
  final List<InspectorDirective> directives;

  /// The direct children of this node.
  ///
  /// This contains both view (template) and content (projected) children.
  final List<InspectorNode> children;

  /// Deserializes this from a [json] object.
  factory InspectorNode.fromJson(Object json) {
    final jsonObject = json as Map<String, Object>;
    return InspectorNode(
      component: _component(jsonObject),
      directives: _directives(jsonObject),
      children: _children(jsonObject),
    );
  }

  /// Serializes this to a JSON object.
  Map<String, Object> toJson() {
    final component = this.component;
    return {
      if (component != null) 'component': component.toJson(),
      if (directives.isNotEmpty)
        'directives': [for (final directive in directives) directive.toJson()],
      if (children.isNotEmpty)
        'children': [for (final child in children) child.toJson()],
    };
  }

  @override
  int get hashCode =>
      hash3(component, hashObjects(directives), hashObjects(children));

  @override
  bool operator ==(Object other) {
    return other is InspectorNode &&
        other.component == component &&
        other.directives.equals(directives) &&
        other.children.equals(children);
  }

  static InspectorDirective? _component(Map<String, Object> jsonObject) {
    return jsonObject.containsKey('component')
        ? InspectorDirective.fromJson(jsonObject.read('component'))
        : null;
  }

  static List<InspectorNode> _children(Map<String, Object> jsonObject) {
    final children = jsonObject.readOptional<List<Object>>('children', []);
    return [for (final child in children) InspectorNode.fromJson(child)];
  }

  static List<InspectorDirective> _directives(Map<String, Object> jsonObject) {
    final directives = jsonObject.readOptional<List<Object>>('directives', []);
    return [
      for (final directive in directives) InspectorDirective.fromJson(directive)
    ];
  }
}

/// The data model for a directive instance.
@immutable
@sealed
class InspectorDirective {
  InspectorDirective({required this.name, this.id = -1});

  /// A string representation of the directive's runtime type.
  final String name;

  /// A unique identifier for the directive instance.
  ///
  /// A default (meaningless) value of `-1` is reserved for testing.
  final int id;

  @override
  int get hashCode => hash2(name, id);

  @override
  bool operator ==(Object other) {
    return other is InspectorDirective && other.id == id && other.name == name;
  }

  /// Deserializes this from a [json] object.
  factory InspectorDirective.fromJson(Object json) {
    final jsonObject = json as Map<String, Object>;
    return InspectorDirective(
      name: jsonObject.read('name'),
      id: jsonObject.read('id'),
    );
  }

  /// Serializes this to a JSON object.
  Map<String, Object> toJson() {
    return {'name': name, 'id': id};
  }
}

/// A helper extension for reading key-value pairs from a JSON object.
extension _JsonObject on Map<String, Object> {
  /// Returns the value for [key] cast as [T].
  T read<T>(String key) {
    return this[key] as T;
  }

  /// Return the value for [key] cast as [T] if present.
  ///
  /// Returns [defaultTo] if this doesn't contain [key].
  T readOptional<T>(String key, T defaultTo) {
    return containsKey(key) ? this[key] as T : defaultTo;
  }
}
