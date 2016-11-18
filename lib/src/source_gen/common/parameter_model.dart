import 'package:code_builder/code_builder.dart';
import 'package:code_builder/dart/core.dart';
import 'package:quiver/strings.dart' as strings;

/// A parameter used in the creation of a reflection type.
class ParameterModel {
  final String typeName;
  final String typeArgs;
  final String paramName;
  final List<String> metadata;

  ParameterModel(
      {this.typeName, this.typeArgs, this.paramName, this.metadata: const []});

  ExpressionBuilder get asList {
    var params = [typeName]..addAll(metadata);
    return list(params.where(strings.isNotEmpty).map(reference),
        type: lib$core.$dynamic, asConst: true);
  }

  // TODO(alorenzen): Handle typeArgs.
  ParameterBuilder get asBuilder => parameter(paramName, [reference(typeName)]);
}
