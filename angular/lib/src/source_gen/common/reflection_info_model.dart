import 'package:code_builder/code_builder.dart';
import 'package:code_builder/dart/core.dart';
import 'package:quiver/strings.dart' as strings;
import 'package:angular/src/transform/common/names.dart';

import 'annotation_model.dart';
import 'parameter_model.dart';

/// Reflective information about a symbol, including annotations, interfaces,
/// and other metadata.
class ReflectionInfoModel {
  final ReferenceBuilder _type;
  final String ctorName;
  final bool isFunction;

  final Iterable<AnnotationModel> _annotations;
  final Iterable<ParameterModel> _parameters;
  final Iterable<ReferenceBuilder> _interfaces;

  ReflectionInfoModel(
      {ReferenceBuilder type,
      this.ctorName,
      this.isFunction: false,
      Iterable<AnnotationModel> annotations: const [],
      Iterable<ParameterModel> parameters: const [],
      Iterable<ReferenceBuilder> interfaces: const []})
      : this._type = type,
        _annotations = annotations,
        _parameters = parameters,
        _interfaces = interfaces;

  List<ExpressionBuilder> get localMetadataEntry => [
        _type,
        _annotationList(_annotations
            .where((AnnotationModel am) => !am.name.endsWith('NgFactory')))
      ];

  StatementBuilder get asRegistration {
    var reflectionInfo = reference('ReflectionInfo', REFLECTOR_IMPORT)
        .newInstance(_reflectionInfoParams);

    var reflector = reference(REFLECTOR_VAR_NAME, REFLECTOR_IMPORT);
    if (isFunction) {
      return reflector.invoke('registerFunction', [_type, reflectionInfo]);
    } else if (_isSimpleType) {
      return reflector.invoke('registerSimpleType', [_type, _factoryClosure]);
    } else {
      return reflector.invoke('registerType', [_type, reflectionInfo]);
    }
  }

  bool get _isSimpleType =>
      !isFunction &&
      _annotations.isEmpty &&
      _parameters.isEmpty &&
      _interfaces.isEmpty;

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
      list(_interfaces, type: lib$core.$dynamic, asConst: true);

  ExpressionBuilder get _factoryClosure {
    var closure = new MethodBuilder.closure(returns: _constructorExpression);
    _parameters.forEach((param) {
      closure.addPositional(param.asBuilder);
    });
    return closure;
  }

  NewInstanceBuilder get _constructorExpression {
    var modelRef = _type;
    var params = _parameters.map((param) => reference(param.paramName));
    return strings.isNotEmpty(ctorName)
        ? modelRef.newInstance(params, constructor: ctorName)
        : modelRef.newInstance(params);
  }
}
