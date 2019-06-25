import 'package:angular/src/compiler/compile_metadata.dart'
    show CompilePipeMetadata, LifecycleHooks;
import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular/src/compiler/view_compiler/compile_method.dart';
import 'package:angular/src/compiler/view_compiler/ir/provider_source.dart';

import 'compile_element.dart' show CompileElement;
import 'compile_view.dart' show CompileView, notThrowOnChanges;
import 'constants.dart' show DetectChangesVars, Lifecycles;

void bindDirectiveDetectChangesLifecycleCallbacks(
  ir.MatchedDirective directive,
  CompileElement compileElement,
) {
  final detectChangesInInputsMethod =
      compileElement.view.detectChangesInInputsMethod;
  _bindAfterChanges(directive, detectChangesInInputsMethod);
  _bindOnInit(directive, detectChangesInInputsMethod);
  _bindDoCheck(directive, detectChangesInInputsMethod);
}

void _bindAfterChanges(ir.MatchedDirective directive, CompileMethod method) {
  if (directive.hasLifecycle(ir.Lifecycle.afterChanges)) {
    method.addStmt(o.IfStmt(
      DetectChangesVars.changed,
      [_lifecycleMethod(directive.providerSource, Lifecycles.afterChanges)],
    ));
  }
}

void _bindOnInit(ir.MatchedDirective directive, CompileMethod method) {
  if (directive.hasLifecycle(ir.Lifecycle.onInit)) {
    // We don't re-use the existing IfStmt (.addStmtsIfFirstCheck), because we
    // require an additional condition (`notThrowOnChanges`).
    method.addStmt(o.IfStmt(
      notThrowOnChanges.and(DetectChangesVars.firstCheck),
      [
        _lifecycleMethod(directive.providerSource, Lifecycles.onInit),
      ],
    ));
  }
}

void _bindDoCheck(ir.MatchedDirective directive, CompileMethod method) {
  if (directive.hasLifecycle(ir.Lifecycle.doCheck)) {
    method.addStmt(o.IfStmt(notThrowOnChanges, [
      _lifecycleMethod(directive.providerSource, Lifecycles.doCheck),
    ]));
  }
}

void bindDirectiveAfterChildrenCallbacks(
  ir.MatchedDirective directive,
  CompileElement compileElement,
) {
  _bindAfterContentCallbacks(directive, compileElement);
  _bindAfterViewCallbacks(directive, compileElement);
  _bindDestroyCallbacks(directive, compileElement);
}

void _bindAfterContentCallbacks(
  ir.MatchedDirective directive,
  CompileElement compileElement,
) {
  final view = compileElement.view;
  final lifecycleCallbacks = view.afterContentLifecycleCallbacksMethod;
  if (directive.hasLifecycle(ir.Lifecycle.afterContentInit)) {
    lifecycleCallbacks.addStmtsIfFirstCheck([
      _lifecycleMethod(directive.providerSource, Lifecycles.afterContentInit),
    ]);
  }
  if (directive.hasLifecycle(ir.Lifecycle.afterContentChecked)) {
    lifecycleCallbacks.addStmt(
      _lifecycleMethod(
          directive.providerSource, Lifecycles.afterContentChecked),
    );
  }
}

void _bindAfterViewCallbacks(
  ir.MatchedDirective directive,
  CompileElement compileElement,
) {
  final view = compileElement.view;
  final lifecycleCallbacks = view.afterViewLifecycleCallbacksMethod;
  if (directive.hasLifecycle(ir.Lifecycle.afterViewInit)) {
    lifecycleCallbacks.addStmtsIfFirstCheck([
      _lifecycleMethod(directive.providerSource, Lifecycles.afterViewInit),
    ]);
  }
  if (directive.hasLifecycle(ir.Lifecycle.afterViewChecked)) {
    lifecycleCallbacks.addStmt(_lifecycleMethod(
        directive.providerSource, Lifecycles.afterViewChecked));
  }
}

/// Call ngOnDestroy for each directive that implements `OnDestroy`.
void _bindDestroyCallbacks(
  ir.MatchedDirective directive,
  CompileElement compileElement,
) {
  if (directive.hasLifecycle(ir.Lifecycle.onDestroy)) {
    compileElement.view.destroyMethod.addStmt(
        _lifecycleMethod(directive.providerSource, Lifecycles.onDestroy));
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
