import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/utils.dart';

import '../../cli/logging.dart';
import '../common.dart';
import '../link.dart';
import '../types.dart';

// TODO(leonsenft): ensure failure messages have an actionable context.
class TypedReader {
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
          'A type argument must be one of the following:\n'
          '  * Type\n'
          '  * Typed\n'
          '  * Symbol\n');
    }
  }

  TypeLink _parseSymbol(DartObject symbolObject) => null;

  TypeLink _parseType(DartObject typeObject) => null;

  TypeLink _parseTyped(DartObject typedObject) {
    final type = typeArgumentOf(typedObject);
    if (type is ParameterizedType) {
      final constant = ConstantReader(typedObject).read('typeArguments');
      final typeArguments = constant.isList
          ? constant.listValue.map((o) => _parse(o))
          : type.typeArguments.map((t) => linkTypeOf(t));
      return new TypeLink(
        getTypeName(type),
        normalizeUrl(type.element.library.source.uri).toString(),
        typeArguments.toList(),
      );
    } else {
      throwFailure('Only parameterized types may be bound to `Typed`.');
    }
  }
}
