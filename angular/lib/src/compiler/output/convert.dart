import 'package:analyzer/dart/element/type.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:source_gen/source_gen.dart';

import '../../source_gen/common/url_resolver.dart';
import '../compile_metadata.dart';
import 'output_ast.dart' as o;

/// Creates an AST for code generation from [dartType].
///
/// If [resolveBounds] is false, type parameters will not be resolved to their
/// bound.
///
/// Note that private types aren't visible to generated code and will be
/// replaced with dynamic.
o.OutputType fromDartType(DartType dartType, {bool resolveBounds = true}) {
  if (dartType == null) {
    // Some analyzer APIs may return a null `DartType` to signify the absence of
    // an explicit type, such as a generic type parameter bound.
    return null;
  }
  if (dartType.isVoid) {
    return o.VOID_TYPE;
  }
  if (dartType.isDartCoreNull) {
    return o.NULL_TYPE;
  }
  if (dartType is FunctionType) {
    return fromFunctionType(dartType);
  }
  if (dartType.element.isPrivate) {
    return o.DYNAMIC_TYPE;
  }
  if (dartType is TypeParameterType && resolveBounds) {
    // Resolve generic type to its bound or dynamic if it has none.
    final dynamicType = dartType.element.context.typeProvider.dynamicType;
    dartType = dartType.resolveToBound(dynamicType);
  }
  // Note this check for dynamic should come after the check for a type
  // parameter, since a type parameter could resolve to dynamic.
  if (dartType.isDynamic) {
    return o.DYNAMIC_TYPE;
  }
  List<o.OutputType> typeArguments;
  if (dartType is ParameterizedType) {
    typeArguments = [];
    for (final typeArgument in dartType.typeArguments) {
      if (typeArgument is TypeParameterType && resolveBounds) {
        // Temporary hack to avoid a stack overflow for <T extends List<T>>.
        //
        // See https://github.com/dart-lang/angular/issues/1397.
        typeArguments.add(o.DYNAMIC_TYPE);
      } else {
        typeArguments.add(fromDartType(typeArgument, resolveBounds: false));
      }
    }
  }
  return o.ExternalType(
    CompileIdentifierMetadata(
      name: dartType.name,
      moduleUrl: moduleUrl(dartType.element),
      // Most o.ExternalTypes are not created, but those that are (like
      // OpaqueToken<...> need this generic type.
      typeArguments: typeArguments,
    ),
    typeArguments,
  );
}

/// Creates an AST from code generation from [typeLink].
o.OutputType fromTypeLink(TypeLink typeLink, LibraryReader library) {
  if (typeLink == null || typeLink.isDynamic || typeLink.isPrivate) {
    return o.DYNAMIC_TYPE;
  }
  var typeArguments = List<o.OutputType>(typeLink.generics.length);
  for (var i = 0; i < typeArguments.length; i++) {
    typeArguments[i] = fromTypeLink(typeLink.generics[i], library);
  }
  // When `typeLink` represents a type parameter, it doesn't require an import.
  final importUrl = typeLink.import != null
      ? library.pathToUrl(typeLink.import).toString()
      : null;
  return o.ExternalType(
    CompileIdentifierMetadata(
      name: typeLink.symbol,
      moduleUrl: importUrl,
      typeArguments: typeArguments,
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
  return o.FunctionType(returnType, paramTypes);
}

/// Creates type argument ASTs to flow [typeParameters].
List<o.OutputType> typeArgumentsFrom(List<o.TypeParameter> typeParameters) {
  final typeArguments = <o.OutputType>[];
  for (final typeParameter in typeParameters) {
    typeArguments
        .add(o.importType(CompileIdentifierMetadata(name: typeParameter.name)));
  }
  return typeArguments;
}
