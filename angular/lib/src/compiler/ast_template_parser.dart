import 'package:source_span/source_span.dart';
import 'package:angular_ast/angular_ast.dart' as ast;

import 'compile_metadata.dart';
import 'expression_parser/parser.dart';
import 'schema/element_schema_registry.dart';
import 'selector.dart';
import 'style_url_resolver.dart';
import 'template_ast.dart' as ng;
import 'template_parser.dart';
import 'template_preparser.dart';

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
    final filter = new ElementFilter();
    final filteredAst = filter.visitAll(parsedAst);
    final visitor = new Visitor(parser, schemaRegistry);
    final context = new ParseContext(directives: directives);
    return filteredAst
        .map((templateAst) => templateAst.accept(visitor, context))
        .toList();
  }
}

class Visitor implements ast.TemplateAstVisitor<ng.TemplateAst, ParseContext> {
  final Parser parser;
  final ElementSchemaRegistry schemaRegistry;

  /// A count of how many <ng-content> elements have been seen so far.
  ///
  /// This is necessary so that we can assign a unique index to each one as we
  /// visit it.
  int ngContentIndex = 0;

  Visitor(this.parser, this.schemaRegistry);

  @override
  ng.TemplateAst visitAttribute(ast.AttributeAst astNode, [ParseContext _]) =>
      new ng.AttrAst(astNode.name, astNode.value ?? '', astNode.sourceSpan);

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
  ng.TemplateAst visitElement(ast.ElementAst astNode, [ParseContext context]) {
    var matchedDirectives = _matchElementDirectives(context, astNode);
    var directiveAsts = _toAst(matchedDirectives, astNode.sourceSpan);
    final elementContext = context.withElementName(astNode.name);
    return new ng.ElementAst(
        astNode.name,
        _visitAll(astNode.attributes, elementContext),
        _visitAll(astNode.properties, elementContext),
        _visitAll(astNode.events, elementContext),
        _visitAll(astNode.references, elementContext),
        directiveAsts,
        [] /* providers */,
        null /* elementProviderUsage */,
        _visitAll(astNode.childNodes, elementContext),
        0 /* ngContentIndex */,
        astNode.sourceSpan);
  }

  @override
  ng.TemplateAst visitEmbeddedContent(ast.EmbeddedContentAst astNode,
          [ParseContext _]) =>
      new ng.NgContentAst(
          ngContentIndex++, 0 /* ngContentIndex */, astNode.sourceSpan);

  @override
  ng.TemplateAst visitEmbeddedTemplate(ast.EmbeddedTemplateAst astNode,
      [ParseContext context]) {
    var matchedDirectives = _matchTemplateDirectives(context, astNode);
    var directiveAsts = _toAst(matchedDirectives, astNode.sourceSpan);
    final embeddedContext = context.withElementName(TEMPLATE_ELEMENT);
    return new ng.EmbeddedTemplateAst(
        _visitAll(astNode.attributes, embeddedContext),
        _visitAll(astNode.events, embeddedContext),
        _visitAll(astNode.references, embeddedContext),
        _visitAll(astNode.letBindings, embeddedContext),
        directiveAsts,
        [] /* providers */,
        null /* elementProviderUsage */,
        _visitAll(astNode.childNodes, embeddedContext),
        0 /* ngContentIndex */,
        astNode.sourceSpan);
  }

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
  ng.TemplateAst visitProperty(ast.PropertyAst astNode,
      [ParseContext context]) {
    var value = parser.parseBinding(astNode.value, _location(astNode), []);
    return createElementPropertyAst(context.elementName, _getName(astNode),
        value, astNode.sourceSpan, schemaRegistry, (_, __, [___]) {});
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

  List<CompileDirectiveMetadata> _matchElementDirectives(
          ParseContext context, ast.ElementAst astNode) =>
      _parseDirectives(context.directives, _elementSelector(astNode));

  List<CompileDirectiveMetadata> _matchTemplateDirectives(
          ParseContext context, ast.EmbeddedTemplateAst astNode) =>
      _parseDirectives(context.directives, _templateSelector(astNode));

  CssSelector _elementSelector(ast.ElementAst astNode) => _selector(
      astNode.name, astNode.attributes, astNode.properties, astNode.events);

  CssSelector _templateSelector(ast.EmbeddedTemplateAst astNode) => _selector(
      TEMPLATE_ELEMENT, astNode.attributes, astNode.properties, astNode.events);

  CssSelector _selector(String elementName, List<ast.AttributeAst> attributes,
      List<ast.PropertyAst> properties, List<ast.EventAst> events) {
    final matchableAttributes = [];
    for (var attr in attributes) {
      matchableAttributes.add([attr.name, attr.value]);
    }
    for (var property in properties) {
      matchableAttributes.add([property.name, property.value]);
    }
    for (var event in events) {
      matchableAttributes.add([event.name, event.value]);
    }
    return createElementCssSelector(elementName, matchableAttributes);
  }

  List<CompileDirectiveMetadata> _parseDirectives(
      List<CompileDirectiveMetadata> directives,
      CssSelector elementCssSelector) {
    var matchedDirectives = new Set();
    _selectorMatcher(directives).match(elementCssSelector,
        (selector, directive) {
      matchedDirectives.add(directive);
    });
    // We return the directives in the same order that they are present in the
    // Component, not the order that they match in the html.
    return directives.where(matchedDirectives.contains).toList();
  }

  SelectorMatcher _selectorMatcher(List<CompileDirectiveMetadata> directives) {
    final SelectorMatcher selectorMatcher = new SelectorMatcher();
    for (var directive in directives) {
      var selector = CssSelector.parse(directive.selector);
      selectorMatcher.addSelectables(selector, directive);
    }
    return selectorMatcher;
  }

  List<ng.DirectiveAst> _toAst(
          Iterable<CompileDirectiveMetadata> directiveMetas,
          SourceSpan sourceSpan) =>
      directiveMetas
          .map((directive) => new ng.DirectiveAst(directive, [] /* inputs */,
              [] /* hostProperties */, [] /* hostEvents */, sourceSpan))
          .toList();

  static String _location(ast.TemplateAst astNode) =>
      astNode.isSynthetic ? '' : astNode.sourceSpan.start.toString();
}

class ParseContext {
  final List<CompileDirectiveMetadata> directives;
  final String elementName;

  ParseContext({this.directives, this.elementName});

  ParseContext withElementName(String name) =>
      new ParseContext(elementName: name, directives: directives);
}

/// Visitor which filters elements that are not supported in angular templates.
class ElementFilter implements ast.TemplateAstVisitor<ast.TemplateAst, bool> {
  List<T> visitAll<T extends ast.TemplateAst>(Iterable<T> astNodes,
      [bool hasNgNonBindable = false]) {
    final result = <T>[];
    for (final node in astNodes) {
      final visited = node.accept(this, hasNgNonBindable);
      if (visited != null) result.add(visited);
    }
    return result;
  }

  @override
  ast.TemplateAst visitElement(ast.ElementAst astNode,
      [bool hasNgNonBindable]) {
    if (_filterElement(astNode, hasNgNonBindable)) {
      return null;
    }
    hasNgNonBindable =
        hasNgNonBindable || _hasNgNOnBindable(astNode.attributes);
    return new ast.ElementAst.from(
        astNode, astNode.name, astNode.closeComplement,
        attributes: visitAll(astNode.attributes, hasNgNonBindable),
        childNodes: visitAll(astNode.childNodes, hasNgNonBindable),
        events: visitAll(astNode.events, hasNgNonBindable),
        properties: visitAll(astNode.properties, hasNgNonBindable),
        references: visitAll(astNode.references, hasNgNonBindable),
        bananas: visitAll(astNode.bananas, hasNgNonBindable),
        stars: visitAll(astNode.stars, hasNgNonBindable));
  }

  @override
  ast.TemplateAst visitEmbeddedContent(ast.EmbeddedContentAst astNode,
          [bool hasNgNonBindable]) =>
      hasNgNonBindable
          ? new ast.ElementAst.from(
              astNode, NG_CONTENT_ELEMENT, astNode.closeComplement,
              childNodes: visitAll(astNode.childNodes, hasNgNonBindable))
          : astNode;

  @override
  ast.TemplateAst visitInterpolation(ast.InterpolationAst astNode,
          [bool hasNgNonBindable]) =>
      hasNgNonBindable
          ? new ast.TextAst.from(astNode, '{{${astNode.value}}}')
          : astNode;

  static bool _filterElement(ast.ElementAst astNode, bool hasNgNonBindable) =>
      _filterScripts(astNode) ||
      _filterStyles(astNode) ||
      _filterStyleSheets(astNode, hasNgNonBindable);

  static bool _filterStyles(ast.ElementAst astNode) =>
      astNode.name.toLowerCase() == STYLE_ELEMENT;

  static bool _filterScripts(ast.ElementAst astNode) =>
      astNode.name.toLowerCase() == SCRIPT_ELEMENT;

  static bool _filterStyleSheets(
      ast.ElementAst astNode, bool hasNgNonBindable) {
    if (astNode.name != LINK_ELEMENT) return false;
    var href = _findHref(astNode.attributes);
    return hasNgNonBindable || isStyleUrlResolvable(href?.value);
  }

  static ast.AttributeAst _findHref(List<ast.AttributeAst> attributes) {
    for (var attr in attributes) {
      if (attr.name.toLowerCase() == LINK_STYLE_HREF_ATTR) return attr;
    }
    return null;
  }

  bool _hasNgNOnBindable(List<ast.AttributeAst> attributes) {
    for (var attr in attributes) {
      if (attr.name == NG_NON_BINDABLE_ATTR) return true;
    }
    return false;
  }

  @override
  ast.TemplateAst visitAttribute(ast.AttributeAst astNode, [bool _]) => astNode;

  @override
  ast.TemplateAst visitBanana(ast.BananaAst astNode, [bool _]) => astNode;

  @override
  ast.TemplateAst visitCloseElement(ast.CloseElementAst astNode, [bool _]) =>
      astNode;

  @override
  ast.TemplateAst visitComment(ast.CommentAst astNode, [bool _]) => astNode;

  @override
  ast.TemplateAst visitEmbeddedTemplate(ast.EmbeddedTemplateAst astNode,
          [bool _]) =>
      astNode;

  @override
  ast.TemplateAst visitEvent(ast.EventAst astNode, [bool _]) => astNode;

  @override
  ast.TemplateAst visitExpression(ast.ExpressionAst astNode, [bool _]) =>
      astNode;

  @override
  ast.TemplateAst visitLetBinding(ast.LetBindingAst astNode, [bool _]) =>
      astNode;

  @override
  ast.TemplateAst visitProperty(ast.PropertyAst astNode, [bool _]) => astNode;

  @override
  ast.TemplateAst visitReference(ast.ReferenceAst astNode, [bool _]) => astNode;

  @override
  ast.TemplateAst visitStar(ast.StarAst astNode, [bool _]) => astNode;

  @override
  ast.TemplateAst visitText(ast.TextAst astNode, [bool _]) => astNode;
}
