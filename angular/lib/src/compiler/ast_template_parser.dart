import 'package:angular_ast/angular_ast.dart' as ast;

import 'compile_metadata.dart';
import 'expression_parser/parser.dart';
import 'schema/element_schema_registry.dart';
import 'template_ast.dart' as ng;
import 'template_parser.dart';

/// A [TemplateParser] which uses the `angular_ast` package to parse angular
/// templates.
class AstTemplateParser implements TemplateParser {
  @override
  final ElementSchemaRegistry schemaRegistry;

  final Parser parser;

  AstTemplateParser(this.schemaRegistry, this.parser);

  @override
  List<ng.TemplateAst> parse(
      CompileDirectiveMetadata compMeta,
      String template,
      List<CompileDirectiveMetadata> directives,
      List<CompilePipeMetadata> pipes,
      String name) {
    final parsedAst = ast.parse(template,
        // TODO(alorenzen): Use real sourceUrl.
        sourceUrl: '/test#inline',
        desugar: true,
        toolFriendlyAst: true,
        parseExpressions: false);
    // TODO(alorenzen): Remove once all tests are passing.
    parsedAst.forEach(print);
    final visitor = new Visitor(parser, schemaRegistry);
    final context = new ParseContext();
    return parsedAst
        .map((templateAst) => templateAst.accept(visitor, context))
        .toList();
  }
}

class Visitor implements ast.TemplateAstVisitor<ng.TemplateAst, ParseContext> {
  final Parser parser;
  final ElementSchemaRegistry schemaRegistry;

  Visitor(this.parser, this.schemaRegistry);

  @override
  ng.TemplateAst visitAttribute(ast.AttributeAst astNode, [ParseContext _]) =>
      new ng.AttrAst(astNode.name, astNode.value, astNode.sourceSpan);

  @override
  ng.TemplateAst visitBanana(ast.BananaAst astNode, [ParseContext _]) =>
      throw new UnimplementedError('Don\'t know how to handle bananas');

  @override
  ng.TemplateAst visitCloseElement(ast.CloseElementAst astNode,
          [ParseContext _]) =>
      throw new UnimplementedError('Don\'t know how to handle close elements');

  @override
  ng.TemplateAst visitComment(ast.CommentAst astNode, [ParseContext _]) =>
      throw new UnimplementedError('Don\'t know how to handle comments.');

  @override
  ng.TemplateAst visitElement(ast.ElementAst astNode, [ParseContext context]) =>
      new ng.ElementAst(
          astNode.name,
          _visitAll(astNode.attributes, context),
          _visitAll(astNode.properties, context),
          _visitAll(astNode.events, context),
          _visitAll(astNode.references, context),
          [] /*directives */,
          [] /* providers */,
          null /* elementProviderUsage */,
          _visitAll(astNode.childNodes, context),
          0 /* ngContentIndex */,
          astNode.sourceSpan);

  @override
  ng.TemplateAst visitEmbeddedContent(ast.EmbeddedContentAst astNode,
          [ParseContext _]) =>
      new ng.NgContentAst(
          0 /* index */, 0 /* ngContentIndex */, astNode.sourceSpan);

  @override
  ng.TemplateAst visitEmbeddedTemplate(ast.EmbeddedTemplateAst astNode,
          [ParseContext context]) =>
      new ng.EmbeddedTemplateAst(
          _visitAll(astNode.attributes, context),
          _visitAll(astNode.events, context),
          _visitAll(astNode.references, context),
          _visitAll(astNode.letBindings, context),
          [] /* directives */,
          [] /* providers */,
          null /* elementProviderUsage */,
          _visitAll(astNode.childNodes, context),
          0 /* ngContentIndex */,
          astNode.sourceSpan);

  @override
  ng.TemplateAst visitEvent(ast.EventAst astNode, [ParseContext _]) {
    var value = parser.parseAction(astNode.value, _location(astNode), const []);
    return new ng.BoundEventAst(astNode.name, value, astNode.sourceSpan);
  }

  @override
  ng.TemplateAst visitExpression(ast.ExpressionAst astNode, [ParseContext _]) =>
      throw new UnimplementedError('Don\'t know how to handle expressions.');

  @override
  ng.TemplateAst visitInterpolation(ast.InterpolationAst astNode,
      [ParseContext _]) {
    var element = parser
        .parseInterpolation('{{${astNode.value}}}', _location(astNode), []);
    return new ng.BoundTextAst(
        element, 0 /* ngContentIndex */, astNode.sourceSpan);
  }

  @override
  ng.TemplateAst visitLetBinding(ast.LetBindingAst astNode, [ParseContext _]) =>
      new ng.VariableAst(astNode.name, astNode.value, astNode.sourceSpan);

  @override
  ng.TemplateAst visitProperty(ast.PropertyAst astNode, [ParseContext _]) {
    // TODO(alorenzen): Determine elementName;
    var elementName = 'div';
    var value = parser.parseBinding(astNode.value, _location(astNode), []);
    return createElementPropertyAst(elementName, _getName(astNode), value,
        astNode.sourceSpan, schemaRegistry, (_, __, [___]) {});
  }

  static String _getName(ast.PropertyAst astNode) {
    if (astNode.unit != null) {
      return '${astNode.name}.${astNode.postfix}.${astNode.unit}';
    }
    if (astNode.postfix != null) {
      return '${astNode.name}.${astNode.postfix}';
    }
    return astNode.name;
  }

  @override
  ng.TemplateAst visitReference(ast.ReferenceAst astNode, [ParseContext _]) =>
      new ng.ReferenceAst(
          astNode.variable, null /* value */, astNode.sourceSpan);

  @override
  ng.TemplateAst visitStar(ast.StarAst astNode, [ParseContext _]) =>
      throw new UnimplementedError('Don\'t know how to handle stars.');

  @override
  ng.TemplateAst visitText(ast.TextAst astNode, [ParseContext _]) =>
      new ng.TextAst(astNode.value, 0 /* ngContentIndex */, astNode.sourceSpan);

  List<T> _visitAll<T extends ng.TemplateAst>(
      List<ast.TemplateAst> astNodes, ParseContext context) {
    final results = <T>[];
    for (final astNode in astNodes) {
      results.add(astNode.accept(this, context) as T);
    }
    return results;
  }

  static String _location(ast.TemplateAst astNode) =>
      astNode.isSynthetic ? '' : astNode.sourceSpan.start.toString();
}

class ParseContext {}
