import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/utils.dart';

/// Returns the inheritance hierarchy of [type] in an ordered list.
///
/// Types are followed, in order, by their mixins, interfaces, and superclass.
List<InterfaceType> getInheritanceHierarchy(InterfaceType type) {
  final types = <InterfaceType>[];
  final typesToVisit = [type];
  final visitedTypes = new Set<InterfaceType>();
  while (typesToVisit.isNotEmpty) {
    final currentType = typesToVisit.removeLast();
    if (visitedTypes.contains(currentType)) continue;
    visitedTypes.add(currentType);
    final supertype = currentType.superclass;
    // Skip [Object], since it can't have metadata, mixins, or interfaces.
    if (supertype == null) continue;
    types.add(currentType);
    typesToVisit
      ..add(supertype)
      ..addAll(currentType.interfaces)
      ..addAll(currentType.mixins);
  }
  return types;
}

/// Forwards and backwards-compatible method of getting the "name" of [type].
String getTypeName(DartType type) {
  // Crux of the issue is that the latest dart analyzer/kernel/frontend does not
  // retain the name of a typedef, for example:
  //   typedef void InterestingFn();
  //
  // Is retained as "typedef InterestingFn = void Function()", where the
  // DartType itself no longer has a "name" property (it always returns null).
  if (type is FunctionType) {
    final element = type.element;
    if (element is GenericFunctionTypeElement) {
      return element.enclosingElement.name;
    }
  }
  return type.name;
}

/// Returns the prefix used to decorate [element], if imported with one.
String prefixOf(Element element) {
  String identifier;
  if (element is ParameterElement) {
    final astNode = element.computeNode();
    if (astNode is DefaultFormalParameter) {
      identifier = _identifierOfAst(astNode.parameter, element);
    } else {
      identifier = _identifierOfAst(astNode, element);
    }
  } else if (element is FunctionElement) {
    identifier = element.computeNode()?.returnType?.toSource();
  }
  if (identifier == null) {
    return null;
  } else {
    // Remove generics.
    identifier = identifier.split('<').first;
  }
  final prefixDot = identifier.indexOf('.');
  if (prefixDot != -1) {
    return identifier.substring(0, prefixDot + 1);
  }
  return null;
}

String _identifierOfAst(AstNode astNode, ParameterElement element) {
  if (astNode is SimpleFormalParameter) {
    return astNode?.type?.toSource();
  } else if (astNode is FieldFormalParameter) {
    final parameter = element as FieldFormalParameterElement;
    final clazz = (element.enclosingElement.enclosingElement) as ClassElement;
    final fieldElement = clazz.getField(parameter.name);
    if (fieldElement == null) {
      log.severe(spanForElement(element).message(
          'Could not find corresponding field "${parameter.name}" in class '
          '"${clazz.name}".'));
      return null;
    }
    final field = fieldElement.computeNode();
    return ((field as VariableDeclaration).parent as VariableDeclarationList)
        ?.type
        ?.toSource();
  }
  return null;
}

/// Returns a canonical URL pointing to [element].
///
/// For example, `List` would be `'dart:core#List'`.
Uri urlOf(Element element, [String name]) {
  if (element?.source == null) {
    return new Uri(scheme: 'dart', path: 'core', fragment: 'dynamic');
  }
  name ??= element.name;
  return normalizeUrl(element.source.uri).replace(fragment: name);
}
