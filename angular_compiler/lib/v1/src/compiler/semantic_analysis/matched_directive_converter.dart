import 'package:angular/src/meta.dart';
import 'package:angular_compiler/v1/src/compiler/analyzed_class.dart';
import 'package:angular_compiler/v1/src/compiler/compile_metadata.dart' as core;
import 'package:angular_compiler/v1/src/compiler/compile_metadata.dart';
import 'package:angular_compiler/v1/src/compiler/ir/model.dart' as ir;
import 'package:angular_compiler/v1/src/compiler/optimize_ir/merge_events.dart';
import 'package:angular_compiler/v1/src/compiler/semantic_analysis/binding_converter.dart';
import 'package:angular_compiler/v1/src/compiler/template_ast.dart' as ast;
import 'package:angular_compiler/v1/src/compiler/view_compiler/compile_element.dart';
import 'package:angular_compiler/v1/src/compiler/view_compiler/ir/provider_source.dart';

/// Converts a list of [ast.DirectiveAst] nodes into [ir.MatchedDirective]
/// instances.
///
/// [CompileElement] represents the element in the template that the directive
/// has matched.
///
/// [AnalyzedClass] represents the Component class that is currently being
/// compiled.
List<ir.MatchedDirective> convertMatchedDirectives(
  Iterable<ast.DirectiveAst> directives,
  CompileElement compileElement,
  CompileDirectiveMetadata compileDirectiveMetadata,
) {
  final matchedDirectives = <ir.MatchedDirective>[];
  var index = -1;
  for (var directive in directives) {
    index++;
    var providerSource = compileElement.directiveInstances[index];
    matchedDirectives.add(convertMatchedDirective(
        directive, providerSource, compileElement, compileDirectiveMetadata));
  }
  return matchedDirectives;
}

/// Converts a single [ast.DirectiveAst] node into a [ir.MatchedDirective]
/// instance.
///
/// [ProviderSource] represents the underlying Directive instance that has been
/// matched.
///
/// [CompileElement] represents the element in the template that the directive
/// has matched.
///
/// [AnalyzedClass] represents the Component class that is currently being
/// compiled.
ir.MatchedDirective convertMatchedDirective(
  ast.DirectiveAst directive,
  ProviderSource? providerSource,
  CompileElement compileElement,
  CompileDirectiveMetadata compileDirectiveMetadata,
) {
  var inputs = convertAllToBinding(
    directive.inputs,
    directive: directive.directive,
    compileDirectiveMetadata: compileDirectiveMetadata,
    compileElement: compileElement,
  );

  var outputs = convertAllToBinding(
    directive.outputs,
    directive: directive.directive,
    compileDirectiveMetadata: compileDirectiveMetadata,
    compileElement: compileElement,
  );
  outputs = mergeEvents(outputs);

  return ir.MatchedDirective(
    providerSource: providerSource,
    inputs: inputs,
    outputs: outputs,
    hasInputs: directive.directive.inputs.isNotEmpty,
    hasHostProperties: directive.hasHostProperties,
    isComponent: directive.directive.isComponent,
    isOnPush:
        directive.directive.changeDetection == ChangeDetectionStrategy.OnPush,
    lifecycles: _lifecycles(directive.directive),
  );
}

Set<ir.Lifecycle> _lifecycles(core.CompileDirectiveMetadata directive) =>
    ir.Lifecycle.values
        .where((lifecycle) =>
            directive.lifecycleHooks.contains(_lifecyclesAsIr[lifecycle]))
        .toSet();

const _lifecyclesAsIr = {
  ir.Lifecycle.afterChanges: core.LifecycleHooks.afterChanges,
  ir.Lifecycle.onInit: core.LifecycleHooks.onInit,
  ir.Lifecycle.doCheck: core.LifecycleHooks.doCheck,
  ir.Lifecycle.afterContentInit: core.LifecycleHooks.afterContentInit,
  ir.Lifecycle.afterContentChecked: core.LifecycleHooks.afterContentChecked,
  ir.Lifecycle.afterViewInit: core.LifecycleHooks.afterViewInit,
  ir.Lifecycle.afterViewChecked: core.LifecycleHooks.afterViewChecked,
  ir.Lifecycle.onDestroy: core.LifecycleHooks.onDestroy,
};
