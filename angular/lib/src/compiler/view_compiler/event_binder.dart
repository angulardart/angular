import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular/src/compiler/view_compiler/bound_value_converter.dart'
    show BoundValueConverter;

import 'compile_element.dart' show CompileElement;

void bindDirectiveOutputs(
  List<ir.Binding> outputs,
  o.Expression directiveInstance,
  CompileElement compileElement,
) {
  var view = compileElement.view;
  var converter = BoundValueConverter.forView(view);
  for (var output in outputs) {
    var handlerExpr = converter
        .scopeNamespace()
        .convertSourceToExpression(output.source, output.target.type);
    var nodeReference = view.createSubscription(
      isMockLike: (output.target as ir.DirectiveOutput).isMockLike,
    );
    view.addEventListener(
        nodeReference, output, handlerExpr, directiveInstance);
  }
}

void bindRenderOutputs(
    List<ir.Binding> outputs, CompileElement compileElement) {
  var converter = BoundValueConverter.forView(compileElement.view);
  for (var output in outputs) {
    var handlerExpr = converter
        .scopeNamespace()
        .convertSourceToExpression(output.source, output.target.type);
    compileElement.view
        .addEventListener(compileElement.renderNode, output, handlerExpr);
  }
}
