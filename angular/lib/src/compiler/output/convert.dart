import 'package:analyzer/dart/element/type.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:source_gen/source_gen.dart';

import '../../source_gen/common/url_resolver.dart';
import '../compile_metadata.dart';
import 'output_ast.dart' as o;

/// Creates an AST for code generation from [dartType].
///
/// Note that private types aren't visible to generated code and will be
/// replaced with dynamic.
o.OutputType fromDartType(DartType dartType) {
  if (dartType.isVoid) return null;
  if (dartType is FunctionType) return fromFunctionType(dartType);
  if (dartType is TypeParameterType) {
    // Resolve generic type to its bound or dynamic if it has none.
    final dynamicType = dartType.element.context.typeProvider.dynamicType;
    dartType = dartType.resolveToBound(dynamicType);
  }
  if (dartType.element.isPrivate) return o.DYNAMIC_TYPE;
  final typeArguments = dartType is ParameterizedType
      ? dartType.typeArguments.map(fromDartType).toList()
      : null;
  return new o.ExternalType(
    new CompileIdentifierMetadata(
      name: dartType.name,
      moduleUrl: moduleUrl(dartType.element),
      // Most o.ExternalTypes are not created, but those that are (like
      // OpaqueToken<...> need this generic type.
      genericTypes: typeArguments,
    ),
    typeArguments,
  );
}

/// Creates an AST from code generation from [typeLink].
o.OutputType fromTypeLink(TypeLink typeLink, LibraryReader library) {
  if (typeLink == null || typeLink.isDynamic || typeLink.isPrivate) {
    return null;
  }
  var typeArguments = new List<o.OutputType>(typeLink.generics.length);
  for (var i = 0; i < typeArguments.length; i++) {
    final arg = fromTypeLink(typeLink.generics[i], library);
    if (arg == null) {
      typeArguments = const [];
      break;
    }
    typeArguments[i] = arg;
  }
  return new o.ExternalType(
    new CompileIdentifierMetadata(
      name: typeLink.symbol,
      moduleUrl: linkToReference(typeLink, library).url,
      genericTypes: typeArguments,
    ),
    typeArguments,
  );
}

/// Creates an AST for code generation from [functionType]
o.FunctionType fromFunctionType(FunctionType functionType) {
  final returnType = fromDartType(functionType.returnType);
  final paramTypes = <o.OutputType>[];
  for (var parameter in functionType.parameters) {
    paramTypes.add(fromDartType(parameter.type));
  }
  return new o.FunctionType(returnType, paramTypes);
}
