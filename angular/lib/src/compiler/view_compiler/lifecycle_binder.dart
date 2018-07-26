import 'package:angular/src/core/metadata/lifecycle_hooks.dart'
    show LifecycleHooks;
import 'package:angular/src/core/change_detection/change_detection.dart'
    show ChangeDetectionStrategy;
import '../compile_metadata.dart'
    show CompileDirectiveMetadata, CompilePipeMetadata;
import '../output/output_ast.dart' as o;
import '../template_ast.dart' show DirectiveAst;
import 'compile_element.dart' show CompileElement;
import 'compile_view.dart' show CompileView, notThrowOnChanges;
import 'constants.dart' show DetectChangesVars;

void bindDirectiveDetectChangesLifecycleCallbacks(DirectiveAst directiveAst,
    o.Expression directiveInstance, CompileElement compileElement) {
  var view = compileElement.view;
  var detectChangesInInputsMethod = view.detectChangesInInputsMethod;
  var directive = directiveAst.directive;
  var lifecycleHooks = directive.lifecycleHooks;
  if (lifecycleHooks.contains(LifecycleHooks.onChanges) &&
      directiveAst.inputs.isNotEmpty) {
    detectChangesInInputsMethod
        .addStmt(o.IfStmt(DetectChangesVars.changes.notIdentical(o.NULL_EXPR), [
      directiveInstance
          .callMethod('ngOnChanges', [DetectChangesVars.changes]).toStmt()
    ]));
  }
  if (lifecycleHooks.contains(LifecycleHooks.afterChanges) &&
      directiveAst.inputs.isNotEmpty) {
    if (directiveAst.directive.changeDetection ==
        ChangeDetectionStrategy.Stateful) {
      detectChangesInInputsMethod.addStmt(
          directiveInstance.callMethod('ngAfterChanges', const []).toStmt());
    } else {
      detectChangesInInputsMethod.addStmt(o.IfStmt(DetectChangesVars.changed,
          [directiveInstance.callMethod('ngAfterChanges', const []).toStmt()]));
    }
  }
  if (lifecycleHooks.contains(LifecycleHooks.onInit)) {
    // We don't re-use the existing IfStmt (.addStmtsIfFirstCheck), because we
    // require an additional condition (`notThrowOnChanges`).
    detectChangesInInputsMethod.addStmt(o.IfStmt(
        notThrowOnChanges.and(DetectChangesVars.firstCheck),
        [directiveInstance.callMethod('ngOnInit', []).toStmt()]));
  }
  if (lifecycleHooks.contains(LifecycleHooks.doCheck)) {
    detectChangesInInputsMethod.addStmt(o.IfStmt(notThrowOnChanges,
        [directiveInstance.callMethod('ngDoCheck', []).toStmt()]));
  }
}

void bindDirectiveAfterContentLifecycleCallbacks(
    CompileDirectiveMetadata directiveMeta,
    o.Expression directiveInstance,
    CompileElement compileElement) {
  var view = compileElement.view;
  var lifecycleHooks = directiveMeta.lifecycleHooks;
  var afterContentLifecycleCallbacksMethod =
      view.afterContentLifecycleCallbacksMethod;
  if (!identical(lifecycleHooks.indexOf(LifecycleHooks.afterContentInit), -1)) {
    afterContentLifecycleCallbacksMethod.addStmtsIfFirstCheck([
      directiveInstance.callMethod('ngAfterContentInit', []).toStmt(),
    ]);
  }
  if (!identical(
      lifecycleHooks.indexOf(LifecycleHooks.afterContentChecked), -1)) {
    afterContentLifecycleCallbacksMethod.addStmt(
        directiveInstance.callMethod('ngAfterContentChecked', []).toStmt());
  }
}

void bindDirectiveAfterViewLifecycleCallbacks(
    CompileDirectiveMetadata directiveMeta,
    o.Expression directiveInstance,
    CompileElement compileElement) {
  var view = compileElement.view;
  var lifecycleHooks = directiveMeta.lifecycleHooks;
  var afterViewLifecycleCallbacksMethod =
      view.afterViewLifecycleCallbacksMethod;
  if (!identical(lifecycleHooks.indexOf(LifecycleHooks.afterViewInit), -1)) {
    afterViewLifecycleCallbacksMethod.addStmtsIfFirstCheck([
      directiveInstance.callMethod('ngAfterViewInit', []).toStmt(),
    ]);
  }
  if (!identical(lifecycleHooks.indexOf(LifecycleHooks.afterViewChecked), -1)) {
    afterViewLifecycleCallbacksMethod.addStmt(
        directiveInstance.callMethod('ngAfterViewChecked', []).toStmt());
  }
}

// Create code to call ngOnDestroy for each directive that contains OnDestroy
// lifecycle hook.
void bindDirectiveDestroyLifecycleCallbacks(
    CompileDirectiveMetadata directiveMeta,
    o.Expression directiveInstance,
    CompileElement compileElement) {
  var onDestroyMethod = compileElement.view.destroyMethod;
  if (!identical(
      directiveMeta.lifecycleHooks.indexOf(LifecycleHooks.onDestroy), -1)) {
    onDestroyMethod
        .addStmt(directiveInstance.callMethod('ngOnDestroy', []).toStmt());
  }
}

void bindPipeDestroyLifecycleCallbacks(
    CompilePipeMetadata pipeMeta, o.Expression pipeInstance, CompileView view) {
  var onDestroyMethod = view.destroyMethod;
  if (!identical(
      pipeMeta.lifecycleHooks.indexOf(LifecycleHooks.onDestroy), -1)) {
    onDestroyMethod
        .addStmt(pipeInstance.callMethod('ngOnDestroy', []).toStmt());
  }
}
