library angular2.src.compiler.view_compiler.compile_binding;

import "compile_element.dart" show CompileNode;
import "../template_ast.dart" show TemplateAst;

class CompileBinding {
  CompileNode node;
  TemplateAst sourceAst;
  CompileBinding(this.node, this.sourceAst) {}
}
