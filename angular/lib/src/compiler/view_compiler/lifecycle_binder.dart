import 'package:angular/src/core/metadata/lifecycle_hooks.dart'
    show LifecycleHooks;

import '../compile_metadata.dart'
    show CompileDirectiveMetadata, CompilePipeMetadata;
import '../identifiers.dart';
import '../output/output_ast.dart' as o;
import '../template_ast.dart' show DirectiveAst;
import 'compile_element.dart' show CompileElement;
import 'compile_view.dart' show CompileView;
import 'constants.dart' show DetectChangesVars;

var NOT_THROW_ON_CHANGES = o.not(o.importExpr(Identifiers.throwOnChanges));

void bindDirectiveDetectChangesLifecycleCallbacks(DirectiveAst directiveAst,
    o.Expression directiveInstance, CompileElement compileElement) {
  var view = compileElement.view;
  var detectChangesInInputsMethod = view.detectChangesInInputsMethod;
  var directive = directiveAst.directive;
  var lifecycleHooks = directive.lifecycleHooks;
  if (lifecycleHooks.contains(LifecycleHooks.OnChanges) &&
      directiveAst.inputs.isNotEmpty) {
    detectChangesInInputsMethod.addStmt(
        new o.IfStmt(DetectChangesVars.changes.notIdentical(o.NULL_EXPR), [
      directiveInstance
          .callMethod('ngOnChanges', [DetectChangesVars.changes]).toStmt()
    ]));
  }
  if (lifecycleHooks.contains(LifecycleHooks.OnInit)) {
    if (view.genConfig.genDebugInfo) {
      detectChangesInInputsMethod.addStmt(new o.IfStmt(
          DetectChangesVars.firstCheck.and(NOT_THROW_ON_CHANGES),
          [directiveInstance.callMethod('ngOnInit', []).toStmt()]));
    } else {
      detectChangesInInputsMethod.addStmt(new o.IfStmt(
          DetectChangesVars.firstCheck,
          [directiveInstance.callMethod('ngOnInit', []).toStmt()]));
    }
  }
  if (lifecycleHooks.contains(LifecycleHooks.DoCheck)) {
    if (view.genConfig.genDebugInfo) {
      detectChangesInInputsMethod.addStmt(new o.IfStmt(NOT_THROW_ON_CHANGES,
          [directiveInstance.callMethod('ngDoCheck', []).toStmt()]));
    } else {
      detectChangesInInputsMethod
          .addStmt(directiveInstance.callMethod('ngDoCheck', []).toStmt());
    }
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
  afterContentLifecycleCallbacksMethod.resetDebugInfo(
      compileElement.nodeIndex, compileElement.sourceAst);
  if (!identical(lifecycleHooks.indexOf(LifecycleHooks.AfterContentInit), -1)) {
    afterContentLifecycleCallbacksMethod.addStmt(new o.IfStmt(
        DetectChangesVars.firstCheck,
        [directiveInstance.callMethod('ngAfterContentInit', []).toStmt()]));
  }
  if (!identical(
      lifecycleHooks.indexOf(LifecycleHooks.AfterContentChecked), -1)) {
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
  afterViewLifecycleCallbacksMethod.resetDebugInfo(
      compileElement.nodeIndex, compileElement.sourceAst);
  if (!identical(lifecycleHooks.indexOf(LifecycleHooks.AfterViewInit), -1)) {
    afterViewLifecycleCallbacksMethod.addStmt(new o.IfStmt(
        DetectChangesVars.firstCheck,
        [directiveInstance.callMethod('ngAfterViewInit', []).toStmt()]));
  }
  if (!identical(lifecycleHooks.indexOf(LifecycleHooks.AfterViewChecked), -1)) {
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
  onDestroyMethod.resetDebugInfo(
      compileElement.nodeIndex, compileElement.sourceAst);
  if (!identical(
      directiveMeta.lifecycleHooks.indexOf(LifecycleHooks.OnDestroy), -1)) {
    onDestroyMethod
        .addStmt(directiveInstance.callMethod('ngOnDestroy', []).toStmt());
  }
}

void bindPipeDestroyLifecycleCallbacks(
    CompilePipeMetadata pipeMeta, o.Expression pipeInstance, CompileView view) {
  var onDestroyMethod = view.destroyMethod;
  if (!identical(
      pipeMeta.lifecycleHooks.indexOf(LifecycleHooks.OnDestroy), -1)) {
    onDestroyMethod
        .addStmt(pipeInstance.callMethod('ngOnDestroy', []).toStmt());
  }
}
