import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

/// Instantiate the class [element] as a legacy type for `this` expression.
InterfaceType instantiateClassElementThis(ClassElement element) {
  List<DartType> typeArguments;
  if (element.typeParameters.isNotEmpty) {
    typeArguments = element.typeParameters.map<DartType>((t) {
      return t.instantiate(nullabilitySuffix: NullabilitySuffix.star);
    }).toList();
  } else {
    typeArguments = const <DartType>[];
  }
  return element.instantiate(
    typeArguments: typeArguments,
    nullabilitySuffix: NullabilitySuffix.star,
  );
}

InterfaceType instantiateClassElementToBounds(ClassElement element) {
  var typeProvider = element.library.typeProvider;
  return element.instantiate(
    typeArguments: element.typeParameters
        .map((p) => p.bound ?? typeProvider.dynamicType)
        .toList(),
    nullabilitySuffix: NullabilitySuffix.star,
  );
}

FunctionType instantiateFunctionTypeAliasElementToBounds(
    FunctionTypeAliasElement element) {
  var typeProvider = element.library.typeProvider;
  return element.instantiate(
    typeArguments: element.typeParameters
        .map((p) => p.bound ?? typeProvider.dynamicType)
        .toList(),
    nullabilitySuffix: NullabilitySuffix.star,
  );
}
