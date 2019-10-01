import 'package:meta/meta.dart';

import '../template_ast.dart';

/// A visitor for [TemplateAst] trees that will process each node.
abstract class RecursiveTemplateVisitor<C>
    implements TemplateAstVisitor<TemplateAst, C> {
  /// Visits a collection of [TemplateAst] nodes, returning all of those that
  /// are not null.
  List<T> visitAll<T extends TemplateAst>(Iterable<T> astNodes, [C context]) {
    if (astNodes == null) return null;

    final results = <T>[];
    for (final astNode in astNodes) {
      var value = visit(astNode, context);
      if (value != null) {
        results.add(value);
      }
    }
    return results;
  }

  T visit<T extends TemplateAst>(T astNode, [C context]) =>
      astNode?.visit(this, context) as T;

  @override
  @mustCallSuper
  TemplateAst visitEmbeddedTemplate(EmbeddedTemplateAst ast, C context) =>
      EmbeddedTemplateAst(
          visitAll(ast.attrs, context),
          visitAll(ast.references, context),
          visitAll(ast.variables, context),
          visitAll(ast.directives, context),
          visitAll(ast.providers, context),
          ast.elementProviderUsage,
          visitAll(ast.children, context),
          ast.ngContentIndex,
          ast.sourceSpan,
          hasDeferredComponent: ast.hasDeferredComponent);

  @override
  @mustCallSuper
  TemplateAst visitElement(ElementAst ast, C context) => ElementAst(
      ast.name,
      visitAll(ast.attrs, context),
      visitAll(ast.inputs, context),
      visitAll(ast.outputs, context),
      visitAll(ast.references, context),
      visitAll(ast.directives, context),
      visitAll(ast.providers, context),
      ast.elementProviderUsage,
      visitAll(ast.children, context),
      ast.ngContentIndex,
      ast.sourceSpan);

  @override
  @mustCallSuper
  TemplateAst visitDirective(DirectiveAst ast, C context) => DirectiveAst(
        ast.directive,
        inputs: visitAll(ast.inputs, context),
        outputs: visitAll(ast.outputs, context),
        sourceSpan: ast.sourceSpan,
      );

  @override
  @mustCallSuper
  TemplateAst visitNgContainer(NgContainerAst ast, context) =>
      NgContainerAst(visitAll(ast.children, context), ast.sourceSpan);

  @override
  TemplateAst visitNgContent(NgContentAst ast, _) => ast;

  @override
  TemplateAst visitReference(ReferenceAst ast, _) => ast;

  @override
  TemplateAst visitVariable(VariableAst ast, _) => ast;

  @override
  TemplateAst visitEvent(BoundEventAst ast, _) => ast;

  @override
  TemplateAst visitElementProperty(BoundElementPropertyAst ast, _) => ast;

  @override
  TemplateAst visitAttr(AttrAst ast, _) => ast;

  @override
  TemplateAst visitBoundText(BoundTextAst ast, _) => ast;

  @override
  TemplateAst visitText(TextAst ast, _) => ast;

  @override
  TemplateAst visitDirectiveProperty(BoundDirectivePropertyAst ast, _) => ast;

  @override
  TemplateAst visitDirectiveEvent(BoundDirectiveEventAst ast, _) => ast;

  @override
  TemplateAst visitProvider(ProviderAst ast, _) => ast;

  @override
  TemplateAst visitI18nText(I18nTextAst ast, _) => ast;
}

// TODO(b/141691580): This should be named `RecursiveTemplateVisitor`, while the
// existing class should be renamed to indicate that it recreates the AST.
abstract class InPlaceRecursiveTemplateVisitor<C>
    implements TemplateAstVisitor<void, C> {
  void visitAll(Iterable<TemplateAst> astNodes, [C context]) {
    if (astNodes == null) return;
    for (final astNode in astNodes) {
      astNode.visit(this, context);
    }
  }

  @override
  @mustCallSuper
  void visitEmbeddedTemplate(EmbeddedTemplateAst ast, C context) {
    visitAll(ast.attrs, context);
    visitAll(ast.references, context);
    visitAll(ast.variables, context);
    visitAll(ast.directives, context);
    visitAll(ast.providers, context);
    visitAll(ast.children, context);
  }

  @override
  @mustCallSuper
  void visitElement(ElementAst ast, C context) {
    visitAll(ast.attrs, context);
    visitAll(ast.inputs, context);
    visitAll(ast.outputs, context);
    visitAll(ast.references, context);
    visitAll(ast.directives, context);
    visitAll(ast.providers, context);
    visitAll(ast.children, context);
  }

  @override
  @mustCallSuper
  void visitDirective(DirectiveAst ast, C context) {
    visitAll(ast.inputs, context);
    visitAll(ast.outputs, context);
  }

  @override
  @mustCallSuper
  void visitNgContainer(NgContainerAst ast, context) {
    visitAll(ast.children, context);
  }

  @override
  void visitNgContent(NgContentAst ast, _) {}

  @override
  void visitReference(ReferenceAst ast, _) {}

  @override
  void visitVariable(VariableAst ast, _) {}

  @override
  void visitEvent(BoundEventAst ast, _) {}

  @override
  void visitElementProperty(BoundElementPropertyAst ast, _) {}

  @override
  void visitAttr(AttrAst ast, _) {}

  @override
  void visitBoundText(BoundTextAst ast, _) {}

  @override
  void visitText(TextAst ast, _) {}

  @override
  void visitDirectiveProperty(BoundDirectivePropertyAst ast, _) {}

  @override
  void visitDirectiveEvent(BoundDirectiveEventAst ast, _) {}

  @override
  void visitProvider(ProviderAst ast, _) {}

  @override
  void visitI18nText(I18nTextAst ast, _) {}
}
