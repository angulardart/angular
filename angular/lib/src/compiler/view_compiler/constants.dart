import "../compile_metadata.dart" show CompileIdentifierMetadata;
import "../identifiers.dart";
import "../output/output_ast.dart" as o;

/// The name of the `ComponentView` field that stores its root element.
const componentViewRootElementFieldName = 'rootElement';

/// The name of the `HostView` field that stores the hosted component instance.
const hostViewComponentFieldName = 'component';

const classAttrName = 'class';
const styleAttrName = 'style';
final parentRenderNodeVar = o.variable('parentRenderNode');

const List<String> _changeDetectionStrategies = [
  'Default',
  'CheckOnce',
  'Checked',
  'CheckAlways',
  'Detached',
  'OnPush',
];

/// Converts value of a `ChangeDetectionStrategy` to refer to the static field.
///
/// Otherwise the generated code refers to arbitrary integer values.
o.Expression changeDetectionStrategyToConst(int value) {
  final name = _changeDetectionStrategies[value];
  return o.importExpr(CompileIdentifierMetadata(
    name: 'ChangeDetectionStrategy.$name',
    moduleUrl: Identifiers.ChangeDetectionStrategy.moduleUrl,
  ));
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
  static final changed = o.variable('changed');
  static final firstCheck = o.variable('firstCheck');
  static final internalSetStateChanged = o.importExpr(
    CompileIdentifierMetadata(
        name: 'internalSetStateChanged',
        moduleUrl: 'asset:angular/lib/src/core/'
            'change_detection/component_state.dart'),
  );
}

class Lifecycles {
  static final afterChanges = 'ngAfterChanges';
  static final onInit = 'ngOnInit';
  static final doCheck = 'ngDoCheck';
  static final afterContentInit = 'ngAfterContentInit';
  static final afterContentChecked = 'ngAfterContentChecked';
  static final afterViewInit = 'ngAfterViewInit';
  static final afterViewChecked = 'ngAfterViewChecked';
  static final onDestroy = 'ngOnDestroy';
}
