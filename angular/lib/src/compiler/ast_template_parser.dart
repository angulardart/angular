import 'package:source_span/source_span.dart';
import 'package:angular_ast/angular_ast.dart' as ast;
import 'package:angular_ast/src/expression/micro.dart';

import 'compile_metadata.dart';
import 'expression_parser/ast.dart';
import 'expression_parser/parser.dart';
import 'html_tags.dart';
import 'identifiers.dart';
import 'provider_parser.dart';
import 'schema/element_schema_registry.dart';
import 'selector.dart';
import 'style_url_resolver.dart';
import 'template_ast.dart' as ng;
import 'template_optimize.dart';
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
    final parsedAst = _parseTemplate(template);
    if (parsedAst.isEmpty) return const [];
    final implicNamespace = _applyImplicitNamespace(parsedAst);
    final desugaredAst = _inlineTemplates(implicNamespace);
    final filteredAst = _filterElements(desugaredAst);
    final boundAsts = _bindDirectives(directives, compMeta, filteredAst);
    final providedAsts = _bindProviders(compMeta, desugaredAst, boundAsts);
    _optimize(compMeta, providedAsts);
    _validatePipeNames(providedAsts, pipes);
    return providedAsts;
  }

  List<ast.TemplateAst> _parseTemplate(String template) {
    final parsedAst = ast.parse(template,
        // TODO(alorenzen): Use real sourceUrl.
        sourceUrl: '/test#inline',
        desugar: true,
        toolFriendlyAst: true,
        parseExpressions: false);
    return parsedAst;
  }

  List<ast.TemplateAst> _inlineTemplates(List<ast.TemplateAst> parsedAst) {
    var values = parsedAst
        .map((asNode) => asNode.accept(new _InlineTemplateDesugar()))
        .toList();
    return values;
  }

  List<ast.TemplateAst> _filterElements(List<ast.TemplateAst> parsedAst) =>
      new _ElementFilter().visitAll(parsedAst);

  List<ng.TemplateAst> _bindDirectives(
      List<CompileDirectiveMetadata> directives,
      CompileDirectiveMetadata compMeta,
      List<ast.TemplateAst> filteredAst) {
    final visitor = new _BindDirectivesVisitor();
    final context = new _ParseContext.forRoot(new _TemplateContext(
        parser: parser,
        schemaRegistry: schemaRegistry,
        directives: directives,
        exports: compMeta.exports));
    return filteredAst
        .map((templateAst) => templateAst.accept(visitor, context))
        .toList();
  }

  List<ng.TemplateAst> _bindProviders(CompileDirectiveMetadata compMeta,
      List<ast.TemplateAst> parsedAst, List<ng.TemplateAst> visitedAsts) {
    var providerViewContext =
        new ProviderViewContext(compMeta, parsedAst.first.sourceSpan);
    final providerVisitor = new _ProviderVisitor(providerViewContext);
    final ProviderElementContext providerContext = new ProviderElementContext(
        providerViewContext, null, false, [], [], [], null);
    return visitedAsts
        .map((templateAst) =>
            templateAst.visit(providerVisitor, providerContext))
        .toList();
  }

  void _optimize(CompileDirectiveMetadata compMeta, List<ng.TemplateAst> asts) {
    final optimizerVisitor = new OptimizeTemplateAstVisitor(compMeta);
    ng.templateVisitAll(optimizerVisitor, asts);
  }

  List<ast.TemplateAst> _applyImplicitNamespace(
          List<ast.TemplateAst> parsedAst) =>
      parsedAst
          .map((asNode) => asNode.accept(new _NamespaceVisitor()))
          .toList();

  void _validatePipeNames(
      List<ng.TemplateAst> parsedAsts, List<CompilePipeMetadata> pipes) {
    var pipeValidator = new _PipeValidator(pipes);
    for (final ast in parsedAsts) {
      ast.visit(pipeValidator, null);
    }
  }
}

/// A visitor which binds directives to element nodes.
///
/// This visitor also converts from the pkg:angular_ast types to the angular
/// compiler types.
class _BindDirectivesVisitor
    implements ast.TemplateAstVisitor<ng.TemplateAst, _ParseContext> {
  /// A count of how many <ng-content> elements have been seen so far.
  ///
  /// This is necessary so that we can assign a unique index to each one as we
  /// visit it.
  int ngContentCount = 0;

  @override
  ng.TemplateAst visitElement(ast.ElementAst astNode,
      [_ParseContext parentContext]) {
    final elementContext =
        new _ParseContext.forElement(astNode, parentContext.templateContext);
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
        _findNgContentIndexForElement(astNode, parentContext),
        astNode.sourceSpan);
  }

  int _findNgContentIndexForElement(
      ast.ElementAst astNode, _ParseContext context) {
    return context
        .findNgContentIndex(_projectAs(astNode) ?? _elementSelector(astNode));
  }

  _projectAs(ast.ElementAst astNode) {
    for (var attr in astNode.attributes) {
      if (attr.name == NG_PROJECT_AS) {
        return CssSelector.parse(attr.value)[0];
      }
    }
    return null;
  }

  @override
  ng.TemplateAst visitEmbeddedTemplate(ast.EmbeddedTemplateAst astNode,
      [_ParseContext parentContext]) {
    final embeddedContext =
        new _ParseContext.forTemplate(astNode, parentContext.templateContext);
    _visitAll(astNode.properties, embeddedContext);
    return new ng.EmbeddedTemplateAst(
        _visitAll(astNode.attributes, embeddedContext),
        _visitAll(astNode.events, embeddedContext),
        _visitAll(astNode.references, embeddedContext),
        _visitAll(astNode.letBindings, embeddedContext),
        embeddedContext.boundDirectives,
        [] /* providers */,
        null /* elementProviderUsage */,
        _visitAll(astNode.childNodes, embeddedContext),
        _findNgContentIndexForTemplate(astNode, parentContext),
        astNode.sourceSpan,
        hasDeferredComponent: astNode.hasDeferredComponent);
  }

  int _findNgContentIndexForTemplate(
      ast.EmbeddedTemplateAst astNode, _ParseContext context) {
    return context.findNgContentIndex(
        _templateProjectAs(astNode) ?? _templateSelector(astNode));
  }

  _templateProjectAs(ast.EmbeddedTemplateAst astNode) {
    for (var attr in astNode.attributes) {
      if (attr.name == NG_PROJECT_AS) {
        return CssSelector.parse(attr.value)[0];
      }
    }
    return null;
  }

  @override
  ng.TemplateAst visitEmbeddedContent(ast.EmbeddedContentAst astNode,
          [_ParseContext context]) =>
      new ng.NgContentAst(
          ngContentCount++,
          context.findNgContentIndex(CssSelector.parse(astNode.selector)[0]),
          astNode.sourceSpan);

  @override
  ng.TemplateAst visitEvent(ast.EventAst astNode, [_ParseContext context]) {
    var value = context.templateContext.parser.parseAction(
        astNode.value, _location(astNode), context.templateContext.exports);
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
    var value = context.templateContext.parser.parseBinding(
        astNode.value ?? 'null',
        _location(astNode),
        context.templateContext.exports);
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
  ng.TemplateAst visitText(ast.TextAst astNode, [_ParseContext context]) =>
      new ng.TextAst(astNode.value,
          context.findNgContentIndex(TEXT_CSS_SELECTOR), astNode.sourceSpan);

  @override
  ng.TemplateAst visitInterpolation(ast.InterpolationAst astNode,
      [_ParseContext context]) {
    var element = context.templateContext.parser.parseInterpolation(
        '{{${astNode.value}}}',
        _location(astNode),
        context.templateContext.exports);
    return new ng.BoundTextAst(element,
        context.findNgContentIndex(TEXT_CSS_SELECTOR), astNode.sourceSpan);
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

  @override
  ng.TemplateAst visitAnnotation(ast.AnnotationAst astNode,
      [_ParseContext context]) {
    throw new UnimplementedError('Don\'t know how to handle annotations.');
  }

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
  final SelectorMatcher _ngContentIndexMatcher;
  final int _wildcardNgContentIndex;

  _ParseContext._(
      this.templateContext,
      this.elementName,
      this.boundDirectives,
      this._isTemplate,
      this._ngContentIndexMatcher,
      this._wildcardNgContentIndex);

  _ParseContext.forRoot(this.templateContext)
      : elementName = '',
        boundDirectives = const [],
        _isTemplate = false,
        _ngContentIndexMatcher = null,
        _wildcardNgContentIndex = null;

  factory _ParseContext.forElement(
      ast.ElementAst element, _TemplateContext templateContext) {
    var boundDirectives = _toAst(
        _matchElementDirectives(templateContext.directives, element),
        element.sourceSpan,
        element.name,
        _location(element),
        templateContext);
    var firstComponent = _firstComponent(boundDirectives);
    return new _ParseContext._(
        templateContext,
        element.name,
        boundDirectives,
        false,
        _createSelector(firstComponent),
        _findWildcardIndex(firstComponent));
  }

  factory _ParseContext.forTemplate(
      ast.EmbeddedTemplateAst template, _TemplateContext templateContext) {
    var boundDirectives = _toAst(
        _matchTemplateDirectives(templateContext.directives, template),
        template.sourceSpan,
        TEMPLATE_ELEMENT,
        _location(template),
        templateContext);
    var firstComponent = _firstComponent(boundDirectives);
    return new _ParseContext._(
        templateContext,
        TEMPLATE_ELEMENT,
        boundDirectives,
        true,
        _createSelector(firstComponent),
        _findWildcardIndex(firstComponent));
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

  int findNgContentIndex(CssSelector selector) {
    if (_ngContentIndexMatcher == null) return _wildcardNgContentIndex;
    var ngContentIndices = [];
    _ngContentIndexMatcher.match(selector, (selector, ngContentIndex) {
      ngContentIndices.add(ngContentIndex);
    });
    ngContentIndices.sort();
    return ngContentIndices.isNotEmpty
        ? ngContentIndices.first
        : _wildcardNgContentIndex;
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

  static SelectorMatcher _createSelector(ng.DirectiveAst component) {
    if (component == null) return null;
    var matcher = new SelectorMatcher();
    var ngContextSelectors = component.directive.template.ngContentSelectors;
    for (var i = 0; i < ngContextSelectors.length; i++) {
      var selector = ngContextSelectors[i];
      if (selector != '*') {
        matcher.addSelectables(CssSelector.parse(selector), i);
      }
    }
    return matcher;
  }

  static int _findWildcardIndex(ng.DirectiveAst component) {
    if (component == null) return null;
    var ngContextSelectors = component.directive.template.ngContentSelectors;
    for (var i = 0; i < ngContextSelectors.length; i++) {
      if (ngContextSelectors[i] == '*') return i;
    }
    return null;
  }

  static ng.DirectiveAst _firstComponent(List<ng.DirectiveAst> directiveAsts) {
    var component = directiveAsts.firstWhere(
        (directive) => directive.directive.isComponent,
        orElse: () => null);
    return component;
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

/// Visitor which binds providers to element nodes.
///
/// These providers are provided by the bound directives on the element or by
/// parent elements.
class _ProviderVisitor
    implements ng.TemplateAstVisitor<ng.TemplateAst, ProviderElementContext> {
  final ProviderViewContext _rootContext;

  _ProviderVisitor(this._rootContext);

  @override
  ng.ElementAst visitElement(
      ng.ElementAst ast, ProviderElementContext context) {
    var elementContext = new ProviderElementContext(_rootContext, context,
        false, ast.directives, ast.attrs, ast.references, ast.sourceSpan);
    var children = <ng.TemplateAst>[];
    for (var child in ast.children) {
      children.add(child.visit(this, elementContext));
    }
    elementContext.afterElement();
    return new ng.ElementAst(
        ast.name,
        ast.attrs,
        ast.inputs,
        ast.outputs,
        ast.references,
        elementContext.transformedDirectiveAsts,
        elementContext.transformProviders,
        elementContext,
        children,
        ast.ngContentIndex,
        ast.sourceSpan);
  }

  @override
  ng.EmbeddedTemplateAst visitEmbeddedTemplate(
      ng.EmbeddedTemplateAst ast, ProviderElementContext context) {
    var elementContext = new ProviderElementContext(_rootContext, context, true,
        ast.directives, ast.attrs, ast.references, ast.sourceSpan);
    var children = <ng.TemplateAst>[];
    for (var child in ast.children) {
      children.add(child.visit(this, elementContext));
    }
    elementContext.afterElement();
    ast.providers.addAll(elementContext.transformProviders);
    return new ng.EmbeddedTemplateAst(
        ast.attrs,
        ast.outputs,
        ast.references,
        ast.variables,
        elementContext.transformedDirectiveAsts,
        elementContext.transformProviders,
        elementContext,
        children,
        ast.ngContentIndex,
        ast.sourceSpan,
        hasDeferredComponent: ast.hasDeferredComponent);
  }

  @override
  visitAttr(ng.AttrAst ast, ProviderElementContext context) => ast;

  @override
  visitBoundText(ng.BoundTextAst ast, ProviderElementContext context) => ast;

  @override
  visitDirective(ng.DirectiveAst ast, ProviderElementContext context) => ast;

  @override
  visitDirectiveProperty(
          ng.BoundDirectivePropertyAst ast, ProviderElementContext context) =>
      ast;

  @override
  visitElementProperty(
          ng.BoundElementPropertyAst ast, ProviderElementContext context) =>
      ast;

  @override
  visitEvent(ng.BoundEventAst ast, ProviderElementContext context) => ast;

  @override
  visitNgContent(ng.NgContentAst ast, ProviderElementContext context) => ast;

  @override
  visitReference(ng.ReferenceAst ast, ProviderElementContext context) => ast;

  @override
  visitText(ng.TextAst ast, ProviderElementContext context) => ast;

  @override
  visitVariable(ng.VariableAst ast, ProviderElementContext context) => ast;
}

/// Visitor which extracts inline templates.
// TODO(alorenzen): Refactor this into pkg:angular_ast.
class _InlineTemplateDesugar extends ast.IdentityTemplateAstVisitor<Null> {
  @override
  ast.TemplateAst visitElement(ast.ElementAst astNode,
      [_ParseContext context]) {
    var templateAttribute = _findTemplateAttribute(astNode);
    if (templateAttribute == null) {
      return astNode;
    }

    astNode.attributes.remove(templateAttribute);

    if (templateAttribute.value == null) {
      return new ast.EmbeddedTemplateAst.from(templateAttribute,
          childNodes: [astNode]);
    }

    var name = _getName(templateAttribute.value);
    var expression = _getExpression(templateAttribute.value);
    final properties = <ast.PropertyAst>[];
    final letBindings = <ast.LetBindingAst>[];
    if (isMicroExpression(expression)) {
      NgMicroAst micro;
      var expressionOffset = (templateAttribute as ast.ParsedAttributeAst)
          .valueToken
          ?.innerValue
          ?.offset;
      try {
        micro = parseMicroExpression(
          name,
          expression,
          expressionOffset,
          sourceUrl: astNode.sourceUrl,
          origin: templateAttribute,
        );
        if (micro != null) {
          properties.addAll(micro.properties);
          letBindings.addAll(micro.letBindings);
        }
        return new ast.EmbeddedTemplateAst.from(templateAttribute,
            properties: properties,
            letBindings: letBindings,
            attributes: name != null
                ? [new ast.AttributeAst.from(templateAttribute, name)]
                : [],
            childNodes: [astNode]);
      } catch (e) {
        rethrow;
        // TODO(alorenzen): Add support for exception handling.
        // exceptionHandler.handle(e);
        // return astNode;
      }
    } else {
      return new ast.EmbeddedTemplateAst.from(templateAttribute, properties: [
        new ast.PropertyAst.from(templateAttribute, name, expression)
      ], childNodes: [
        astNode
      ]);
    }
  }

  ast.AttributeAst _findTemplateAttribute(ast.ElementAst astNode) =>
      astNode.attributes
          .firstWhere((attr) => attr.name == 'template', orElse: () => null);

  String _getName(String value) {
    var spaceIndex = value.indexOf(' ');
    var name = value.substring(0, spaceIndex);
    if (name == 'let') return null;
    return name;
  }

  String _getExpression(String value) {
    var spaceIndex = value.indexOf(' ');
    if (value.substring(0, spaceIndex) == 'let') return value;
    return value.substring(spaceIndex + 1);
  }
}

/// Visitor that applies default namespaces to elements.
// TODO(alorenzen): Refactor this into pkg:angular_ast.
class _NamespaceVisitor extends ast.IdentityTemplateAstVisitor<String> {
  @override
  visitElement(ast.ElementAst element, [String parentPrefix]) {
    var prefix = _getNamespace(element.name) ?? parentPrefix;
    var children =
        element.childNodes.map((child) => child.accept(this, prefix)).toList();
    return new ast.ElementAst.from(
        element, mergeNsAndName(prefix, element.name), element.closeComplement,
        attributes: element.attributes,
        childNodes: children,
        events: element.events,
        properties: element.properties,
        references: element.references,
        bananas: element.bananas,
        stars: element.stars);
  }

  String _getNamespace(String name) =>
      getHtmlTagDefinition(name).implicitNamespacePrefix;
}

/// Visitor that verifies all pipes in the template are valid.
///
/// First, we visit all [AST] values to extract the pipe names declared in the
/// template, and then we verify that those names are actually defined by a
/// [CompilePipeMetadata] entry.
class _PipeValidator implements ng.TemplateAstVisitor<Null, Null> {
  final List<String> _pipeNames;

  _PipeValidator(List<CompilePipeMetadata> pipes)
      : _pipeNames = pipes.map((pipe) => pipe.name).toList();

  void _validatePipeNames(AST ast, SourceSpan sourceSpan) {
    if (ast == null) return;
    var collector = new PipeCollector();
    ast.visit(collector);
    for (String pipeName in collector.pipes) {
      if (!_pipeNames.contains(pipeName)) {
        // TODO(alorenzen): Replace this with proper error handling.
        throw new ArgumentError(
            "The pipe '$pipeName' could not be found. ${sourceSpan}");
      }
    }
  }

  @override
  visitBoundText(ng.BoundTextAst ast, _) {
    _validatePipeNames(ast.value, ast.sourceSpan);
  }

  @override
  visitDirectiveProperty(ng.BoundDirectivePropertyAst ast, _) {
    _validatePipeNames(ast.value, ast.sourceSpan);
  }

  @override
  visitElementProperty(ng.BoundElementPropertyAst ast, _) {
    _validatePipeNames(ast.value, ast.sourceSpan);
  }

  @override
  visitEvent(ng.BoundEventAst ast, _) {
    _validatePipeNames(ast.handler, ast.sourceSpan);
  }

  @override
  visitDirective(ng.DirectiveAst ast, _) {
    ng.templateVisitAll(this, ast.hostEvents);
    ng.templateVisitAll(this, ast.hostProperties);
    ng.templateVisitAll(this, ast.inputs);
  }

  @override
  visitElement(ng.ElementAst ast, _) {
    ng.templateVisitAll(this, ast.attrs);
    ng.templateVisitAll(this, ast.inputs);
    ng.templateVisitAll(this, ast.outputs);
    ng.templateVisitAll(this, ast.references);
    ng.templateVisitAll(this, ast.directives);
    ng.templateVisitAll(this, ast.providers);
    ng.templateVisitAll(this, ast.children);
  }

  @override
  visitEmbeddedTemplate(ng.EmbeddedTemplateAst ast, _) {
    ng.templateVisitAll(this, ast.attrs);
    ng.templateVisitAll(this, ast.variables);
    ng.templateVisitAll(this, ast.outputs);
    ng.templateVisitAll(this, ast.references);
    ng.templateVisitAll(this, ast.directives);
    ng.templateVisitAll(this, ast.providers);
    ng.templateVisitAll(this, ast.children);
  }

  @override
  visitAttr(ng.AttrAst ast, _) {}

  @override
  visitNgContent(ng.NgContentAst ast, _) {}

  @override
  visitReference(ng.ReferenceAst ast, _) {}

  @override
  visitText(ng.TextAst ast, _) {}

  @override
  visitVariable(ng.VariableAst ast, _) {}
}
