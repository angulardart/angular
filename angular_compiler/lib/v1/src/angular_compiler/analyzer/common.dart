import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:source_gen/src/utils.dart';

/// Returns the import URL for [type].
String getTypeImport(DartType type) {
  var aliasElement = type.alias?.element;
  if (aliasElement != null) {
    return normalizeUrl(aliasElement.library.source.uri).toString();
  }
  if (type is DynamicType) {
    return 'dart:core';
  }
  if (type is InterfaceType) {
    return normalizeUrl(type.element.library.source.uri).toString();
  }
  throw UnimplementedError('(${type.runtimeType}) $type');
}

/// Forwards and backwards-compatible method of getting the "name" of [type].
String? getTypeName(DartType type) {
  var aliasElement = type.alias?.element;
  if (aliasElement != null) {
    return aliasElement.name;
  }
  if (type is DynamicType) {
    return 'dynamic';
  }
  if (type is FunctionType) {
    return null;
  }
  if (type is InterfaceType) {
    return type.element.name;
  }
  if (type is VoidType) {
    return 'void';
  }
  throw UnimplementedError('(${type.runtimeType}) $type');
}

/// Returns the bound [DartType] from the instance [object].
///
/// For example for the following code:
/// ```
/// const foo = const <String>[];
/// const bar = const ['A string'];
/// ```
///
/// ... both `foo` and `bar` should return the [DartType] for `String`.
DartType typeArgumentOf(DartObject object, [int index = 0]) {
  var type = object.type;
  if (type is ParameterizedType) {
    var typeArguments = type.typeArguments;
    if (typeArguments.isNotEmpty) {
      return type.typeArguments[index];
    }
  }
  return DynamicTypeImpl.instance;
}

String? typeToCode(DartType? type) {
  if (type == null) {
    return null;
  } else if (type.isDynamic) {
    return 'dynamic';
  } else if (type is InterfaceType) {
    var typeArguments = type.typeArguments;
    if (typeArguments.isEmpty) {
      return type.element.name;
    } else {
      final typeArgumentsStr = typeArguments.map(typeToCode).join(', ');
      return '${type.element.name}<$typeArgumentsStr>';
    }
  } else if (type is TypeParameterType) {
    return type.element.name;
  } else if (type.isVoid) {
    return 'void';
  } else {
    throw UnimplementedError('(${type.runtimeType}) $type');
  }
}

/// Returns a canonical URL pointing to [element].
///
/// For example:
///  * `List` would be `'dart:core#List'`,
///  * `Duration.zero` would be `'dart:core#Duration.zero'`.
Uri urlOf(Element? element, [String? name]) {
  if (element?.source == null) {
    return Uri(scheme: 'dart', path: 'core', fragment: 'dynamic');
  }

  var fragment = name ?? element!.name;
  final enclosing = element!.enclosingElement;
  if (enclosing is ClassElement) {
    fragment = '${enclosing.name}.$fragment';
  }

  // NOTE: element.source.uri might be a file that is not importable (i.e. is
  // a "part"), while element.library.source.uri is always importable.
  return normalizeUrl(element.library!.source.uri).replace(fragment: fragment);
}
