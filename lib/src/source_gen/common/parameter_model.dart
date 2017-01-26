import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/source_gen/common/annotation_model.dart';
import 'package:angular2/src/source_gen/common/references.dart' as references;
import 'package:code_builder/code_builder.dart';
import 'package:code_builder/dart/core.dart';

/// A parameter used in the creation of a reflection type.
class ParameterModel {
  final String paramName;
  final ReferenceBuilder _type;
  final List<ReferenceBuilder> _metadata;

  ParameterModel._(
      {this.paramName,
      ReferenceBuilder type,
      Iterable<TypeBuilder> metadata: const []})
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
        type: references.toBuilder(element.type, element.library.imports),
        metadata: element.metadata
            .map((annotation) => _getMetadataType(annotation, element)));
  }

  ExpressionBuilder get asList {
    var params = _typeAsList..addAll(_metadata);
    return list(params, type: lib$core.$dynamic, asConst: true);
  }

  List<ReferenceBuilder> get _typeAsList => _type != null ? [_type] : [];

  ParameterBuilder get asBuilder => parameter(paramName, _typeAsList);

  static ReferenceBuilder _getMetadataType(
          ElementAnnotation annotation, Element element) =>
      new AnnotationModel.fromElement(annotation, element).type;
}
