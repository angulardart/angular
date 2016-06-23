library angular2.src.compiler.view_compiler.lifecycle_binder;

import "../output/output_ast.dart" as o;
import "constants.dart" show DetectChangesVars, ChangeDetectorStateEnum;
import "package:angular2/src/core/metadata/lifecycle_hooks.dart"
    show LifecycleHooks;
import "../compile_metadata.dart"
    show CompileDirectiveMetadata, CompilePipeMetadata;
import "../template_ast.dart" show DirectiveAst;
import "compile_element.dart" show CompileElement;
import "compile_view.dart" show CompileView;

var STATE_IS_NEVER_CHECKED =
    o.THIS_EXPR.prop("cdState").identical(ChangeDetectorStateEnum.NeverChecked);
var NOT_THROW_ON_CHANGES = o.not(DetectChangesVars.throwOnChange);
bindDirectiveDetectChangesLifecycleCallbacks(DirectiveAst directiveAst,
    o.Expression directiveInstance, CompileElement compileElement) {
  var view = compileElement.view;
  var detectChangesInInputsMethod = view.detectChangesInInputsMethod;
  var lifecycleHooks = directiveAst.directive.lifecycleHooks;
  if (!identical(lifecycleHooks.indexOf(LifecycleHooks.OnChanges), -1) &&
      directiveAst.inputs.length > 0) {
    detectChangesInInputsMethod.addStmt(
        new o.IfStmt(DetectChangesVars.changes.notIdentical(o.NULL_EXPR), [
      directiveInstance
          .callMethod("ngOnChanges", [DetectChangesVars.changes]).toStmt()
    ]));
  }
  if (!identical(lifecycleHooks.indexOf(LifecycleHooks.OnInit), -1)) {
    detectChangesInInputsMethod.addStmt(new o.IfStmt(
        STATE_IS_NEVER_CHECKED.and(NOT_THROW_ON_CHANGES),
        [directiveInstance.callMethod("ngOnInit", []).toStmt()]));
  }
  if (!identical(lifecycleHooks.indexOf(LifecycleHooks.DoCheck), -1)) {
    detectChangesInInputsMethod.addStmt(new o.IfStmt(NOT_THROW_ON_CHANGES,
        [directiveInstance.callMethod("ngDoCheck", []).toStmt()]));
  }
}

bindDirectiveAfterContentLifecycleCallbacks(
    CompileDirectiveMetadata directiveMeta,
    o.Expression directiveInstance,
    CompileElement compileElement) {
  var view = compileElement.view;
  var lifecycleHooks = directiveMeta.lifecycleHooks;
  var afterContentLifecycleCallbacksMethod =
      view.afterContentLifecycleCallbacksMethod;
  afterContentLifecycleCallbacksMethod.resetDebugInfo(
      compileElement.nodeIndex, compileElement.sourceAst);
  if (!identical(lifecycleHooks.indexOf(LifecycleHooks.AfterContentInit), -1)) {
    afterContentLifecycleCallbacksMethod.addStmt(new o.IfStmt(
        STATE_IS_NEVER_CHECKED,
        [directiveInstance.callMethod("ngAfterContentInit", []).toStmt()]));
  }
  if (!identical(
      lifecycleHooks.indexOf(LifecycleHooks.AfterContentChecked), -1)) {
    afterContentLifecycleCallbacksMethod.addStmt(
        directiveInstance.callMethod("ngAfterContentChecked", []).toStmt());
  }
}

bindDirectiveAfterViewLifecycleCallbacks(CompileDirectiveMetadata directiveMeta,
    o.Expression directiveInstance, CompileElement compileElement) {
  var view = compileElement.view;
  var lifecycleHooks = directiveMeta.lifecycleHooks;
  var afterViewLifecycleCallbacksMethod =
      view.afterViewLifecycleCallbacksMethod;
  afterViewLifecycleCallbacksMethod.resetDebugInfo(
      compileElement.nodeIndex, compileElement.sourceAst);
  if (!identical(lifecycleHooks.indexOf(LifecycleHooks.AfterViewInit), -1)) {
    afterViewLifecycleCallbacksMethod.addStmt(new o.IfStmt(
        STATE_IS_NEVER_CHECKED,
        [directiveInstance.callMethod("ngAfterViewInit", []).toStmt()]));
  }
  if (!identical(lifecycleHooks.indexOf(LifecycleHooks.AfterViewChecked), -1)) {
    afterViewLifecycleCallbacksMethod.addStmt(
        directiveInstance.callMethod("ngAfterViewChecked", []).toStmt());
  }
}

bindDirectiveDestroyLifecycleCallbacks(CompileDirectiveMetadata directiveMeta,
    o.Expression directiveInstance, CompileElement compileElement) {
  var onDestroyMethod = compileElement.view.destroyMethod;
  onDestroyMethod.resetDebugInfo(
      compileElement.nodeIndex, compileElement.sourceAst);
  if (!identical(
      directiveMeta.lifecycleHooks.indexOf(LifecycleHooks.OnDestroy), -1)) {
    onDestroyMethod
        .addStmt(directiveInstance.callMethod("ngOnDestroy", []).toStmt());
  }
}

bindPipeDestroyLifecycleCallbacks(CompilePipeMetadata pipeMeta,
    o.Expression directiveInstance, CompileView view) {
  var onDestroyMethod = view.destroyMethod;
  if (!identical(
      pipeMeta.lifecycleHooks.indexOf(LifecycleHooks.OnDestroy), -1)) {
    onDestroyMethod
        .addStmt(directiveInstance.callMethod("ngOnDestroy", []).toStmt());
  }
}
