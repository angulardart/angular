import "package:angular2/src/core/change_detection/change_detection.dart"
    show ChangeDetectorState, ChangeDetectionStrategy;
import "package:angular2/src/core/linker/view_type.dart" show ViewType;
import "package:angular2/src/core/metadata/view.dart" show ViewEncapsulation;

import "../compile_metadata.dart" show CompileIdentifierMetadata;
import "../identifiers.dart" show Identifiers;
import "../output/output_ast.dart" as o;

String _resolveEnumToken(enumValue, val) {
  // turn Enum.Token -> Token
  return val.toString().replaceFirst(new RegExp('^.+\\.'), '');
}

o.Expression _enumExpression(
    CompileIdentifierMetadata classIdentifier, dynamic value) {
  if (value == null) return o.NULL_EXPR;
  var name = _resolveEnumToken(classIdentifier.runtime, value);
  return o.importExpr(new CompileIdentifierMetadata(
      name: '${classIdentifier.name}.${name}',
      moduleUrl: classIdentifier.moduleUrl,
      runtime: value));
}

class ViewTypeEnum {
  static o.Expression fromValue(ViewType value) {
    return _enumExpression(Identifiers.ViewType, value);
  }

  static final HOST = ViewTypeEnum.fromValue(ViewType.HOST);
  static final COMPONENT = ViewTypeEnum.fromValue(ViewType.COMPONENT);
  static final EMBEDDED = ViewTypeEnum.fromValue(ViewType.EMBEDDED);
}

class ViewEncapsulationEnum {
  static o.Expression fromValue(ViewEncapsulation value) {
    return _enumExpression(Identifiers.ViewEncapsulation, value);
  }

  static final Emulated =
      ViewEncapsulationEnum.fromValue(ViewEncapsulation.Emulated);
  static final Native =
      ViewEncapsulationEnum.fromValue(ViewEncapsulation.Native);
  static final None = ViewEncapsulationEnum.fromValue(ViewEncapsulation.None);
}

class ChangeDetectorStateEnum {
  static o.Expression fromValue(ChangeDetectorState value) {
    return _enumExpression(Identifiers.ChangeDetectorState, value);
  }

  static final NeverChecked =
      ChangeDetectorStateEnum.fromValue(ChangeDetectorState.NeverChecked);
  static final CheckedBefore =
      ChangeDetectorStateEnum.fromValue(ChangeDetectorState.CheckedBefore);
  static final Errored =
      ChangeDetectorStateEnum.fromValue(ChangeDetectorState.Errored);
}

class ChangeDetectionStrategyEnum {
  static o.Expression fromValue(ChangeDetectionStrategy value) {
    return _enumExpression(Identifiers.ChangeDetectionStrategy, value);
  }

  static final CheckOnce =
      ChangeDetectionStrategyEnum.fromValue(ChangeDetectionStrategy.CheckOnce);
  static final Checked =
      ChangeDetectionStrategyEnum.fromValue(ChangeDetectionStrategy.Checked);
  static final CheckAlways = ChangeDetectionStrategyEnum
      .fromValue(ChangeDetectionStrategy.CheckAlways);
  static final Detached =
      ChangeDetectionStrategyEnum.fromValue(ChangeDetectionStrategy.Detached);
  static final OnPush =
      ChangeDetectionStrategyEnum.fromValue(ChangeDetectionStrategy.OnPush);
  static final Default =
      ChangeDetectionStrategyEnum.fromValue(ChangeDetectionStrategy.Default);
}

class ViewConstructorVars {
  static final parentView = o.variable('parentView');
  static final parentIndex = o.variable('parentIndex');
}

class ViewProperties {
  static final projectableNodes = new o.ReadClassMemberExpr('projectableNodes');
}

class EventHandlerVars {
  static final event = o.variable('\$event');
}

class InjectMethodVars {
  static final token = o.variable('token');

  /// Name of node index parameter used in AppView injectorGetInternal method.
  static final nodeIndex = o.variable('nodeIndex');
  static final notFoundResult = o.variable('notFoundResult');
}

class DetectChangesVars {
  static final changes = o.variable('changes');
  static final changed = o.variable('changed');
  static final firstCheck = o.variable('firstCheck');
  static final valUnwrapper = o.variable('valUnwrapper');
}
