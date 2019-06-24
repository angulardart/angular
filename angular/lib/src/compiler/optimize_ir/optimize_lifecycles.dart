import 'package:angular/src/compiler/ir/model.dart' as ir;

/// Optimizes lifecycle hooks in the directive.
///
/// If there are no inputs declared, then nothing can every change for the
/// matched directive.  Thus, we do not need to call the `ngAfterChanges`
/// lifecycle hook.
ir.MatchedDirective optimizeLifecycles(ir.MatchedDirective directive) {
  if (directive.inputs.isNotEmpty ||
      !directive.hasLifecycle(ir.Lifecycle.afterChanges)) {
    return directive;
  }

  return ir.MatchedDirective(
    lifecycles: directive.lifecycles
        .where((lifecycle) => lifecycle != ir.Lifecycle.afterChanges)
        .toSet(),
    providerSource: directive.providerSource,
    inputs: directive.inputs,
    outputs: directive.outputs,
    hasInputs: directive.hasInputs,
    hasHostProperties: directive.hasHostProperties,
    isComponent: directive.isComponent,
    isOnPush: directive.isOnPush,
  );
}
