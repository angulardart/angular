import 'package:angular2/src/source_gen/common/annotation_model.dart';
import 'package:angular2/src/source_gen/common/parameter_model.dart';
import 'package:angular2/src/transform/common/names.dart';
import 'package:code_builder/code_builder.dart';
import 'package:code_builder/dart/core.dart';
import 'package:quiver/strings.dart' as strings;

/// Reflective information about a symbol, including annotations, interfaces,
/// and other metadata.
class ReflectionInfoModel {
  final String name;
  final String ctorName;
  final bool isFunction;

  final List<AnnotationModel> _annotations;
  final List<ParameterModel> _parameters;
  final List<String> _interfaces;

  ReflectionInfoModel(
      {this.name,
      this.ctorName,
      this.isFunction: false,
      List<AnnotationModel> annotations: const [],
      List<ParameterModel> parameters: const [],
      List<String> interfaces: const []})
      : _annotations = annotations,
        _parameters = parameters,
        _interfaces = interfaces;

  List<ExpressionBuilder> get localMetadataEntry => [
        reference(name),
        _annotationList(_annotations
            .where((AnnotationModel am) => !am.name.endsWith('NgFactory')))
      ];

  StatementBuilder get asRegistration {
    var reflectionInfo = reference('ReflectionInfo', REFLECTOR_IMPORT)
        .newInstance(_reflectionInfoParams);
    return reference(REFLECTOR_VAR_NAME, REFLECTOR_IMPORT).invoke(
        isFunction ? 'registerFunction' : 'registerType',
        [reference(name), reflectionInfo]);
  }

  List<ExpressionBuilder> get _reflectionInfoParams {
    var reflectionInfoParams = <ExpressionBuilder>[
      _allAnnotations,
      _parameterList
    ];

    if (!isFunction) {
      reflectionInfoParams.add(_factoryClosure);

      if (_interfaces.isNotEmpty) {
        reflectionInfoParams.add(_interfaceList);
      }
    }
    return reflectionInfoParams;
  }

  ExpressionBuilder get _allAnnotations => _annotationList(_annotations);

  ExpressionBuilder _annotationList(Iterable<AnnotationModel> annotations) =>
      list(annotations.map((AnnotationModel model) => model.asExpression),
          type: lib$core.$dynamic, asConst: true);

  ExpressionBuilder get _parameterList =>
      list(_parameters.map((ParameterModel model) => model.asList),
          asConst: true);

  ExpressionBuilder get _interfaceList =>
      list(_interfaces.map(reference), type: lib$core.$dynamic, asConst: true);

  ExpressionBuilder get _factoryClosure {
    var closure = new MethodBuilder.closure(returns: _constructorExpression);
    _parameters.forEach((param) {
      closure.addPositional(param.asBuilder);
    });
    return closure;
  }

  NewInstanceBuilder get _constructorExpression {
    var modelRef = reference(name);
    var params = _parameters.map((param) => reference(param.paramName));
    return strings.isNotEmpty(ctorName)
        ? modelRef.namedNewInstance(ctorName, params)
        : modelRef.newInstance(params);
  }
}
