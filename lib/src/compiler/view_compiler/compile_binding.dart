library angular2.src.compiler.view_compiler.compile_binding;

import "../template_ast.dart" show TemplateAst;
import "compile_element.dart" show CompileNode;

class CompileBinding {
  CompileNode node;
  TemplateAst sourceAst;
  CompileBinding(this.node, this.sourceAst) {}
}
