// http://go/migrate-deps-first
// @dart=2.9
import 'package:angular_compiler/v1/src/compiler/analyzed_class.dart';
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
  AnalyzedClass analyzedClass,
) {
  var inputs = convertAllToBinding(
    elementAst.inputs,
    analyzedClass: analyzedClass,
    compileElement: compileElement,
  );

  var outputs = convertAllToBinding(
    elementAst.outputs,
    analyzedClass: analyzedClass,
    compileElement: compileElement,
  );

  outputs = mergeEvents(outputs);

  var directives = convertMatchedDirectives(
    elementAst.directives,
    compileElement,
    analyzedClass,
  );
  directives = directives.map(optimizeLifecycles).toList();

  return ir.Element(
      compileElement, inputs, outputs, directives, elementAst.children, []);
}

ir.Element convertEmbeddedTemplate(
  ast.EmbeddedTemplateAst embeddedTemplate,
  CompileElement compileElement,
  AnalyzedClass analyzedClass,
) {
  var directives = convertMatchedDirectives(
      embeddedTemplate.directives, compileElement, analyzedClass);
  directives = directives.map(optimizeLifecycles).toList();

  var embeddedView = ir.EmbeddedView(
    embeddedTemplate.children,
  );

  embeddedView.compileView = compileElement.embeddedView;

  return ir.Element(compileElement, [], [], directives, [], [embeddedView]);
}
