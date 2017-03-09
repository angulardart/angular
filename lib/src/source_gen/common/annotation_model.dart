import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';

import 'references.dart';

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

  factory AnnotationModel.fromElement(
    // Not part of public API yet: https://github.com/dart-lang/sdk/issues/28631
    ElementAnnotationImpl annotation,
    Element hostElement,
  ) {
    var element = annotation.element;
    if (element is ConstructorElement) {
      var parameters = <ReferenceBuilder>[];
      var namedParameters = <NamedParameter>[];
      annotation.annotationAst.arguments.arguments.forEach((arg) {
        if (arg is NamedExpression) {
          namedParameters.add(
            new NamedParameter(
              arg.name.label.name,
              new ExpressionBuilder.raw(
                (_) => arg.expression.toSource(),
              ),
            ),
          );
        } else {
          parameters.add(
            new ExpressionBuilder.raw((_) => arg.toSource()),
          );
        }
      });
      return new AnnotationModel(
        name: element.enclosingElement.name,
        type: toBuilder(element.type.returnType, hostElement.library.imports),
        isConstObject: false,
        parameters: parameters,
        namedParameters: namedParameters,
      );
    } else {
      // TODO(alorenzen): Determine if prefixing element.name is necessary.
      return new AnnotationModel(name: element.name, isConstObject: true);
    }
  }

  ExpressionBuilder get asExpression => _isConstObject
      ? type
      : type.constInstance(_parameters, namedArguments: _namedParametersAsMap);

  Map<String, ExpressionBuilder> get _namedParametersAsMap =>
      new Map.fromIterable(_namedParameters,
          key: (param) => param.name, value: (param) => param.value);
}

class NamedParameter {
  final String name;
  final ReferenceBuilder value;

  NamedParameter(this.name, this.value);
}
