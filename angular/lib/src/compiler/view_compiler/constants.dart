import "../compile_metadata.dart" show CompileIdentifierMetadata;
import "../identifiers.dart";
import "../output/output_ast.dart" as o;

const String appViewRootElementName = 'rootEl';
const classAttrName = "class";
const styleAttrName = "style";
var parentRenderNodeVar = o.variable("parentRenderNode");

o.Expression createEnumExpression(
    CompileIdentifierMetadata classIdentifier, dynamic value) {
  if (value == null) return o.NULL_EXPR;
  String enumStr = value.toString();
  var name = enumStr.substring(enumStr.lastIndexOf('.') + 1);
  return o.importExpr(CompileIdentifierMetadata(
      name: '${classIdentifier.name}.$name',
      moduleUrl: classIdentifier.moduleUrl));
}

const List<String> _changeDetectionStrategies = [
  'Default',
  'CheckOnce',
  'Checked',
  'CheckAlways',
  'Detached',
  'OnPush',
  'Stateful'
];

// Converts integer change detection strategy to const expression
// to make generated code more readable.
o.Expression changeDetectionStrategyToConst(int value) {
  String name = _changeDetectionStrategies[value];
  return o.importExpr(CompileIdentifierMetadata(
      name: 'ChangeDetectionStrategy.$name',
      moduleUrl: Identifiers.ChangeDetectionStrategy.moduleUrl));
}

class ViewConstructorVars {
  static final parentView = o.variable('parentView');
  static final parentIndex = o.variable('parentIndex');
}

class ViewProperties {
  static final projectedNodes = o.ReadClassMemberExpr('projectedNodes');
}

class EventHandlerVars {
  static final event = o.variable('\$event');
}

/// Variables used to implement `injectorGetInternal` in generated views.
class InjectMethodVars {
  /// The token being injected.
  static final token = o.variable('token');

  /// The index of the node from which the query for [token] originated.
  static final nodeIndex = o.variable('nodeIndex');

  /// The value to be returned if [token] isn't matched.
  static final notFoundResult = o.variable('notFoundResult');
}

class DetectChangesVars {
  static final cachedCtx = o.variable('_ctx');
  static final changes = o.variable('changes');
  static final changed = o.variable('changed');
  static final firstCheck = o.variable('firstCheck');
}
