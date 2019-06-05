import 'package:angular/src/compiler/template_ast.dart';

/// Determines if an AST is pure vanilla HTML.
///
/// An AST is "pure" if it contains no Angular-specific markup, and could be
/// rendered in a browser as normal HTML.
class IsPureHtmlVisitor extends TemplateAstVisitor<bool, Null> {
  @override
  bool visitAttr(AttrAst ast, _) => true;

  @override
  bool visitBoundText(BoundTextAst ast, _) => false;

  @override
  bool visitDirective(DirectiveAst ast, _) => false;

  @override
  bool visitDirectiveProperty(BoundDirectivePropertyAst ast, _) => false;

  @override
  bool visitDirectiveEvent(BoundDirectiveEventAst ast, _) => false;

  @override
  bool visitElement(ElementAst ast, _) {
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
  bool visitElementProperty(BoundElementPropertyAst ast, _) => false;

  @override
  bool visitEmbeddedTemplate(EmbeddedTemplateAst ast, _) => false;

  @override
  bool visitEvent(BoundEventAst ast, _) => false;

  @override
  bool visitNgContainer(NgContainerAst ast, _) =>
      ast.children.every((child) => child.visit(this, null));

  @override
  bool visitNgContent(NgContentAst ast, _) => false;

  @override
  bool visitProvider(ProviderAst providerAst, _) => false;

  @override
  bool visitReference(ReferenceAst ast, _) => false;

  @override
  bool visitText(TextAst ast, _) => true;

  @override
  bool visitVariable(VariableAst ast, _) => false;

  @override
  bool visitI18nText(I18nTextAst ast, _) => false;
}
