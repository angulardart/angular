import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/utils.dart';

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
    AstNode astNode;
    // TODO(matanl): https://b2.corp.google.com/issues/67906224.
    try {
      astNode = element.computeNode();
    } catch (_) {
      return null;
    }
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
  if (object.type.typeArguments.isEmpty) {
    return DynamicTypeImpl.instance;
  }
  return object.type.typeArguments[index];
}

/// Returns a canonical URL pointing to [element].
///
/// For example, `List` would be `'dart:core#List'`.
Uri urlOf(Element element, [String name]) {
  if (element?.source == null) {
    return new Uri(scheme: 'dart', path: 'core', fragment: 'dynamic');
  }
  name ??= element.name;
  // NOTE: element.source.uri might be a file that is not importable (i.e. is
  // a "part"), while element.library.source.uri is always importable.
  return normalizeUrl(element.library.source.uri).replace(fragment: name);
}
