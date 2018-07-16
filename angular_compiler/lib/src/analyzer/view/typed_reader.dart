import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../../../cli.dart';
import '../common.dart';
import '../link.dart';
import '../types.dart';

// TODO(leonsenft): ensure failure messages have an actionable context.
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
  ///
  /// Returns a [TypeLink] that represents the type defined by [typedObject].
  TypeLink parse(DartObject typedObject) {
    if (!$Typed.isExactlyType(typedObject.type)) {
      throwFailure(''
          'Expected an expression of type "Typed", but got '
          '"${typedObject.type}"');
    }
    return _parseTyped(typedObject);
  }

  /// Parses the value of a compile-time constant [object].
  TypeLink _parse(DartObject object) {
    final constant = ConstantReader(object);
    if (constant.instanceOf($Typed)) {
      return _parseTyped(object);
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
          'Got an expression of type "${object.type}".');
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
  TypeLink _parseTyped(DartObject typedObject) {
    final type = typeArgumentOf(typedObject);
    if (type is ParameterizedType && type.typeParameters.isNotEmpty) {
      // If the named constructor `Typed.of()` was used to specify type
      // arguments, we parse them from the `typeArguments` field. Otherwise, we
      // use the type arguments of the type itself.
      final constant = ConstantReader(typedObject).read('typeArguments');
      final typeArguments = constant.isList
          ? constant.listValue.map(_parse).toList()
          : type.typeArguments.map(linkTypeOf).toList();
      return TypeLink(getTypeName(type), getTypeImport(type), typeArguments);
    } else {
      throwFailure(''
          'Expected a generic type to be used as a type argument of "Typed", '
          'but got concrete type "$type". A concrete type may be used directly '
          'as a type argument without the need for "Typed".');
    }
  }
}
