import 'package:angular_analyzer_plugin/ast.dart';

/// Extract [localVariables] from target node if it has any.
class LocalVariablesExtractor implements AngularAstVisitor {
  Map<String, LocalVariable> variables;

  // don't recurse
  @override
  void visitDocumentInfo(DocumentInfo document) {}

  @override
  void visitElementInfo(ElementInfo element) {}

  @override
  void visitEmptyStarBinding(EmptyStarBinding binding) {}

  @override
  void visitExpressionBoundAttr(ExpressionBoundAttribute attr) {
    variables = attr.localVariables;
  }

  @override
  void visitMustache(Mustache mustache) {
    variables = mustache.localVariables;
  }

  @override
  void visitStatementsBoundAttr(StatementsBoundAttribute attr) {
    variables = attr.localVariables;
  }

  @override
  void visitTemplateAttr(TemplateAttribute attr) {
    variables = attr.localVariables;
  }

  @override
  void visitTextAttr(TextAttribute attr) {}

  @override
  void visitTextInfo(TextInfo text) {}
}
