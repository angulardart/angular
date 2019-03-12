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

void bindDirectiveDetectChangesLifecycleCallbacks(
  DirectiveAst directiveAst,
  o.Expression directiveInstance,
  CompileElement compileElement,
) {
  final view = compileElement.view;
  final detectChangesInInputsMethod = view.detectChangesInInputsMethod;
  final directive = directiveAst.directive;
  final lifecycleHooks = directive.lifecycleHooks;
  if (lifecycleHooks.contains(LifecycleHooks.onChanges) &&
      directiveAst.inputs.isNotEmpty) {
    detectChangesInInputsMethod.addStmt(
      o.IfStmt(
        DetectChangesVars.changes.notIdentical(o.NULL_EXPR),
        [
          directiveInstance.callMethod(
            'ngOnChanges',
            [DetectChangesVars.changes],
          ).toStmt()
        ],
      ),
    );
  }
  if (lifecycleHooks.contains(LifecycleHooks.afterChanges) &&
      directiveAst.inputs.isNotEmpty) {
    if (directiveAst.directive.changeDetection ==
        ChangeDetectionStrategy.Stateful) {
      detectChangesInInputsMethod.addStmt(
        directiveInstance.callMethod('ngAfterChanges', const []).toStmt(),
      );
    } else {
      detectChangesInInputsMethod.addStmt(o.IfStmt(
        DetectChangesVars.changed,
        [directiveInstance.callMethod('ngAfterChanges', const []).toStmt()],
      ));
    }
  }
  if (lifecycleHooks.contains(LifecycleHooks.onInit)) {
    // We don't re-use the existing IfStmt (.addStmtsIfFirstCheck), because we
    // require an additional condition (`notThrowOnChanges`).
    detectChangesInInputsMethod.addStmt(o.IfStmt(
      notThrowOnChanges.and(DetectChangesVars.firstCheck),
      [
        directiveInstance.callMethod(
          'ngOnInit',
          [],
        ).toStmt(),
      ],
    ));
  }
  if (lifecycleHooks.contains(LifecycleHooks.doCheck)) {
    detectChangesInInputsMethod.addStmt(o.IfStmt(notThrowOnChanges, [
      directiveInstance.callMethod('ngDoCheck', []).toStmt(),
    ]));
  }
}

void bindDirectiveAfterContentLifecycleCallbacks(
  CompileDirectiveMetadata directiveMeta,
  o.Expression directiveInstance,
  CompileElement compileElement,
) {
  final view = compileElement.view;
  final lifecycleHooks = directiveMeta.lifecycleHooks;
  final lifecycleCallbacks = view.afterContentLifecycleCallbacksMethod;
  if (lifecycleHooks.contains(LifecycleHooks.afterContentInit)) {
    lifecycleCallbacks.addStmtsIfFirstCheck([
      directiveInstance.callMethod(
        'ngAfterContentInit',
        [],
      ).toStmt(),
    ]);
  }
  if (lifecycleHooks.contains(LifecycleHooks.afterContentChecked)) {
    lifecycleCallbacks.addStmt(
      directiveInstance.callMethod('ngAfterContentChecked', []).toStmt(),
    );
  }
}

void bindDirectiveAfterViewLifecycleCallbacks(
  CompileDirectiveMetadata directiveMeta,
  o.Expression directiveInstance,
  CompileElement compileElement,
) {
  final view = compileElement.view;
  final lifecycleHooks = directiveMeta.lifecycleHooks;
  final lifecycleCallbacks = view.afterViewLifecycleCallbacksMethod;
  if (lifecycleHooks.contains(LifecycleHooks.afterViewInit)) {
    lifecycleCallbacks.addStmtsIfFirstCheck([
      directiveInstance.callMethod(
        'ngAfterViewInit',
        [],
      ).toStmt(),
    ]);
  }
  if (lifecycleHooks.contains(LifecycleHooks.afterViewChecked)) {
    lifecycleCallbacks.addStmt(directiveInstance.callMethod(
      'ngAfterViewChecked',
      [],
    ).toStmt());
  }
}

/// Call ngOnDestroy for each directive that implements `OnDestroy`.
void bindDirectiveDestroyLifecycleCallbacks(
  CompileDirectiveMetadata directiveMeta,
  o.Expression directiveInstance,
  CompileElement compileElement,
) {
  if (directiveMeta.lifecycleHooks.contains(LifecycleHooks.onDestroy)) {
    compileElement.view.destroyMethod.addStmt(directiveInstance.callMethod(
      'ngOnDestroy',
      [],
    ).toStmt());
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
      'ngOnDestroy',
      [],
    ).toStmt());
  }
}
