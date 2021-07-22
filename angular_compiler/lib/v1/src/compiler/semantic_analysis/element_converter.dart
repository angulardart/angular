import 'package:angular_compiler/v1/src/compiler/compile_metadata.dart';
import 'package:angular_compiler/v1/src/compiler/ir/model.dart' as ir;
import 'package:angular_compiler/v1/src/compiler/optimize_ir/merge_events.dart';
import 'package:angular_compiler/v1/src/compiler/optimize_ir/optimize_lifecycles.dart';
import 'package:angular_compiler/v1/src/compiler/semantic_analysis/binding_converter.dart';
import 'package:angular_compiler/v1/src/compiler/semantic_analysis/matched_directive_converter.dart';
import 'package:angular_compiler/v1/src/compiler/template_ast.dart' as ast;
import 'package:angular_compiler/v1/src/compiler/view_compiler/compile_element.dart';

ir.Element convertElement(
  ast.ElementAst elementAst,
  CompileElement compileElement,
  CompileDirectiveMetadata? compileDirectiveMetadata,
) {
  var inputs = convertAllToBinding(
    elementAst.inputs,
    compileDirectiveMetadata: compileDirectiveMetadata,
    compileElement: compileElement,
  );

  var outputs = convertAllToBinding(
    elementAst.outputs,
    compileDirectiveMetadata: compileDirectiveMetadata,
    compileElement: compileElement,
  );

  outputs = mergeEvents(outputs);

  var directives = convertMatchedDirectives(
    elementAst.directives,
    compileElement,
    compileDirectiveMetadata!,
  );
  directives = directives.map(optimizeLifecycles).toList();

  return ir.Element(
      compileElement, inputs, outputs, directives, elementAst.children, []);
}

ir.Element convertEmbeddedTemplate(
  ast.EmbeddedTemplateAst embeddedTemplate,
  CompileElement compileElement,
  CompileDirectiveMetadata compileDirectiveMetadata,
) {
  var directives = convertMatchedDirectives(
    embeddedTemplate.directives,
    compileElement,
    compileDirectiveMetadata,
  );
  directives = directives.map(optimizeLifecycles).toList();

  var embeddedView = ir.EmbeddedView(
    embeddedTemplate.children,
  );

  embeddedView.compileView = compileElement.embeddedView;

  return ir.Element(compileElement, [], [], directives, [], [embeddedView]);
}
