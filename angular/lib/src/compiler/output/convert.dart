import 'package:analyzer/dart/element/type.dart';

import '../../source_gen/common/url_resolver.dart';
import '../compile_metadata.dart';
import 'output_ast.dart' as o;

o.OutputType fromDartType(DartType dartType) {
  if (dartType.isVoid) return null;
  if (dartType is FunctionType) return fromFunctionType(dartType);
  final typeArguments = dartType is ParameterizedType
      ? dartType.typeArguments.map(fromDartType).toList()
      : null;
  return new o.ExternalType(
    new CompileIdentifierMetadata(
      name: dartType.name,
      moduleUrl: moduleUrl(dartType.element),
    ),
    typeArguments,
  );
}

o.FunctionType fromFunctionType(FunctionType functionType) {
  final returnType = fromDartType(functionType.returnType);
  final paramTypes = <o.OutputType>[];
  for (var parameter in functionType.parameters) {
    paramTypes.add(fromDartType(parameter.type));
  }
  return new o.FunctionType(returnType, paramTypes);
}
