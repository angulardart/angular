import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/source_gen/common/references.dart';
import 'package:code_builder/code_builder.dart';

/// An annotation on a reflection type.
class AnnotationModel {
  final String name;
  final ReferenceBuilder type;
  final bool _isConstObject;
  final Iterable<ReferenceBuilder> _parameters;
  final Iterable<NamedParameter> _namedParameters;

  AnnotationModel(
      {this.name,
      ReferenceBuilder type,
      bool isConstObject: false,
      Iterable<ReferenceBuilder> parameters: const [],
      Iterable<NamedParameter> namedParameters: const []})
      : this.type = type ?? reference(name),
        _isConstObject = isConstObject,
        _parameters = parameters,
        _namedParameters = namedParameters;

  factory AnnotationModel.fromElement(ElementAnnotation annotation) {
    var element = annotation.element;
    if (element is ConstructorElement) {
      return new AnnotationModel(
          name: element.enclosingElement.name,
          type: toBuilder(element.type.returnType, element.library.imports),
          isConstObject: false,
          // TODO(alorenzen): Implement.
          parameters: [],
          namedParameters: []);
    } else {
      // TODO(alorenzen): Determine if prefixing element.name is necessary.
      return new AnnotationModel(name: element.name, isConstObject: true);
    }
  }

  ExpressionBuilder get asExpression => _isConstObject
      ? type
      : type.constInstance(_parameters, _namedParametersAsMap);

  Map<String, ExpressionBuilder> get _namedParametersAsMap =>
      new Map.fromIterable(_namedParameters,
          key: (param) => param.name, value: (param) => param.value);
}

class NamedParameter {
  final String name;
  final ReferenceBuilder value;

  NamedParameter(this.name, this.value);
}
