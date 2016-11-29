import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';

/// An annotation on a reflection type.
class AnnotationModel {
  final String name;
  final bool _isConstObject;
  final List<String> _parameters;
  final List<NamedParameter> _namedParameters;

  AnnotationModel(
      {this.name,
      bool isConstObject: false,
      List<String> parameters: const [],
      List<NamedParameter> namedParameters: const []})
      : _isConstObject = isConstObject,
        _parameters = parameters,
        _namedParameters = namedParameters;

  factory AnnotationModel.fromElement(ElementAnnotation annotation) {
    if (annotation.element is ConstructorElement) {
      return new AnnotationModel(
          name: annotation.element.enclosingElement.name, isConstObject: false,
          // TODO(alorenzen): Implement.
          parameters: [], namedParameters: []);
    } else {
      return new AnnotationModel(
          name: annotation.element.name, isConstObject: true);
    }
  }

  ExpressionBuilder get asExpression => _isConstObject
      ? reference(name)
      : reference(name)
          .constInstance(_parameters.map(reference), _namedParametersAsMap);

  Map<String, ExpressionBuilder> get _namedParametersAsMap =>
      new Map.fromIterable(_namedParameters,
          key: (param) => param.name, value: (param) => reference(param.value));
}

class NamedParameter {
  final String name;
  final String value;

  NamedParameter(this.name, this.value);
}
