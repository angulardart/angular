import 'package:code_builder/code_builder.dart';

/// An annotation on a reflection type.
class AnnotationModel {
  final String name;
  final bool isConstObject;
  final List<String> parameters;
  final List<NamedParameter> namedParameters;

  AnnotationModel(
      {this.name,
      this.isConstObject: false,
      this.parameters: const [],
      this.namedParameters: const []});

  ExpressionBuilder get asExpression => isConstObject
      ? reference(name)
      : reference(name)
          .constInstance(parameters.map(reference), _namedParametersAsMap);

  Map<String, ExpressionBuilder> get _namedParametersAsMap =>
      new Map.fromIterable(namedParameters,
          key: (param) => param.name, value: (param) => reference(param.value));
}

class NamedParameter {
  final String name;
  final String value;

  NamedParameter(this.name, this.value);
}
