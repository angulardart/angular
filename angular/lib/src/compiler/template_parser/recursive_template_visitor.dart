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
      new EmbeddedTemplateAst(
          visitAll(ast.attrs, context),
          visitAll(ast.outputs, context),
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
  TemplateAst visitElement(ElementAst ast, C context) => new ElementAst(
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
  TemplateAst visitDirective(DirectiveAst ast, C context) => new DirectiveAst(
      ast.directive,
      visitAll(ast.inputs, context),
      visitAll(ast.hostProperties, context),
      visitAll(ast.hostEvents, context),
      ast.sourceSpan);

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
  TemplateAst visitProvider(ProviderAst ast, _) => ast;
}
