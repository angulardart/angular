import 'package:source_span/source_span.dart';
import 'package:angular/src/facade/exceptions.dart';
import 'package:angular_ast/angular_ast.dart' as ast;
import 'package:angular_ast/src/expression/micro.dart';

import 'chars.dart';
import 'compile_metadata.dart';
import 'expression_parser/ast.dart';
import 'expression_parser/parser.dart';
import 'html_tags.dart';
import 'identifiers.dart';
import 'parse_util.dart';
import 'provider_parser.dart';
import 'schema/element_schema_registry.dart';
import 'selector.dart';
import 'style_url_resolver.dart';
import 'template_ast.dart' as ng;
import 'template_optimize.dart';
import 'template_parser.dart';
import 'template_parser/recursive_template_visitor.dart';
import 'template_preparser.dart';

/// A [TemplateParser] which uses the `angular_ast` package to parse angular
/// templates.
class AstTemplateParser implements TemplateParser {
  @override
  final ElementSchemaRegistry schemaRegistry;

  final Parser parser;

  AstTemplateParser(this.schemaRegistry, this.parser);

  /// Parses the template into a structured tree of [ng.TemplateAst] nodes.
  ///
  /// This parsing is done in multiple phases:
  /// 1. Parse the raw template using `angular_ast` package.
  /// 2. Post-process the raw [ast.TemplateAst] nodes.
  /// 3. Bind any matching Directives and Providers, converting into
  ///    [ng.TemplateAst] nodes.
  /// 4. Post-process the bound [ng.TemplateAst] nodes.
  ///
  /// We will collect parse errors for each phase, and only continue to the next
  /// phase if no errors have occurred.
  @override
  List<ng.TemplateAst> parse(
      CompileDirectiveMetadata compMeta,
      String template,
      List<CompileDirectiveMetadata> directives,
      List<CompilePipeMetadata> pipes,
      String name) {
    final exceptionHandler = new _AstExceptionHandler(template, name);

    final parsedAst = _parseTemplate(template, name, exceptionHandler);
    exceptionHandler.maybeReportExceptions();
    if (parsedAst.isEmpty) return const [];

    final filteredAst = _processRawTemplateNodes(
      parsedAst,
      template: template,
      name: name,
      exceptionHandler: exceptionHandler,
      preserveWhitespace: compMeta.template.preserveWhitespace ?? false,
    );
    exceptionHandler.maybeReportExceptions();

    final providedAsts = _bindDirectivesAndProviders(directives, compMeta,
        filteredAst, exceptionHandler, parsedAst.first.sourceSpan);
    exceptionHandler.maybeReportExceptions();

    var processedAsts = _processBoundTemplateNodes(
        compMeta, providedAsts, pipes, exceptionHandler);
    exceptionHandler.maybeReportExceptions();

    return processedAsts;
  }

  List<ast.TemplateAst> _parseTemplate(String template, String name,
          _AstExceptionHandler exceptionHandler) =>
      ast.parse(template,
          sourceUrl: name,
          desugar: true,
          toolFriendlyAst: true,
          parseExpressions: false,
          exceptionHandler: exceptionHandler);

  List<ast.TemplateAst> _processRawTemplateNodes(
      Iterable<ast.TemplateAst> parsedAst,
      {String template,
      String name,
      _AstExceptionHandler exceptionHandler,
      bool preserveWhitespace: false}) {
    final implicNamespace = _applyImplicitNamespace(parsedAst);
    final desugaredAst = _inlineTemplates(implicNamespace, exceptionHandler);
    var filterElements = _filterElements(desugaredAst, preserveWhitespace);
    _validateTemplate(filterElements, exceptionHandler);
    return filterElements;
  }

  List<ng.TemplateAst> _bindDirectivesAndProviders(
      List<CompileDirectiveMetadata> directives,
      CompileDirectiveMetadata compMeta,
      List<ast.TemplateAst> filteredAst,
      _AstExceptionHandler exceptionHandler,
      SourceSpan span) {
    final boundAsts =
        _bindDirectives(directives, compMeta, filteredAst, exceptionHandler);
    return _bindProviders(compMeta, boundAsts, span, exceptionHandler);
  }

  List<ng.TemplateAst> _processBoundTemplateNodes(
      CompileDirectiveMetadata compMeta,
      List<ng.TemplateAst> providedAsts,
      List<CompilePipeMetadata> pipes,
      _AstExceptionHandler exceptionHandler) {
    final optimizedAsts = _optimize(compMeta, providedAsts);
    final sortedAsts = _sortInputs(optimizedAsts);
    _validatePipeNames(sortedAsts, pipes, exceptionHandler);
    return sortedAsts;
  }

  List<ast.TemplateAst> _inlineTemplates(List<ast.TemplateAst> parsedAst,
          ast.ExceptionHandler exceptionHandler) =>
      parsedAst
          .map((asNode) =>
              asNode.accept(new _InlineTemplateDesugar(exceptionHandler)))
          .toList();

  List<ast.TemplateAst> _filterElements(
      List<ast.TemplateAst> parsedAst, bool preserveWhitespace) {
    var filteredElements = new _ElementFilter().visitAll(parsedAst, false);
    return new _PreserveWhitespaceVisitor()
        .visitAll(filteredElements, preserveWhitespace);
  }

  List<ng.TemplateAst> _bindDirectives(
      List<CompileDirectiveMetadata> directives,
      CompileDirectiveMetadata compMeta,
      List<ast.TemplateAst> filteredAst,
      _AstExceptionHandler exceptionHandler) {
    final visitor = new _BindDirectivesVisitor();
    final context = new _ParseContext.forRoot(new _TemplateContext(
        parser: parser,
        schemaRegistry: schemaRegistry,
        directives: removeDuplicates(directives),
        exports: compMeta.exports,
        exceptionHandler: exceptionHandler));
    return visitor._visitAll(filteredAst, context);
  }

  List<ng.TemplateAst> _bindProviders(
      CompileDirectiveMetadata compMeta,
      List<ng.TemplateAst> visitedAsts,
      SourceSpan sourceSpan,
      _AstExceptionHandler exceptionHandler) {
    var providerViewContext = new ProviderViewContext(compMeta, sourceSpan);
    final providerVisitor = new _ProviderVisitor(providerViewContext);
    final ProviderElementContext providerContext = new ProviderElementContext(
        providerViewContext, null, false, [], [], [], null);
    final providedAsts = providerVisitor.visitAll(visitedAsts, providerContext);
    exceptionHandler.handleAll(providerViewContext.errors);
    return providedAsts;
  }

  List<ng.TemplateAst> _optimize(
          CompileDirectiveMetadata compMeta, List<ng.TemplateAst> asts) =>
      new OptimizeTemplateAstVisitor(compMeta).visitAll(asts);

  List<ng.TemplateAst> _sortInputs(List<ng.TemplateAst> asts) =>
      new _SortInputsVisitor().visitAll(asts);

  List<ast.TemplateAst> _applyImplicitNamespace(
          List<ast.TemplateAst> parsedAst) =>
      parsedAst
          .map((asNode) => asNode.accept(new _NamespaceVisitor()))
          .toList();

  void _validatePipeNames(List<ng.TemplateAst> parsedAsts,
      List<CompilePipeMetadata> pipes, _AstExceptionHandler exceptionHandler) {
    var pipeValidator =
        new _PipeValidator(removeDuplicates(pipes), exceptionHandler);
    for (final ast in parsedAsts) {
      ast.visit(pipeValidator, null);
    }
  }

  void _validateTemplate(
      List<ast.TemplateAst> parsedAst, _AstExceptionHandler exceptionHandler) {
    for (final ast in parsedAst) {
      ast.accept(new _TemplateValidator(exceptionHandler));
    }
  }
}

class _AstExceptionHandler extends ast.RecoveringExceptionHandler {
  final String template;
  final String sourceUrl;

  final parseErrors = <ParseError>[];

  _AstExceptionHandler(this.template, this.sourceUrl);

  void handleParseError(ParseError error) {
    parseErrors.add(error);
  }

  void handleAll(Iterable<ParseError> errors) {
    parseErrors.addAll(errors);
  }

  void maybeReportExceptions() {
    if (exceptions.isNotEmpty) {
      // We always throw here, so no need to clear the list.
      _reportExceptions();
    }
    if (parseErrors.isNotEmpty) {
      // TODO(alorenzen): Once this is no longer used for the legacy parser,
      // rename to reportParseErrors.
      handleParseErrors(parseErrors);
      // handleParseErrors() may only log warnings and not throw, so we need to
      // clear the list before the next phase.
      parseErrors.clear();
    }
  }

  void _reportExceptions() {
    final sourceFile = new SourceFile.fromString(template, url: sourceUrl);
    final errorString = exceptions
        .map((exception) => sourceFile
            .span(exception.offset, exception.offset + exception.length)
            .message(exception.errorCode.message))
        .join('\n');
    throw new BaseException('Template parse errors:\n$errorString');
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

    // Note: We rely on the fact that attributes are visited before properties
    // in order to ensure that properties take precedence over attributes with
    // the same name.
    return new ng.ElementAst(
        astNode.name,
        _visitAll(astNode.attributes, elementContext),
        _visitProperties(
            astNode.properties, astNode.attributes, elementContext),
        _visitAll(astNode.events, elementContext),
        _visitAll(astNode.references, elementContext),
        elementContext.boundDirectives,
        [] /* providers */,
        null /* elementProviderUsage */,
        _visitAll(astNode.childNodes, elementContext),
        _findNgContentIndexForElement(astNode, parentContext),
        astNode.sourceSpan);
  }

  List<ng.BoundElementPropertyAst> _visitProperties(
      List<ast.PropertyAst> properties,
      List<ast.AttributeAst> attributes,
      _ParseContext elementContext) {
    var visitedProperties = _visitAll(properties, elementContext);
    for (var attribute in attributes) {
      if (attribute.mustaches?.isNotEmpty ?? false) {
        var boundElementPropertyAst =
            _createPropertyForAttribute(attribute, elementContext);
        if (boundElementPropertyAst != null) {
          visitedProperties.add(boundElementPropertyAst);
        }
      }
    }
    return visitedProperties;
  }

  ng.BoundElementPropertyAst _createPropertyForAttribute(
      ast.AttributeAst attribute, _ParseContext elementContext) {
    try {
      var parsedInterpolation = elementContext.templateContext.parser
          .parseInterpolation(attribute.value, _location(attribute),
              elementContext.templateContext.exports);
      if (elementContext.bindInterpolationToDirective(
          attribute, parsedInterpolation)) {
        return null;
      }
      return createElementPropertyAst(
          elementContext.elementName,
          attribute.name,
          parsedInterpolation,
          attribute.sourceSpan,
          elementContext.templateContext.schemaRegistry,
          elementContext.templateContext.reportError);
    } on ParseException catch (e) {
      elementContext.templateContext
          .reportError(e.message, attribute.sourceSpan);
      return null;
    }
  }

  int _findNgContentIndexForElement(
      ast.ElementAst astNode, _ParseContext context) {
    return context.findNgContentIndex(_elementSelector(astNode));
  }

  @override
  ng.TemplateAst visitEmbeddedTemplate(ast.EmbeddedTemplateAst astNode,
      [_ParseContext parentContext]) {
    final embeddedContext =
        new _ParseContext.forTemplate(astNode, parentContext.templateContext);
    _visitProperties(astNode.properties, astNode.attributes, embeddedContext);
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
    if (_isInlineTemplate(astNode)) {
      return _findNgContentIndexForElement(
          astNode.childNodes
              .firstWhere((childNode) => childNode is ast.ElementAst),
          context);
    }
    return context.findNgContentIndex(_templateSelector(astNode));
  }

  bool _isInlineTemplate(ast.EmbeddedTemplateAst astNode) {
    if (astNode is! ast.SyntheticTemplateAst) return false;
    final syntheticNode = astNode as ast.SyntheticTemplateAst;
    if (syntheticNode.origin is ast.EmbeddedTemplateAst) {
      return _isInlineTemplate(syntheticNode.origin);
    }
    if (syntheticNode.origin is ast.StarAst ||
        syntheticNode.origin is ast.AttributeAst) return true;
    return false;
  }

  @override
  ng.TemplateAst visitEmbeddedContent(ast.EmbeddedContentAst astNode,
          [_ParseContext context]) =>
      new ng.NgContentAst(
          ngContentCount++,
          _findNgContentIndexForEmbeddedContent(context, astNode),
          astNode.sourceSpan);

  int _findNgContentIndexForEmbeddedContent(
          _ParseContext context, ast.EmbeddedContentAst astNode) =>
      context.findNgContentIndex(_embeddedContentSelector(astNode));

  CssSelector _embeddedContentSelector(ast.EmbeddedContentAst astNode) =>
      astNode.ngProjectAs != null
          ? CssSelector.parse(astNode.ngProjectAs)[0]
          : createElementCssSelector(NG_CONTENT_ELEMENT, [
              [NG_CONTENT_SELECT_ATTR, astNode.selector]
            ]);

  @override
  ng.TemplateAst visitEvent(ast.EventAst astNode, [_ParseContext context]) {
    try {
      var value = context.templateContext.parser.parseAction(
          astNode.value, _location(astNode), context.templateContext.exports);
      return new ng.BoundEventAst(
          _getEventName(astNode), value, astNode.sourceSpan);
    } on ParseException catch (e) {
      context.templateContext.reportError(e.message, astNode.sourceSpan);
      return null;
    }
  }

  @override
  ng.TemplateAst visitAttribute(ast.AttributeAst astNode,
      [_ParseContext context]) {
    // If there is interpolation, then we will handle this node elsewhere.
    if (astNode.mustaches?.isNotEmpty ?? false) return null;
    context.bindLiteralToDirective(astNode);
    return new ng.AttrAst(
        astNode.name, astNode.value ?? '', astNode.sourceSpan);
  }

  @override
  ng.TemplateAst visitProperty(ast.PropertyAst astNode,
      [_ParseContext context]) {
    try {
      var value = context.templateContext.parser.parseBinding(
          astNode.value ?? 'null',
          _location(astNode),
          context.templateContext.exports);
      // If we bind the property to a directive input, or the element is a
      // template element, then we don't want to bind the property to the element.
      if (context.bindPropertyToDirective(astNode, value) ||
          context.isTemplate) {
        return null;
      }
      return createElementPropertyAst(
          context.elementName,
          _getPropertyName(astNode),
          value,
          astNode.sourceSpan,
          context.templateContext.schemaRegistry,
          context.templateContext.reportError);
    } on ParseException catch (e) {
      context.templateContext.reportError(e.message, astNode.sourceSpan);
      return null;
    }
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
    try {
      var element = context.templateContext.parser.parseInterpolation(
          '{{${astNode.value}}}',
          _location(astNode),
          context.templateContext.exports);
      return new ng.BoundTextAst(element,
          context.findNgContentIndex(TEXT_CSS_SELECTOR), astNode.sourceSpan);
    } on ParseException catch (e) {
      context.templateContext.reportError(e.message, astNode.sourceSpan);
      return null;
    }
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
      null;

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
  final _AstExceptionHandler exceptionHandler;

  _TemplateContext(
      {this.parser,
      this.schemaRegistry,
      this.directives,
      this.exports,
      this.exceptionHandler});

  void reportError(String message, SourceSpan sourceSpan,
      [ParseErrorLevel level]) {
    level ??= ParseErrorLevel.FATAL;
    exceptionHandler
        .handleParseError(new TemplateParseError(message, sourceSpan, level));
  }
}

class _ParseContext {
  final _TemplateContext templateContext;
  final String elementName;
  final List<ng.DirectiveAst> boundDirectives;
  final bool isTemplate;
  final SelectorMatcher _ngContentIndexMatcher;
  final int _wildcardNgContentIndex;

  _ParseContext._(
      this.templateContext,
      this.elementName,
      this.boundDirectives,
      this.isTemplate,
      this._ngContentIndexMatcher,
      this._wildcardNgContentIndex);

  _ParseContext.forRoot(this.templateContext)
      : elementName = '',
        boundDirectives = const [],
        isTemplate = false,
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
      if ((identifier == null && directive.directive.isComponent) ||
          identifier != null && identifier == directive.directive.exportAs) {
        return identifierToken(directive.directive.type);
      }
    }
    return isTemplate ? identifierToken(Identifiers.TemplateRef) : null;
  }

  void bindLiteralToDirective(ast.AttributeAst astNode) => _bindToDirective(
      boundDirectives,
      astNode.name,
      astNode.value == null
          ? new EmptyExpr()
          : templateContext.parser
              .wrapLiteralPrimitive(astNode.value, _location(astNode)),
      astNode.sourceSpan);

  bool bindPropertyToDirective(ast.PropertyAst astNode, AST value) =>
      _bindToDirective(boundDirectives, _getPropertyName(astNode), value,
          astNode.sourceSpan);

  bool bindInterpolationToDirective(ast.AttributeAst astNode, AST value) =>
      _bindToDirective(
          boundDirectives, astNode.name, value, astNode.sourceSpan);

  bool _bindToDirective(List<ng.DirectiveAst> directives, String name,
      AST value, SourceSpan sourceSpan) {
    bool foundMatch = false;
    directive:
    for (var directive in directives) {
      for (var directiveName in directive.directive.inputs.keys) {
        var templateName = directive.directive.inputs[directiveName];
        if (templateName == name) {
          _removeExisting(directive.inputs, templateName);
          directive.inputs.add(new ng.BoundDirectivePropertyAst(
              directiveName, templateName, value, sourceSpan));
          foundMatch = true;
          continue directive;
        }
      }
    }
    return foundMatch;
  }

  void _removeExisting(
      List<ng.BoundDirectivePropertyAst> inputs, String templateName) {
    var input = inputs.firstWhere((input) => input.templateName == templateName,
        orElse: () => null);
    if (input != null) {
      inputs.remove(input);
    }
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
      try {
        var expression = directive.hostProperties[propName];
        var exprAst = templateContext.parser
            .parseBinding(expression, location, templateContext.exports);
        result.add(createElementPropertyAst(
            elementName,
            propName,
            exprAst,
            sourceSpan,
            templateContext.schemaRegistry,
            templateContext.reportError));
      } on ParseException catch (e) {
        templateContext.reportError(e.message, sourceSpan);
        continue;
      }
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
      try {
        var expression = directive.hostListeners[eventName];
        var value = templateContext.parser
            .parseAction(expression, location, templateContext.exports);
        result.add(new ng.BoundEventAst(eventName, value, sourceSpan));
      } on ParseException catch (e) {
        templateContext.reportError(e.message, sourceSpan);
        continue;
      }
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
    matchableAttributes.add([_getPropertyName(property), property.value]);
  }
  for (var event in events) {
    matchableAttributes.add([_getEventName(event), event.value]);
  }
  return createElementCssSelector(elementName, matchableAttributes);
}

String _location(ast.TemplateAst astNode) =>
    astNode.isSynthetic ? '' : astNode.sourceSpan.start.toString();

String _getPropertyName(ast.PropertyAst astNode) {
  if (astNode.unit != null) {
    return '${astNode.name}.${astNode.postfix}.${astNode.unit}';
  }
  if (astNode.postfix != null) {
    return '${astNode.name}.${astNode.postfix}';
  }
  return astNode.name;
}

String _getEventName(ast.EventAst event) =>
    ([event.name]..addAll(event.reductions)).join('.');

/// Visitor which filters elements that are not supported in angular templates.
class _ElementFilter extends ast.RecursiveTemplateAstVisitor<bool> {
  @override
  ast.TemplateAst visitElement(ast.ElementAst astNode,
      [bool hasNgNonBindable]) {
    if (_filterElement(astNode, hasNgNonBindable)) {
      return null;
    }
    return super.visitElement(
        astNode, hasNgNonBindable || _hasNgNonBindable(astNode.attributes));
  }

  @override
  ast.TemplateAst visitEmbeddedTemplate(ast.EmbeddedTemplateAst astNode,
          [bool hasNgNonBindable]) =>
      super.visitEmbeddedTemplate(
          astNode, hasNgNonBindable || _hasNgNonBindable(astNode.attributes));

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
          : super.visitInterpolation(astNode, hasNgNonBindable);

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

  bool _hasNgNonBindable(List<ast.AttributeAst> attributes) {
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
    extends RecursiveTemplateVisitor<ProviderElementContext> {
  final ProviderViewContext _rootContext;

  _ProviderVisitor(this._rootContext);

  @override
  // We intentionally don't call super.visitElement() so that we can control
  // exactly when the children are visited.
  // ignore: MUST_CALL_SUPER
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
  // We intentionally don't call super.visitElement() so that we can control
  // exactly when the children are visited.
  // ignore: MUST_CALL_SUPER
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
}

/// Visitor which extracts inline templates.
// TODO(alorenzen): Refactor this into pkg:angular_ast.
class _InlineTemplateDesugar extends ast.RecursiveTemplateAstVisitor<Null> {
  final ast.ExceptionHandler exceptionHandler;

  _InlineTemplateDesugar(this.exceptionHandler);

  @override
  ast.TemplateAst visitElement(ast.ElementAst astNode, [_]) {
    astNode = super.visitElement(astNode);
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
      var expressionOffset = _expressionOffset(templateAttribute);
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
      } on ast.AngularParserException catch (e) {
        exceptionHandler.handle(e);
        return null;
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
    var name = spaceIndex == -1 ? value : value.substring(0, spaceIndex);
    if (name == 'let') return null;
    return name.replaceAll(':', '');
  }

  String _getExpression(String value) {
    var spaceIndex = value.indexOf(' ');
    if (spaceIndex == -1) return null;
    if (value.substring(0, spaceIndex) == 'let') return value;
    return value.substring(spaceIndex + 1);
  }

  int _expressionOffset(ast.AttributeAst templateAttribute) {
    if (templateAttribute == null) return null;
    if (templateAttribute is ast.SyntheticTemplateAst) {
      return _expressionOffset(
          (templateAttribute as ast.SyntheticTemplateAst).origin);
    }
    return (templateAttribute as ast.ParsedAttributeAst)
        .valueToken
        ?.innerValue
        ?.offset;
  }
}

/// Visitor that applies default namespaces to elements.
// TODO(alorenzen): Refactor this into pkg:angular_ast.
class _NamespaceVisitor extends ast.RecursiveTemplateAstVisitor<String> {
  @override
  visitElement(ast.ElementAst element, [String parentPrefix]) {
    var prefix = _getNamespace(element.name) ?? parentPrefix;
    var visitedElement = super.visitElement(element, prefix) as ast.ElementAst;
    return new ast.ElementAst.from(
        visitedElement,
        mergeNsAndName(prefix, _getName(visitedElement.name)),
        visitedElement.closeComplement,
        attributes: visitedElement.attributes,
        childNodes: visitedElement.childNodes,
        events: visitedElement.events,
        properties: visitedElement.properties,
        references: visitedElement.references,
        bananas: visitedElement.bananas,
        stars: visitedElement.stars);
  }

  String _getNamespace(String name) {
    return _getNsPrefix(name) ??
        getHtmlTagDefinition(name).implicitNamespacePrefix;
  }

  @override
  visitAttribute(ast.AttributeAst astNode, [String parentPrefix]) {
    astNode = super.visitAttribute(astNode, parentPrefix);
    if (_getNsPrefix(astNode.name) == null) return astNode;
    var names = astNode.name.split(':');
    return new ast.AttributeAst.from(astNode,
        mergeNsAndName(names[0], names[1]), astNode.value, astNode.mustaches);
  }

  String _getNsPrefix(String name) {
    var separatorIndex = name.indexOf(':');
    if (separatorIndex == -1) return null;
    return name.substring(0, separatorIndex);
  }

  String _getName(String name) {
    var separatorIndex = name.indexOf(':');
    if (separatorIndex == -1) return name;
    return name.substring(separatorIndex + 1);
  }
}

class _TemplateValidator extends ast.RecursiveTemplateAstVisitor<Null> {
  final _AstExceptionHandler exceptionHandler;

  _TemplateValidator(this.exceptionHandler);

  @override
  ast.TemplateAst visitElement(ast.ElementAst astNode, [_]) {
    _findDuplicateAttributes(astNode.attributes);
    _findDuplicateProperties(astNode.properties);
    _findDuplicateEvents(astNode.events);
    return super.visitElement(astNode);
  }

  @override
  ast.TemplateAst visitEmbeddedTemplate(ast.EmbeddedTemplateAst astNode, [_]) {
    _findDuplicateAttributes(astNode.attributes);
    _findDuplicateProperties(astNode.properties);
    _findDuplicateEvents(astNode.events);
    return super.visitEmbeddedTemplate(astNode);
  }

  @override
  ast.TemplateAst visitAttribute(ast.AttributeAst astNode, [_]) {
    // warnings
    if (astNode.name.startsWith('bindon-')) {
      _reportError(
          astNode,
          '"bindon-" for properties/events is no longer supported. Use "[()]" '
          'instead!',
          ParseErrorLevel.WARNING);
    }
    if (astNode.name.startsWith('ref-')) {
      _reportError(
          astNode,
          '"ref-" for references is no longer supported. Use "#" instead!',
          ParseErrorLevel.WARNING);
    }
    if (astNode.name.startsWith('var-')) {
      _reportError(
          astNode,
          '"var-" for references is no longer supported. Use "#" instead!',
          ParseErrorLevel.WARNING);
    }
    return super.visitAttribute(astNode);
  }

  @override
  ast.TemplateAst visitEvent(ast.EventAst astNode, [_]) {
    if (_getEventName(astNode).contains(':')) {
      _reportError(astNode,
          '":" is not allowed in event names: ${_getEventName(astNode)}');
    }
    return super.visitEvent(astNode);
  }

  @override
  ast.TemplateAst visitReference(ast.ReferenceAst astNode, [_]) {
    if (astNode.variable.contains('-')) {
      _reportError(astNode, '"-" is not allowed in reference names');
    }
    return super.visitReference(astNode);
  }

  @override
  ast.TemplateAst visitProperty(ast.PropertyAst astNode, [_]) {
    if (astNode.value?.startsWith('#') ?? false) {
      _reportError(astNode,
          '"#" inside of expressions is no longer supported. Use "let" instead!');
    }
    if (astNode.value?.startsWith('var ') ?? false) {
      _reportError(astNode,
          '"var" inside of expressions is no longer supported. Use "let" instead!');
    }
    return super.visitProperty(astNode);
  }

  void _findDuplicateAttributes(List<ast.AttributeAst> attributes) {
    final seenAttributes = new Set<String>();
    for (final attribute in attributes) {
      if (seenAttributes.contains(attribute.name)) {
        _reportError(attribute,
            'Found multiple attributes with the same name: ${attribute.name}.');
      } else {
        seenAttributes.add(attribute.name);
      }
    }
  }

  void _findDuplicateProperties(List<ast.PropertyAst> properties) {
    final seenProperties = new Set<String>();
    for (final property in properties) {
      final propertyName = _getPropertyName(property);
      if (seenProperties.contains(propertyName)) {
        _reportError(property,
            'Found multiple properties with the same name: $propertyName.');
      } else {
        seenProperties.add(propertyName);
      }
    }
  }

  void _findDuplicateEvents(List<ast.EventAst> events) {
    final seenEvents = new Set<String>();
    for (final event in events) {
      final eventName = _getEventName(event);
      if (seenEvents.contains(eventName)) {
        _reportError(
            event,
            'Found multiple events with the same name: $eventName. You should '
            'merge the handlers into a single statement.');
      } else {
        seenEvents.add(eventName);
      }
    }
  }

  void _reportError(ast.TemplateAst astNode, String message,
      [ParseErrorLevel level = ParseErrorLevel.FATAL]) {
    exceptionHandler.handleParseError(
        new TemplateParseError(message, astNode.sourceSpan, level));
  }
}

/// Visitor that verifies all pipes in the template are valid.
///
/// First, we visit all [AST] values to extract the pipe names declared in the
/// template, and then we verify that those names are actually defined by a
/// [CompilePipeMetadata] entry.
class _PipeValidator extends RecursiveTemplateVisitor<Null> {
  final List<String> _pipeNames;
  final _AstExceptionHandler _exceptionHandler;

  _PipeValidator(List<CompilePipeMetadata> pipes, this._exceptionHandler)
      : _pipeNames = pipes.map((pipe) => pipe.name).toList();

  void _validatePipeNames(AST ast, SourceSpan sourceSpan) {
    if (ast == null) return;
    var collector = new PipeCollector();
    ast.visit(collector);
    for (String pipeName in collector.pipes) {
      if (!_pipeNames.contains(pipeName)) {
        _exceptionHandler.handleParseError(new TemplateParseError(
            "The pipe '$pipeName' could not be found.",
            sourceSpan,
            ParseErrorLevel.FATAL));
      }
    }
  }

  @override
  ng.TemplateAst visitBoundText(ng.BoundTextAst ast, _) {
    _validatePipeNames(ast.value, ast.sourceSpan);
    return super.visitBoundText(ast, null);
  }

  @override
  ng.TemplateAst visitDirectiveProperty(ng.BoundDirectivePropertyAst ast, _) {
    _validatePipeNames(ast.value, ast.sourceSpan);
    return super.visitDirectiveProperty(ast, null);
  }

  @override
  ng.TemplateAst visitElementProperty(ng.BoundElementPropertyAst ast, _) {
    _validatePipeNames(ast.value, ast.sourceSpan);
    return super.visitElementProperty(ast, null);
  }

  @override
  ng.TemplateAst visitEvent(ng.BoundEventAst ast, _) {
    _validatePipeNames(ast.handler, ast.sourceSpan);
    return super.visitEvent(ast, null);
  }
}

class _PreserveWhitespaceVisitor extends ast.IdentityTemplateAstVisitor<bool> {
  List<T> visitAll<T extends ast.TemplateAst>(
      List<T> astNodes, bool preserveWhitespace) {
    final result = <T>[];
    for (int i = 0; i < astNodes.length; i++) {
      var node = astNodes[i];
      final visited = node is ast.TextAst
          ? _stripWhitespace(i, node, astNodes, preserveWhitespace)
          : node.accept(this, preserveWhitespace);
      if (visited != null) result.add(visited);
    }
    return result;
  }

  @override
  visitElement(ast.ElementAst astNode, [bool preserveWhitespace]) {
    var children = visitAll(astNode.childNodes, preserveWhitespace);
    astNode.childNodes.clear();
    astNode.childNodes.addAll(children);
    return astNode;
  }

  @override
  visitEmbeddedTemplate(ast.EmbeddedTemplateAst astNode,
      [bool preserveWhitespace]) {
    var children = visitAll(astNode.childNodes, preserveWhitespace);
    astNode.childNodes.clear();
    astNode.childNodes.addAll(children);
    return astNode;
  }

  ast.TextAst _stripWhitespace(int i, ast.TextAst node,
      List<ast.TemplateAst> astNodes, bool preserveWhitespace) {
    var text = node.value;

    if (preserveWhitespace ||
        text.contains('\u00A0') ||
        text.contains(ngSpace) ||
        _betweenInterpolation(astNodes, i)) {
      return new ast.TextAst.from(node, replaceNgSpace(text));
    }

    if (_hasInterpolation(astNodes, i)) {
      if (text.contains('\n')) {
        if (!_hasInterpolationBefore(astNodes, i)) text = text.trimLeft();
        if (!_hasInterpolationAfter(astNodes, i)) text = text.trimRight();
      }
    } else {
      text = text.trim();
    }

    if (text.isEmpty) return null;

    // Convert &ngsp to actual space.
    text = replaceNgSpace(text);
    return new ast.TextAst.from(node, text);
  }

  bool _hasInterpolation(List<ast.TemplateAst> astNodes, int i) =>
      _hasInterpolationBefore(astNodes, i) ||
      _hasInterpolationAfter(astNodes, i);

  bool _betweenInterpolation(List<ast.TemplateAst> astNodes, int i) =>
      _hasInterpolationBefore(astNodes, i) &&
      _hasInterpolationAfter(astNodes, i);

  bool _hasInterpolationBefore(List<ast.TemplateAst> astNodes, int i) {
    if (i == 0) return false;
    return astNodes[i - 1] is ast.InterpolationAst;
  }

  bool _hasInterpolationAfter(List<ast.TemplateAst> astNodes, int i) {
    if (i == (astNodes.length - 1)) return false;
    return astNodes[i + 1] is ast.InterpolationAst;
  }
}

class _SortInputsVisitor extends RecursiveTemplateVisitor<Null> {
  @override
  ng.DirectiveAst visitDirective(ng.DirectiveAst ast, _) {
    ast.inputs.sort(_orderingOf(ast.directive.inputs));
    return super.visitDirective(ast, null);
  }

  Comparator<ng.BoundDirectivePropertyAst> _orderingOf(
      Map<String, String> inputs) {
    final keys = inputs.keys.toList(growable: false);
    int _indexOf(ng.BoundDirectivePropertyAst input) {
      return keys.indexOf(input.directiveName);
    }

    return (ng.BoundDirectivePropertyAst a, ng.BoundDirectivePropertyAst b) =>
        Comparable.compare(_indexOf(a), _indexOf(b));
  }
}
