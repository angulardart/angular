import 'template_ast.dart';

/// Determines if an AST is pure vanilla HTML.
///
/// An AST is "pure" if it contains no Angular-specific markup, and could be
/// rendered in a browser as normal HTML.
class IsPureHtmlVisitor extends TemplateAstVisitor<bool, Null> {
  @override
  bool visitAttr(AttrAst ast, dynamic context) => true;

  @override
  bool visitBoundText(BoundTextAst ast, dynamic context) => false;

  @override
  bool visitDirective(DirectiveAst ast, dynamic context) => false;

  @override
  bool visitDirectiveProperty(BoundDirectivePropertyAst ast, dynamic context) =>
      false;

  @override
  bool visitElement(ElementAst ast, dynamic context) {
    var isComponent = ast.directives.any((d) => d.directive.isComponent);

    if (isComponent ||
        ast.inputs.isNotEmpty ||
        ast.outputs.isNotEmpty ||
        ast.providers.isNotEmpty ||
        ast.references.isNotEmpty) {
      return false;
    }
    return ast.children.every((t) => t.visit(this, null));
  }

  @override
  bool visitElementProperty(BoundElementPropertyAst ast, dynamic context) =>
      false;

  @override
  bool visitEmbeddedTemplate(EmbeddedTemplateAst ast, dynamic context) => false;

  @override
  bool visitEvent(BoundEventAst ast, dynamic context) => false;

  @override
  bool visitNgContent(NgContentAst ast, dynamic context) => false;

  @override
  bool visitProvider(ProviderAst providerAst, dynamic context) => false;

  @override
  bool visitReference(ReferenceAst ast, dynamic context) => false;

  @override
  bool visitText(TextAst ast, dynamic context) => true;

  @override
  bool visitVariable(VariableAst ast, dynamic context) => false;
}
