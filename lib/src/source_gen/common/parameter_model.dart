import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:code_builder/dart/core.dart';

import 'annotation_model.dart';
import 'references.dart' as references;

/// A parameter used in the creation of a reflection type.
class ParameterModel {
  final String paramName;
  final ReferenceBuilder _type;
  final List<ExpressionBuilder> _metadata;

  ParameterModel._(
      {this.paramName,
      ReferenceBuilder type,
      Iterable<ExpressionBuilder> metadata: const []})
      : _type = type,
        _metadata = metadata.toList();

  factory ParameterModel(
      {String paramName,
      String typeName,
      String importedFrom,
      Iterable<String> typeArgs: const [],
      Iterable<String> metadata: const []}) {
    return new ParameterModel._(
        paramName: paramName,
        type: typeName != null
            ? reference(typeName, importedFrom).toTyped(typeArgs.map(reference))
            : null,
        metadata: metadata.map(reference).toList());
  }

  factory ParameterModel.fromElement(ParameterElement element) {
    return new ParameterModel._(
        paramName: element.name,
        type: references.toBuilder(element.type, element.library.imports,
            includeGenerics: false),
        metadata: _metadataFor(element));
  }

  ExpressionBuilder get asList {
    var params = _typeAsList..addAll(_metadata);
    return list(params, type: lib$core.$dynamic, asConst: true);
  }

  List<ExpressionBuilder> get _typeAsList => _type != null ? [_type] : [];

  ParameterBuilder get asBuilder => parameter(paramName, _typeAsList);

  static List<ExpressionBuilder> _metadataFor(ParameterElement element) {
    final metadata = <ExpressionBuilder>[];
    for (ElementAnnotation annotation in element.metadata) {
      metadata.add(_getMetadataInvocation(annotation, element));
    }
    if (element.parameterKind == ParameterKind.POSITIONAL) {
      metadata.add(reference('Optional', optionalPackage).constInstance([]));
    }
    return metadata;
  }

  static ExpressionBuilder _getMetadataInvocation(
          ElementAnnotation annotation, Element element) =>
      new AnnotationModel.fromElement(annotation, element).asExpression;
}

const optionalPackage = 'package:angular2/src/core/di/decorators.dart';
