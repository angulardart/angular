import 'package:angular_compiler/v1/src/compiler/identifiers.dart';
import 'package:angular_compiler/v1/src/compiler/ir/model.dart';
import 'package:angular_compiler/v1/src/compiler/output/output_ast.dart';
import 'package:angular_compiler/v2/context.dart';

/// Optionally returns a statement that records a [binding] for developer tools.
///
/// If [CompileContext.isDevToolsEnabled] is true and [binding] is an `@Input()`
/// binding, this returns an `if` statement that records the bound [value] for
/// inspection when developer tooling is enabled:
///
/// ```
/// if (isDevToolsEnabled) {
///   ComponentInspector.recordInput(component, 'name', value);
/// }
/// ```
///
/// Otherwise, this returns null.
Statement devToolsBindingStatement(
  Binding binding,
  Expression receiver,
  Expression value,
) {
  if (!CompileContext.current.isDevToolsEnabled) {
    return null;
  }

  var target = binding.target;
  if (target is InputBinding) {
    return IfStmt(importExpr(DevTools.isDevToolsEnabled), [
      _recordInputStatement(receiver, literal(target.templateName), value),
    ]);
  }

  return null;
}

/// Returns a statement that records an input binding.
///
/// ```
/// ComponentInspector.recordInput(component, name, value);
/// ```
Statement _recordInputStatement(
  Expression component,
  Expression name,
  Expression value,
) {
  return importExpr(DevTools.componentInspector)
      .callMethod('recordInput', [component, name, value]).toStmt();
}
