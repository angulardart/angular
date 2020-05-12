import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart' show TypeReference;
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import 'common.dart';

final TypeReference _dynamic = TypeReference((b) => b
  ..symbol = 'dynamic'
  ..url = 'dart:core');

/// Returns as a `code_builder` [TypeReference] for code generation.
TypeReference linkToReference(TypeLink link, LibraryReader library) {
  if (link.isDynamic || link.isPrivate) {
    return _dynamic;
  }
  return TypeReference((b) => b
    ..symbol = link.symbol
    ..url = library.pathToUrl(link.import).toString()
    ..types.addAll(link.generics.map((t) => linkToReference(t, library))));
}

DartType _resolveBounds(DartType type) {
  return type is TypeParameterType ? _resolveBounds(type.bound) : type;
}

/// Returns a [TypeLink] to the given statically analyzed [DartType].
TypeLink linkTypeOf(DartType type) {
  // Return void or Null types.
  if (type.isVoid) {
    return TypeLink.$void;
  }
  if (type.isDartCoreNull) {
    return TypeLink.$null;
  }
  // Return dynamic type (no type found or type is unusable/inaccessible).
  //
  // For example, there are missing imports, we are referring to a FunctionType
  // that does not come from a typedef, it is the type of a top-level function
  // and that type was not inferred previously by the analyzer. A more proper
  // fix from Angular would be to support function types (for now dynamic only).
  if (type.isDynamic || type.element?.library == null) {
    return TypeLink.$dynamic;
  }
  type = _resolveBounds(type);
  // Return dynamic type (no type found) after _resolveBounds.
  if (type.element.library == null) {
    return TypeLink.$dynamic;
  }
  return TypeLink(
    getTypeName(type),
    getTypeImport(type),
    type is ParameterizedType
        ? type.typeArguments.map(linkTypeOf).toList()
        : const [],
  );
}

/// An abstraction over pointing to a type in a given Dart source file.
///
/// In `package:source_gen` (and elsewhere) we sometimes refer to types by
/// URL, such as `dart:core#String`. This breaks down once there is a generic
/// type, such as `List<String>`.
///
/// [TypeLink] is a way to represent this type so it may be used for codegen.
class TypeLink {
  /// Represents the type of `dynamic` (i.e. omitted type).
  static const $dynamic = TypeLink('dynamic', null);

  /// Represents the type of `void`.
  static const $void = TypeLink('void', 'dart:core');

  /// Represents the type of `Null`.
  static const $null = TypeLink('Null', 'dart:core');

  /// Name of the symbol for the type, such as `String`.
  final String symbol;

  /// Import path needed to refer to this type. May be `null` for none needed.
  final String import;

  /// Generic types, used to represent types such as `List<String>`.
  final List<TypeLink> generics;

  const TypeLink(
    this.symbol,
    this.import, [
    this.generics = const [],
  ]);

  static const _list = ListEquality();

  @override
  bool operator ==(Object o) {
    if (o is TypeLink) {
      return symbol == o.symbol &&
          import == o.import &&
          _list.equals(generics, o.generics);
    }
    return false;
  }

  @override
  int get hashCode => symbol.hashCode ^ import.hashCode ^ _list.hash(generics);

  /// Whether this is considered `dynamic`.
  bool get isDynamic => this == $dynamic;

  /// Whether this is a private type.
  bool get isPrivate => symbol.startsWith('_');

  @override
  String toString() => 'TypeLink {$import:$symbol<$generics>}';

  /// Returns as the older [Url] format, omitting any [generics].
  ///
  /// This should be used for migration purposes off [Url] only.
  Uri toUrlWithoutGenerics() => Uri.parse('$import#$symbol');

  /// Returns as a [TypeLink] without generic type arguments.
  TypeLink withoutGenerics() => TypeLink(symbol, import);
}
