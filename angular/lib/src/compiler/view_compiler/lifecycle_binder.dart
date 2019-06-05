import 'package:angular/src/compiler/compile_metadata.dart'
    show CompileDirectiveMetadata, CompilePipeMetadata;
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular/src/compiler/template_ast.dart' show DirectiveAst;
import 'package:angular/src/compiler/view_compiler/compile_method.dart';
import 'package:angular/src/compiler/view_compiler/ir/provider_source.dart';
import 'package:angular/src/core/change_detection/change_detection.dart'
    show ChangeDetectionStrategy;
import 'package:angular/src/core/metadata/lifecycle_hooks.dart'
    show LifecycleHooks;

import 'compile_element.dart' show CompileElement;
import 'compile_view.dart' show CompileView, notThrowOnChanges;
import 'constants.dart' show DetectChangesVars, Lifecycles;

void bindDirectiveDetectChangesLifecycleCallbacks(
  DirectiveAst directiveAst,
  ProviderSource directiveInstance,
  CompileElement compileElement,
) {
  final detectChangesInInputsMethod =
      compileElement.view.detectChangesInInputsMethod;
  final directive = directiveAst.directive;
  final lifecycleHooks = directive.lifecycleHooks;
  _bindAfterChanges(lifecycleHooks, directiveAst, detectChangesInInputsMethod,
      directiveInstance);
  _bindOnInit(lifecycleHooks, detectChangesInInputsMethod, directiveInstance);
  _bindDoCheck(lifecycleHooks, detectChangesInInputsMethod, directiveInstance);
}

void _bindAfterChanges(
    List<LifecycleHooks> lifecycleHooks,
    DirectiveAst directiveAst,
    CompileMethod method,
    ProviderSource directiveInstance) {
  if (lifecycleHooks.contains(LifecycleHooks.afterChanges) &&
      directiveAst.inputs.isNotEmpty) {
    if (directiveAst.directive.changeDetection ==
        ChangeDetectionStrategy.Stateful) {
      method.addStmt(
        _lifecycleMethod(directiveInstance, Lifecycles.afterChanges),
      );
    } else {
      method.addStmt(o.IfStmt(
        DetectChangesVars.changed,
        [_lifecycleMethod(directiveInstance, Lifecycles.afterChanges)],
      ));
    }
  }
}

void _bindOnInit(List<LifecycleHooks> lifecycleHooks, CompileMethod method,
    ProviderSource directiveInstance) {
  if (lifecycleHooks.contains(LifecycleHooks.onInit)) {
    // We don't re-use the existing IfStmt (.addStmtsIfFirstCheck), because we
    // require an additional condition (`notThrowOnChanges`).
    method.addStmt(o.IfStmt(
      notThrowOnChanges.and(DetectChangesVars.firstCheck),
      [
        _lifecycleMethod(directiveInstance, Lifecycles.onInit),
      ],
    ));
  }
}

void _bindDoCheck(List<LifecycleHooks> lifecycleHooks, CompileMethod method,
    ProviderSource directiveInstance) {
  if (lifecycleHooks.contains(LifecycleHooks.doCheck)) {
    method.addStmt(o.IfStmt(notThrowOnChanges, [
      _lifecycleMethod(directiveInstance, Lifecycles.doCheck),
    ]));
  }
}

void bindDirectiveAfterChildrenCallbacks(CompileDirectiveMetadata directive,
    ProviderSource directiveInstance, CompileElement compileElement) {
  _bindAfterContentCallbacks(directive, directiveInstance, compileElement);
  _bindAfterViewCallbacks(directive, directiveInstance, compileElement);
  _bindDestroyCallbacks(directive, directiveInstance, compileElement);
}

void _bindAfterContentCallbacks(
  CompileDirectiveMetadata directiveMeta,
  ProviderSource directiveInstance,
  CompileElement compileElement,
) {
  final view = compileElement.view;
  final lifecycleHooks = directiveMeta.lifecycleHooks;
  final lifecycleCallbacks = view.afterContentLifecycleCallbacksMethod;
  if (lifecycleHooks.contains(LifecycleHooks.afterContentInit)) {
    lifecycleCallbacks.addStmtsIfFirstCheck([
      _lifecycleMethod(directiveInstance, Lifecycles.afterContentInit),
    ]);
  }
  if (lifecycleHooks.contains(LifecycleHooks.afterContentChecked)) {
    lifecycleCallbacks.addStmt(
      _lifecycleMethod(directiveInstance, Lifecycles.afterContentChecked),
    );
  }
}

void _bindAfterViewCallbacks(
  CompileDirectiveMetadata directiveMeta,
  ProviderSource directiveInstance,
  CompileElement compileElement,
) {
  final view = compileElement.view;
  final lifecycleHooks = directiveMeta.lifecycleHooks;
  final lifecycleCallbacks = view.afterViewLifecycleCallbacksMethod;
  if (lifecycleHooks.contains(LifecycleHooks.afterViewInit)) {
    lifecycleCallbacks.addStmtsIfFirstCheck([
      _lifecycleMethod(directiveInstance, Lifecycles.afterViewInit),
    ]);
  }
  if (lifecycleHooks.contains(LifecycleHooks.afterViewChecked)) {
    lifecycleCallbacks.addStmt(
        _lifecycleMethod(directiveInstance, Lifecycles.afterViewChecked));
  }
}

/// Call ngOnDestroy for each directive that implements `OnDestroy`.
void _bindDestroyCallbacks(
  CompileDirectiveMetadata directiveMeta,
  ProviderSource directiveInstance,
  CompileElement compileElement,
) {
  if (directiveMeta.lifecycleHooks.contains(LifecycleHooks.onDestroy)) {
    compileElement.view.destroyMethod
        .addStmt(_lifecycleMethod(directiveInstance, Lifecycles.onDestroy));
  }
}

/// Call ngOnDestroy for each pipe that implements `OnDestroy`.
void bindPipeDestroyLifecycleCallbacks(
  CompilePipeMetadata pipeMeta,
  o.Expression pipeInstance,
  CompileView view,
) {
  if (pipeMeta.lifecycleHooks.contains(LifecycleHooks.onDestroy)) {
    view.destroyMethod.addStmt(pipeInstance.callMethod(
      Lifecycles.onDestroy,
      [],
    ).toStmt());
  }
}

o.Statement _lifecycleMethod(ProviderSource directiveInstance, String name) {
  return directiveInstance.build().callMethod(
    name,
    [],
  ).toStmt();
}
