import 'package:meta/meta.dart';

/// A defined set of elements.
abstract class NgTemplateSchema {
  /// Create a schema of [elements].
  ///
  /// ## Example
  ///     // An example of using Polymer paper widgets.
  ///     const NgTemplateSchema({
  ///       'paper-button': const NgElementSchema(
  ///         'paper-button',
  ///         events: ...,
  ///         properties: ...,
  ///       ),
  ///       ...
  ///     })
  @literal
  const factory NgTemplateSchema(Map<String, NgTemplateSchema> elements) = _NgTemplateSchema;

  /// Known elements in the schema.
  Map<String, NgTemplateSchema> get elements;
}

class _NgTemplateSchema implements NgTemplateSchema {
  @override
  final Map<String, NgTemplateSchema> elements;

  const _NgTemplateSchema(this.elements);
}

/// A defined set of events and properties of an element.
abstract class NgElementSchema {
  /// Create a definition of an element with [tagName].
  ///
  /// ## Example
  ///     // A native "button" element.
  ///     const NgElementSchema(
  ///       'button',
  ///       events: const {
  ///         'click': const NgEventDefinition(...)
  ///       },
  ///       properties: const {
  ///         'title': const NgPropertyDefinition(...),
  ///       },
  ///     )
  @literal
  const factory NgElementSchema(String tagName, {
    Map<String, NgEventDefinition> events,
    Map<String, NgPropertyDefinition> properties,
  }) = _NgElementSchema;

  /// Known events on the element.
  Map<String, NgEventDefinition> get events;

  /// Known properties on the element.
  Map<String, NgPropertyDefinition> get properties;

  /// Name of the element.
  String get tagName;
}

class _NgElementSchema implements NgElementSchema {
  @override
  final Map<String, NgEventDefinition> events;

  @override
  final Map<String, NgPropertyDefinition> properties;

  @override
  final String tagName;

  @literal
  const _NgElementSchema(this.tagName, {
    this.events: const {},
    this.properties: const {},
  });
}

/// A defined set of properties on an [NgElementSchema].
abstract class NgPropertyDefinition {
  /// Create a definition of a property [name] that has a [type].
  ///
  /// ## Example
  ///     // A native "text" property.
  ///     const NgPropertyDefinition(
  ///       'text',
  ///       const NgTypeReference.dartSdk('core', 'String'),
  ///     )
  @literal
  const factory NgPropertyDefinition(String name, [NgTypeReference type]) = _NgPropertyDefinition;

  /// Name of the property.
  String get name;

  /// A reference to a Dart type passed as the value of the event.
  NgTypeReference get type;
}

class _NgPropertyDefinition implements NgPropertyDefinition {
  @override
  final String name;

  @override
  final NgTypeReference type;

  @literal
  const _NgPropertyDefinition(this.name, [this.type]);
}

/// A defined set of events on an [NgElementSchema].
abstract class NgEventDefinition {
  /// Create a definition of an event [name] that emits a [type].
  ///
  /// ## Example
  ///     // A native DOM "click" event.
  ///     const NgEventDefinition(
  ///       'click',
  ///       const NgTypeReference.dartsdk('html', 'MouseEvent'),
  ///     )
  /// 
  ///     // A custom "closed" event.
  ///     const NgEventDefinition(
  ///       'closed',
  ///       const NgTypeReference('material/lib/material.dart', 'CloseEvent'),
  ///     )
  @literal
  const factory NgEventDefinition(String name, [NgTypeReference type]) = _NgEventDefinition;

  /// Name of the event.
  String get name;

  /// A reference to a Dart type passed as the value of the event.
  NgTypeReference get type;
}

class _NgEventDefinition implements NgEventDefinition {
  @override
  final String name;

  @override
  final NgTypeReference type;

  @literal
  const _NgEventDefinition(this.name, [this.type]);
}

/// A reference to a Dart type.
abstract class NgTypeReference {
  /// Create a reference to an `asset` reference to an external package.
  ///
  /// ## Example
  ///     // assert:quiver/lib/time.dart#Clock
  ///     const NgTypeReference('quiver/lib/time.dart', 'Clock')
  @literal
  const factory NgTypeReference(
    String path,
    String identifier, [
    List<NgTypeReference> types,
  ]) = _NgTypeReference;

  /// Create a reference to a `dart` SDK reference.
  /// 
  /// ## Example
  ///     // dart:core#String
  ///     const NgTypeReference.dartSdk('core', 'String')
  /// 
  ///     // dart:core#List<String>
  ///     const NgTypeReference.dartSdk('core', 'List', const [
  ///       const NgTypeReference.dartSdk('core', 'String'),
  ///     ])
  @literal
  const factory NgTypeReference.dartSdk(
    String path, 
    String identifier, [
    List<NgTypeReference> types,
  ]) = _NgTypeReference.dartSdk;

  /// Identifier.
  String get identifier;

  /// Package and file path.
  String get path;

  /// Which scheme to access the [path].
  String get scheme;

  /// Return as a Uri.
  Uri toUri();

  /// Which generic types are part of this type.
  List<NgTypeReference> get types;
}

class _NgTypeReference implements NgTypeReference {
  @override
  final String identifier;

  @override
  final String path;

  @override
  final String scheme;

  @override
  final List<NgTypeReference> types;

  @literal
  const _NgTypeReference(
    this.path,
    this.identifier, [
    this.types = const [],
  ]) 
      : this.scheme = 'assert';

  @literal
  const _NgTypeReference.dartSdk(
    this.path,
    this.identifier, [
    this.types = const [],
  ])
      : this.scheme = 'dart';

  @override
  Uri toUri() {
    String fragment = identifier;
    if (types.isNotEmpty) {
      fragment = types.map/*<String>*/((t) => t.toUri().toString()).join(', ');
    }
    return new Uri(
      fragment: fragment,
      path: path,
      scheme: scheme,
    );
  }
}
