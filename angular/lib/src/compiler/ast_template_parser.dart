import 'package:source_span/source_span.dart';
import 'package:angular_ast/angular_ast.dart' as ast;

import 'compile_metadata.dart';
import 'expression_parser/ast.dart';
import 'expression_parser/parser.dart';
import 'identifiers.dart';
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
    final filter = new _ElementFilter();
    final filteredAst = filter.visitAll(parsedAst);
    final visitor = new _Visitor();
    final context = new _ParseContext.forRoot(new _TemplateContext(
        parser: parser,
        schemaRegistry: schemaRegistry,
        directives: directives,
        exports: compMeta.exports));
    return filteredAst
        .map((templateAst) => templateAst.accept(visitor, context))
        .toList();
  }
}

class _Visitor
    implements ast.TemplateAstVisitor<ng.TemplateAst, _ParseContext> {
  /// A count of how many <ng-content> elements have been seen so far.
  ///
  /// This is necessary so that we can assign a unique index to each one as we
  /// visit it.
  int ngContentIndex = 0;

  @override
  ng.TemplateAst visitElement(ast.ElementAst astNode, [_ParseContext context]) {
    final elementContext =
        new _ParseContext.forElement(astNode, context.templateContext);
    return new ng.ElementAst(
        astNode.name,
        _visitAll(astNode.attributes, elementContext),
        _visitAll(astNode.properties, elementContext),
        _visitAll(astNode.events, elementContext),
        _visitAll(astNode.references, elementContext),
        elementContext.boundDirectives,
        [] /* providers */,
        null /* elementProviderUsage */,
        _visitAll(astNode.childNodes, elementContext),
        0 /* ngContentIndex */,
        astNode.sourceSpan);
  }

  @override
  ng.TemplateAst visitEmbeddedTemplate(ast.EmbeddedTemplateAst astNode,
      [_ParseContext context]) {
    final embeddedContext =
        new _ParseContext.forTemplate(astNode, context.templateContext);
    return new ng.EmbeddedTemplateAst(
        _visitAll(astNode.attributes, embeddedContext),
        _visitAll(astNode.events, embeddedContext),
        _visitAll(astNode.references, embeddedContext),
        _visitAll(astNode.letBindings, embeddedContext),
        embeddedContext.boundDirectives,
        [] /* providers */,
        null /* elementProviderUsage */,
        _visitAll(astNode.childNodes, embeddedContext),
        0 /* ngContentIndex */,
        astNode.sourceSpan);
  }

  @override
  ng.TemplateAst visitEmbeddedContent(ast.EmbeddedContentAst astNode,
          [_ParseContext _]) =>
      new ng.NgContentAst(
          ngContentIndex++, 0 /* ngContentIndex */, astNode.sourceSpan);

  @override
  ng.TemplateAst visitEvent(ast.EventAst astNode, [_ParseContext context]) {
    var value = context.templateContext.parser
        .parseAction(astNode.value, _location(astNode), const []);
    return new ng.BoundEventAst(astNode.name, value, astNode.sourceSpan);
  }

  @override
  ng.TemplateAst visitAttribute(ast.AttributeAst astNode,
      [_ParseContext context]) {
    context.bindLiteralToDirective(astNode);
    return new ng.AttrAst(
        astNode.name, astNode.value ?? '', astNode.sourceSpan);
  }

  @override
  ng.TemplateAst visitProperty(ast.PropertyAst astNode,
      [_ParseContext context]) {
    var value = context.templateContext.parser
        .parseBinding(astNode.value, _location(astNode), []);
    if (context.bindPropertyToDirective(astNode, value)) return null;
    return createElementPropertyAst(
        context.elementName,
        _getPropertyName(astNode),
        value,
        astNode.sourceSpan,
        context.templateContext.schemaRegistry,
        (_, __, [___]) {});
  }

  static String _getPropertyName(ast.PropertyAst astNode) {
    if (astNode.unit != null) {
      return '${astNode.name}.${astNode.postfix}.${astNode.unit}';
    }
    if (astNode.postfix != null) {
      return '${astNode.name}.${astNode.postfix}';
    }
    return astNode.name;
  }

  @override
  ng.TemplateAst visitLetBinding(ast.LetBindingAst astNode,
          [_ParseContext _]) =>
      new ng.VariableAst(astNode.name, astNode.value, astNode.sourceSpan);

  @override
  ng.TemplateAst visitReference(ast.ReferenceAst astNode,
          [_ParseContext context]) =>
      new ng.ReferenceAst(
          astNode.variable,
          context.identifierForReference(astNode.identifier),
          astNode.sourceSpan);

  @override
  ng.TemplateAst visitText(ast.TextAst astNode, [_ParseContext _]) =>
      new ng.TextAst(astNode.value, 0 /* ngContentIndex */, astNode.sourceSpan);

  @override
  ng.TemplateAst visitInterpolation(ast.InterpolationAst astNode,
      [_ParseContext context]) {
    var element = context.templateContext.parser
        .parseInterpolation('{{${astNode.value}}}', _location(astNode), []);
    return new ng.BoundTextAst(
        element, 0 /* ngContentIndex */, astNode.sourceSpan);
  }

  @override
  ng.TemplateAst visitBanana(ast.BananaAst astNode, [_ParseContext _]) =>
      throw new UnimplementedError('Don\'t know how to handle bananas');

  @override
  ng.TemplateAst visitCloseElement(ast.CloseElementAst astNode,
          [_ParseContext _]) =>
      throw new UnimplementedError('Don\'t know how to handle close elements');

  @override
  ng.TemplateAst visitComment(ast.CommentAst astNode, [_ParseContext _]) =>
      throw new UnimplementedError('Don\'t know how to handle comments.');

  @override
  ng.TemplateAst visitExpression(ast.ExpressionAst astNode,
          [_ParseContext _]) =>
      throw new UnimplementedError('Don\'t know how to handle expressions.');

  @override
  ng.TemplateAst visitStar(ast.StarAst astNode, [_ParseContext _]) =>
      throw new UnimplementedError('Don\'t know how to handle stars.');

  List<T> _visitAll<T extends ng.TemplateAst>(
      List<ast.TemplateAst> astNodes, _ParseContext context) {
    final results = <T>[];
    for (final astNode in astNodes) {
      var value = astNode.accept(this, context) as T;
      if (value != null) {
        results.add(value);
      }
    }
    return results;
  }
}

class _TemplateContext {
  final Parser parser;
  final ElementSchemaRegistry schemaRegistry;
  final List<CompileDirectiveMetadata> directives;
  final List<CompileIdentifierMetadata> exports;

  _TemplateContext(
      {this.parser, this.schemaRegistry, this.directives, this.exports});
}

class _ParseContext {
  final _TemplateContext templateContext;
  final String elementName;
  final List<ng.DirectiveAst> boundDirectives;
  final bool _isTemplate;

  _ParseContext._(this.templateContext, this.elementName, this.boundDirectives,
      this._isTemplate);

  _ParseContext.forRoot(this.templateContext)
      : elementName = '',
        boundDirectives = const [],
        _isTemplate = false;

  factory _ParseContext.forElement(
      ast.ElementAst element, _TemplateContext templateContext) {
    var boundDirectives = _toAst(
        _matchElementDirectives(templateContext.directives, element),
        element.sourceSpan,
        element.name,
        _location(element),
        templateContext);
    return new _ParseContext._(
        templateContext, element.name, boundDirectives, false);
  }

  factory _ParseContext.forTemplate(
      ast.EmbeddedTemplateAst template, _TemplateContext templateContext) {
    var boundDirectives = _toAst(
        _matchTemplateDirectives(templateContext.directives, template),
        template.sourceSpan,
        TEMPLATE_ELEMENT,
        _location(template),
        templateContext);
    return new _ParseContext._(
        templateContext, TEMPLATE_ELEMENT, boundDirectives, true);
  }

  CompileTokenMetadata identifierForReference(String identifier) {
    for (var directive in boundDirectives) {
      if (identifier == null || identifier == directive.directive.exportAs) {
        return identifierToken(directive.directive.type);
      }
    }
    return _isTemplate ? identifierToken(Identifiers.TemplateRef) : null;
  }

  void bindLiteralToDirective(ast.AttributeAst astNode) => _bindToDirective(
      boundDirectives,
      astNode.name,
      templateContext.parser
          .wrapLiteralPrimitive(astNode.value, _location(astNode)),
      astNode.sourceSpan);

  bool bindPropertyToDirective(ast.PropertyAst astNode, ASTWithSource value) =>
      _bindToDirective(
          boundDirectives, astNode.name, value, astNode.sourceSpan);

  bool _bindToDirective(List<ng.DirectiveAst> directives, String name,
      ASTWithSource value, SourceSpan sourceSpan) {
    for (var directive in directives) {
      for (var directiveName in directive.directive.inputs.keys) {
        var templateName = directive.directive.inputs[directiveName];
        if (templateName == name) {
          directive.inputs.add(new ng.BoundDirectivePropertyAst(
              directiveName, templateName, value, sourceSpan));
          return true;
        }
      }
    }
    return false;
  }

  static List<ng.DirectiveAst> _toAst(
          Iterable<CompileDirectiveMetadata> directiveMetas,
          SourceSpan sourceSpan,
          String elementName,
          String location,
          _TemplateContext templateContext) =>
      directiveMetas
          .map((directive) => new ng.DirectiveAst(
              directive,
              [] /* inputs */,
              _bindProperties(directive, sourceSpan, elementName, location,
                  templateContext),
              _bindEvents(directive, sourceSpan, elementName, location,
                  templateContext),
              sourceSpan))
          .toList();

  static List<CompileDirectiveMetadata> _matchElementDirectives(
          List<CompileDirectiveMetadata> directives, ast.ElementAst astNode) =>
      _parseDirectives(directives, _elementSelector(astNode));

  static List<CompileDirectiveMetadata> _matchTemplateDirectives(
          List<CompileDirectiveMetadata> directives,
          ast.EmbeddedTemplateAst astNode) =>
      _parseDirectives(directives, _templateSelector(astNode));

  static List<CompileDirectiveMetadata> _parseDirectives(
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

  static SelectorMatcher _selectorMatcher(
      List<CompileDirectiveMetadata> directives) {
    final SelectorMatcher selectorMatcher = new SelectorMatcher();
    for (var directive in directives) {
      var selector = CssSelector.parse(directive.selector);
      selectorMatcher.addSelectables(selector, directive);
    }
    return selectorMatcher;
  }

  static List<ng.BoundElementPropertyAst> _bindProperties(
      CompileDirectiveMetadata directive,
      SourceSpan sourceSpan,
      String elementName,
      String location,
      _TemplateContext templateContext) {
    var result = [];
    for (var propName in directive.hostProperties.keys) {
      var expression = directive.hostProperties[propName];
      var exprAst = templateContext.parser
          .parseBinding(expression, location, templateContext.exports);
      result.add(createElementPropertyAst(elementName, propName, exprAst,
          sourceSpan, templateContext.schemaRegistry, (_, __, [___]) {}));
    }
    return result;
  }

  static List<ng.BoundEventAst> _bindEvents(
      CompileDirectiveMetadata directive,
      SourceSpan sourceSpan,
      String elementName,
      String location,
      _TemplateContext templateContext) {
    var result = [];
    for (var eventName in directive.hostListeners.keys) {
      var expression = directive.hostListeners[eventName];
      var value = templateContext.parser
          .parseAction(expression, location, templateContext.exports);
      result.add(new ng.BoundEventAst(eventName, value, sourceSpan));
    }
    return result;
  }
}

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

String _location(ast.TemplateAst astNode) =>
    astNode.isSynthetic ? '' : astNode.sourceSpan.start.toString();

/// Visitor which filters elements that are not supported in angular templates.
class _ElementFilter extends ast.IdentityTemplateAstVisitor<bool> {
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
}
