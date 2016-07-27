import "package:angular2/src/core/change_detection/change_detection.dart"
    show ChangeDetectorState, ChangeDetectionStrategy;
import "package:angular2/src/core/linker/view_type.dart" show ViewType;
import "package:angular2/src/core/metadata/view.dart" show ViewEncapsulation;
import "package:angular2/src/facade/lang.dart" show resolveEnumToken;

import "../compile_metadata.dart" show CompileIdentifierMetadata;
import "../identifiers.dart" show Identifiers;
import "../output/output_ast.dart" as o;

o.Expression _enumExpression(
    CompileIdentifierMetadata classIdentifier, dynamic value) {
  if (value == null) return o.NULL_EXPR;
  var name = resolveEnumToken(classIdentifier.runtime, value);
  return o.importExpr(new CompileIdentifierMetadata(
      name: '${classIdentifier.name}.${name}',
      moduleUrl: classIdentifier.moduleUrl,
      runtime: value));
}

class ViewTypeEnum {
  static o.Expression fromValue(ViewType value) {
    return _enumExpression(Identifiers.ViewType, value);
  }

  static var HOST = ViewTypeEnum.fromValue(ViewType.HOST);
  static var COMPONENT = ViewTypeEnum.fromValue(ViewType.COMPONENT);
  static var EMBEDDED = ViewTypeEnum.fromValue(ViewType.EMBEDDED);
}

class ViewEncapsulationEnum {
  static o.Expression fromValue(ViewEncapsulation value) {
    return _enumExpression(Identifiers.ViewEncapsulation, value);
  }

  static var Emulated =
      ViewEncapsulationEnum.fromValue(ViewEncapsulation.Emulated);
  static var Native = ViewEncapsulationEnum.fromValue(ViewEncapsulation.Native);
  static var None = ViewEncapsulationEnum.fromValue(ViewEncapsulation.None);
}

class ChangeDetectorStateEnum {
  static o.Expression fromValue(ChangeDetectorState value) {
    return _enumExpression(Identifiers.ChangeDetectorState, value);
  }

  static var NeverChecked =
      ChangeDetectorStateEnum.fromValue(ChangeDetectorState.NeverChecked);
  static var CheckedBefore =
      ChangeDetectorStateEnum.fromValue(ChangeDetectorState.CheckedBefore);
  static var Errored =
      ChangeDetectorStateEnum.fromValue(ChangeDetectorState.Errored);
}

class ChangeDetectionStrategyEnum {
  static o.Expression fromValue(ChangeDetectionStrategy value) {
    return _enumExpression(Identifiers.ChangeDetectionStrategy, value);
  }

  static var CheckOnce =
      ChangeDetectionStrategyEnum.fromValue(ChangeDetectionStrategy.CheckOnce);
  static var Checked =
      ChangeDetectionStrategyEnum.fromValue(ChangeDetectionStrategy.Checked);
  static var CheckAlways = ChangeDetectionStrategyEnum
      .fromValue(ChangeDetectionStrategy.CheckAlways);
  static var Detached =
      ChangeDetectionStrategyEnum.fromValue(ChangeDetectionStrategy.Detached);
  static var OnPush =
      ChangeDetectionStrategyEnum.fromValue(ChangeDetectionStrategy.OnPush);
  static var Default =
      ChangeDetectionStrategyEnum.fromValue(ChangeDetectionStrategy.Default);
}

class ViewConstructorVars {
  static var viewUtils = o.variable('viewUtils');
  static var parentInjector = o.variable('parentInjector');
  static var declarationEl = o.variable('declarationEl');
}

class ViewProperties {
  static var renderer = o.THIS_EXPR.prop('renderer');
  static var projectableNodes = o.THIS_EXPR.prop('projectableNodes');
  static var viewUtils = o.THIS_EXPR.prop('viewUtils');
}

class EventHandlerVars {
  static var event = o.variable('\$event');
}

class InjectMethodVars {
  static var token = o.variable('token');
  static var requestNodeIndex = o.variable('requestNodeIndex');
  static var notFoundResult = o.variable('notFoundResult');
}

class DetectChangesVars {
  static var changes = o.variable('changes');
  static var changed = o.variable('changed');
  static var valUnwrapper = o.variable('valUnwrapper');
}
