import "../template_ast.dart" show TemplateAst;
import "compile_element.dart" show CompileNode;

class CompileBinding {
  final CompileNode node;
  final TemplateAst sourceAst;
  CompileBinding(this.node, this.sourceAst);
}
