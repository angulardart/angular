import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../../../cli.dart';
import '../common.dart';
import '../link.dart';
import '../types.dart';

/// A statically parsed `Typed` used to specify type arguments on a directive.
class TypedElement {
  /// An optional identifier used to select specific instances of the directive.
  final String on;

  /// The fully typed directive's type.
  final TypeLink typeLink;

  TypedElement(this.typeLink, {this.on});

  @override
  int get hashCode => on.hashCode ^ typeLink.hashCode;

  @override
  bool operator ==(Object o) {
    if (o is TypedElement) {
      return on == o.on && typeLink == o.typeLink;
    }
    return false;
  }
}

/// Parses types from compile-time constant `Typed` expressions.
class TypedReader {
  final ClassElement _hostElement;

  /// Creates a reader for parsing `Typed` values associated with a host class.
  ///
  /// It's required that any type parameter referenced via [Symbol] be declared
  /// by the host class. For example, parsing `Typed<List>.of([#X])` requires
  /// that the host class has a type parameter `X`.
  TypedReader(this._hostElement);

  /// Parses the value of a compile-time constant `Typed` expression.
  TypedElement parse(DartObject typedObject) {
    if (!$Typed.isExactlyType(typedObject.type)) {
      final typeStr = typeToCode(typedObject.type);
      throwFailure(''
          'Expected an expression of type "Typed", but got "$typeStr"');
    }
    return _parseTyped(typedObject, root: true);
  }

  /// Parses the value of a compile-time constant [object].
  TypeLink _parse(DartObject object) {
    final constant = ConstantReader(object);
    if (constant.instanceOf($Typed)) {
      return _parseTyped(object).typeLink;
    } else if (constant.isSymbol) {
      return _parseSymbol(object);
    } else if (constant.isType) {
      return _parseType(object);
    } else {
      throwFailure(''
          'Expected a type argument of "Typed" to be of one of the following '
          'types:\n'
          '  * "Symbol"\n'
          '  * "Type"\n'
          '  * "Typed"\n'
          'Got an expression of type "${typeToCode(object.type)}".');
    }
  }

  /// Parses a [Symbol], e.g. `#X`.
  TypeLink _parseSymbol(DartObject symbolObject) {
    final symbol = symbolObject.toSymbolValue();
    // Check that the host component has a matching type parameter to flow.
    if (!_hostElement.typeParameters.any((p) => p.name == symbol)) {
      throwFailure(''
          'Attempted to flow a type parameter "$symbol", but '
          '"${_hostElement.name}" declares no such generic type parameter');
    }
    return TypeLink(symbol, null);
  }

  /// Parses a [Type], e.g. `String`.
  TypeLink _parseType(DartObject typeObject) =>
      linkTypeOf(typeObject.toTypeValue());

  /// Parses a [Typed], e.g. `Typed<List<String>>()`.
  ///
  /// [root] is true when [typedObject] represents the root `Typed` instance
  /// of a `Typed` expression.
  TypedElement _parseTyped(DartObject typedObject, {bool root = false}) {
    final type = typeArgumentOf(typedObject);
    if (type is ParameterizedType && type.typeParameters.isNotEmpty) {
      if (root && !$Directive.hasAnnotationOf(type.element)) {
        throwFailure(''
            'Expected a "Typed" expression with a "Component" or "Directive" '
            'annotated type, but got "Typed<${type.name}>"');
      }
      String on;
      final reader = ConstantReader(typedObject);
      final onReader = reader.read('on');
      if (onReader.isString) {
        if (!root) {
          throwFailure(''
              'The "on" argument is only supported on the root "Typed" of a '
              '"Typed" expression');
        }
        on = onReader.stringValue;
      }
      // If the named constructor `Typed.of()` was used to specify type
      // arguments, we parse them from the `typeArguments` field. Otherwise, we
      // use the type arguments of the type itself.
      final typeArgumentsReader = reader.read('typeArguments');
      final typeArguments = typeArgumentsReader.isList
          ? typeArgumentsReader.listValue.map(_parse).toList()
          : type.typeArguments.map(linkTypeOf).toList();
      for (final typeArgument in typeArguments) {
        if (typeArgument.isPrivate) {
          throwFailure(''
              'Directive type arguments must be public, but "${type.name}" was '
              'given private type argument "${typeArgument.symbol}" by '
              '"${_hostElement.name}".');
        }
      }
      return TypedElement(
        TypeLink(
          getTypeName(type),
          getTypeImport(type),
          typeArguments,
        ),
        on: on,
      );
    } else {
      throwFailure(''
          'Expected a generic type to be used as a type argument of "Typed", '
          'but got concrete type "${typeToCode(type)}". A concrete type may be'
          'used directly as a type argument without the need for "Typed".');
    }
  }
}
