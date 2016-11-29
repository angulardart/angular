import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angular2/src/source_gen/common/annotation_model.dart';
import 'package:code_builder/code_builder.dart';
import 'package:code_builder/dart/core.dart';
import 'package:quiver/strings.dart' as strings;

/// A parameter used in the creation of a reflection type.
class ParameterModel {
  final String paramName;
  final String _typeName;
  final List<String> _typeArgs;
  final List<String> _metadata;

  ParameterModel(
      {this.paramName,
      String typeName,
      Iterable<String> typeArgs: const [],
      Iterable<String> metadata: const []})
      : _typeName = typeName,
        _typeArgs = typeArgs.toList(),
        _metadata = metadata.toList();

  factory ParameterModel.fromElement(ParameterElement element) {
    return new ParameterModel(
        paramName: element.name,
        typeName: element.type.name,
        typeArgs: _coerceTypeArgs(element.type),
        metadata: element.metadata.map(_getMetadataString));
  }

  ExpressionBuilder get asList {
    var params = [_typeName]..addAll(_metadata);
    return list(params.where(strings.isNotEmpty).map(reference),
        type: lib$core.$dynamic, asConst: true);
  }

  ParameterBuilder get asBuilder => parameter(paramName,
      [new TypeBuilder(_typeName, genericTypes: _typeArgs.map(reference))]);

  static Iterable<String> _coerceTypeArgs(DartType type) {
    if (type is! ParameterizedType) return const [];
    return (type as ParameterizedType).typeArguments.map((type) => type.name);
  }

  static String _getMetadataString(ElementAnnotation annotation) =>
      new AnnotationModel.fromElement(annotation).name;
}
