import 'package:source_span/source_span.dart';
import 'package:angular/src/core/linker/app_view_utils.dart'
    show MAX_INTERPOLATION_VALUES;
import 'package:angular/src/facade/exceptions.dart' show BaseException;
import 'package:angular/src/facade/lang.dart' show jsSplit;

import '../core/security.dart';
import 'chars.dart';
import 'compile_metadata.dart'
    show
        CompileDirectiveMetadata,
        CompileIdentifierMetadata,
        CompilePipeMetadata;
import 'expression_parser/ast.dart'
    show
        AST,
        Interpolation,
        ASTWithSource,
        TemplateBinding,
        RecursiveAstVisitor,
        BindingPipe;
import 'expression_parser/ast.dart';
import 'expression_parser/parser.dart' show Parser;
import 'html_ast.dart';
import 'html_parser.dart' show HtmlParser;
import 'html_tags.dart' show splitNsName, mergeNsAndName;
import 'identifiers.dart' show identifierToken, Identifiers;
import 'logging.dart' show logger;
import 'parse_util.dart' show ParseError, ParseErrorLevel;
import 'provider_parser.dart' show ProviderElementContext, ProviderViewContext;
import 'schema/element_schema_registry.dart' show ElementSchemaRegistry;
import 'selector.dart' show CssSelector, SelectorMatcher;
import 'style_url_resolver.dart' show isStyleUrlResolvable;
import 'template_ast.dart'
    show
        ElementAst,
        BoundElementPropertyAst,
        BoundEventAst,
        ReferenceAst,
        TemplateAst,
        TextAst,
        BoundTextAst,
        EmbeddedTemplateAst,
        AttrAst,
        NgContentAst,
        PropertyBindingType,
        DirectiveAst,
        BoundDirectivePropertyAst,
        VariableAst;
import 'template_preparser.dart' show preparseElement;

// Group 1 = 'bind-'
// Group 2 = 'var-'
// Group 3 = 'let-'
// Group 4 = 'ref-/#'
// Group 5 = 'on-'
// Group 6 = 'bindon-'
// Group 7 = the identifier after 'bind-', 'var-/#', or 'on-'
// Group 8 = identifier inside [()]
// Group 9 = identifier inside []
// Group 10 = identifier inside ()
final BIND_NAME_REGEXP =
    new RegExp(r'^(?:(?:(?:(bind-)|(var-)|(let-)|(ref-|#)|(on-)|(bindon-))(.+))'
        r'|\[\(([^\)]+)\)\]|\[([^\]]+)\]|\(([^\)]+)\))$');
const TEMPLATE_ELEMENT = 'template';
const TEMPLATE_ATTR = 'template';
const TEMPLATE_ATTR_PREFIX = '*';
const TEMPLATE_DEFERRED_ATTR = '@deferred';
const CLASS_ATTR = 'class';
final PROPERTY_PARTS_SEPARATOR = '.';
const ATTRIBUTE_PREFIX = 'attr';
const CLASS_PREFIX = 'class';
const STYLE_PREFIX = 'style';
final CssSelector TEXT_CSS_SELECTOR = CssSelector.parse('*')[0];

class TemplateParseError extends ParseError {
  TemplateParseError(String message, SourceSpan span, ParseErrorLevel level)
      : super(span, message, level);
}

class TemplateParseResult {
  List<TemplateAst> templateAst;
  List<ParseError> errors;
  TemplateParseResult([this.templateAst, this.errors]);
}

/// Converts Html AST to TemplateAST nodes.
class TemplateParser {
  final Parser _exprParser;
  final ElementSchemaRegistry schemaRegistry;
  final HtmlParser _htmlParser;

  TemplateParser(this._exprParser, this.schemaRegistry, this._htmlParser);

  /// Parses template and checks for warnings and errors.
  ///
  /// Warnings are logged, errors will throw BaseException.
  List<TemplateAst> parse(
      CompileDirectiveMetadata component,
      String template,
      List<CompileDirectiveMetadata> directives,
      List<CompilePipeMetadata> pipes,
      String templateUrl) {
    var result = tryParse(component, template, directives, pipes, templateUrl);
    var warnings = <ParseError>[];
    var errors = <ParseError>[];
    for (ParseError error in result.errors) {
      if (error.level == ParseErrorLevel.WARNING) {
        warnings.add(error);
      } else if (error.level == ParseErrorLevel.FATAL) {
        errors.add(error);
      }
    }
    if (warnings.isNotEmpty) {
      logger.warning("Template parse warnings:\n${warnings.join('\n')}");
    }
    if (errors.isNotEmpty) {
      var errorString = errors.join('\n');
      throw new BaseException('Template parse errors:\n$errorString');
    }
    return result.templateAst;
  }

  /// Parses template and populates ast nodes, errors and warnings in
  /// TemplateParseResult.
  TemplateParseResult tryParse(
      CompileDirectiveMetadata component,
      String template,
      List<CompileDirectiveMetadata> directives,
      List<CompilePipeMetadata> pipes,
      String templateUrl) {
    var htmlAstWithErrors = _htmlParser.parse(template, templateUrl);
    List<ParseError> errors = htmlAstWithErrors.errors;
    List<TemplateAst> result;
    if (htmlAstWithErrors.rootNodes.isNotEmpty) {
      List<CompileDirectiveMetadata> uniqDirectives;
      try {
        uniqDirectives = removeDuplicates(directives);
      } catch (_) {
        // Continue since we are trying to report errors.
        uniqDirectives = directives;
      }
      var uniquePipes = removeDuplicates(pipes);
      var providerViewContext = new ProviderViewContext(
          component, htmlAstWithErrors.rootNodes.first.sourceSpan);
      try {
        var parseVisitor = new TemplateParseVisitor(
            providerViewContext,
            uniqDirectives,
            uniquePipes,
            _exprParser,
            schemaRegistry,
            component.template?.preserveWhitespace ?? false);
        result = htmlVisitAll(parseVisitor, htmlAstWithErrors.rootNodes,
            EMPTY_ELEMENT_CONTEXT) as List<TemplateAst>;
        errors = new List.from(errors)
          ..addAll(parseVisitor.errors)
          ..addAll(providerViewContext.errors);
      } catch (_) {
        errors = new List.from(errors)..addAll(providerViewContext.errors);
        result = <TemplateAst>[];
      }
    } else {
      result = <TemplateAst>[];
    }
    return new TemplateParseResult(result, errors);
  }
}

/// Visits HTML AST and produces TemplateAST.
///
/// - Uses expression parser for interpolations, event actions and bindings.
/// - Validates pipe names.
class TemplateParseVisitor implements HtmlAstVisitor {
  final ProviderViewContext providerViewContext;
  final Parser _exprParser;
  final ElementSchemaRegistry _schemaRegistry;
  final SelectorMatcher selectorMatcher = new SelectorMatcher();
  final List<TemplateParseError> errors = [];
  final Map<String, CompilePipeMetadata> pipesByName =
      <String, CompilePipeMetadata>{};
  final bool preserveWhitespace;
  var directivesIndex = new Map<CompileDirectiveMetadata, int>();
  int ngContentCount = 0;

  TemplateParseVisitor(
      this.providerViewContext,
      List<CompileDirectiveMetadata> directives,
      List<CompilePipeMetadata> pipes,
      this._exprParser,
      this._schemaRegistry,
      this.preserveWhitespace) {
    // Add all css selectors in directives to selectorMatcher to map from html
    // node to each directive efficiently.
    var index = -1;
    for (CompileDirectiveMetadata directive in directives) {
      index++;
      var selector = CssSelector.parse(directive.selector);
      selectorMatcher.addSelectables(selector, directive);
      directivesIndex[directive] = index;
    }
    for (var pipe in pipes) {
      // TODO: report duplicate pipe name error.
      pipesByName[pipe.name] = pipe;
    }
  }

  void _reportError(String message, SourceSpan sourceSpan,
      [ParseErrorLevel level]) {
    level ??= ParseErrorLevel.FATAL;
    errors.add(new TemplateParseError(message, sourceSpan, level));
  }

  @override
  bool visit(HtmlAst ast, dynamic context) => false;

  @override
  dynamic visitText(HtmlTextAst ast, dynamic context) {
    ElementContext parent = context;
    var ngContentIndex = parent.findNgContentIndex(TEXT_CSS_SELECTOR);
    var expr = _parseInterpolation(ast.value, ast.sourceSpan, parent.exports);
    if (expr != null) {
      return new BoundTextAst(expr, ngContentIndex, ast.sourceSpan);
    } else {
      String text = ast.value;
      // If preserve white space is turned off, filter out spaces after line
      // breaks and any empty text nodes.
      if (preserveWhitespace == false) {
        if (!(text.contains('\u00A0') || text.contains(ngSpace))) {
          text = text.trim();
        }
        if (text.isEmpty) return null;
        if (_isNewLineWithSpaces(text)) {
          return null;
        }
      }
      // Convert &ngsp to actual space.
      text = text.replaceAll('\uE500', ' ');
      return new TextAst(text, ngContentIndex, ast.sourceSpan);
    }
  }

  bool _isNewLineWithSpaces(String text) {
    int len = text.length;
    for (int i = 0; i < len; i++) {
      if (text[i] != '\n' && text[i] != ' ') {
        return false;
      }
    }
    return true;
  }

  dynamic visitAttr(HtmlAttrAst ast, dynamic context) {
    return new AttrAst(ast.name, ast.value, ast.sourceSpan);
  }

  dynamic visitComment(HtmlCommentAst ast, dynamic context) {
    return null;
  }

  dynamic visitElement(HtmlElementAst element, dynamic context) {
    ElementContext parent = context;
    var nodeName = element.name;
    var preparsedElement = preparseElement(element);
    if (preparsedElement.isScript || preparsedElement.isStyle) {
      // Skipping <script> for security reasons
      // Skipping <style> as we already processed them in the StyleCompiler.
      return null;
    }
    if (preparsedElement.isStyleSheet &&
        isStyleUrlResolvable(preparsedElement.hrefAttr)) {
      // Skipping stylesheets with either relative urls or package scheme as
      // we already processed them in the StyleCompiler
      return null;
    }
    var matchableAttrs = <List<String>>[];
    var elementOrDirectiveProps = <BoundElementOrDirectiveProperty>[];
    var elementOrDirectiveRefs = <ElementOrDirectiveRef>[];
    var elementVars = <VariableAst>[];
    var events = <BoundEventAst>[];
    var templateElementOrDirectiveProps = <BoundElementOrDirectiveProperty>[];
    var templateMatchableAttrs = <List<String>>[];
    var templateElementVars = <VariableAst>[];
    var hasInlineTemplates = false;
    var attrs = <AttrAst>[];
    var lcElName = splitNsName(nodeName.toLowerCase())[1];
    var isTemplateElement = lcElName == TEMPLATE_ELEMENT;
    bool hasDeferredComponent = false;

    for (HtmlAttrAst attr in element.attrs) {
      var hasBinding = _parseAttr(
          isTemplateElement,
          attr,
          matchableAttrs,
          elementOrDirectiveProps,
          events,
          elementOrDirectiveRefs,
          elementVars,
          providerViewContext.component.exports);
      var hasTemplateBinding = _parseInlineTemplateBinding(
          attr,
          templateMatchableAttrs,
          templateElementOrDirectiveProps,
          templateElementVars,
          providerViewContext.component.exports);
      if (!hasBinding && !hasTemplateBinding) {
        // don't include the bindings as attributes as well in the AST
        attrs.add(visitAttr(attr, null));
        matchableAttrs.add([attr.name, attr.value]);
      }
      if (hasTemplateBinding) {
        hasInlineTemplates = true;
      }
      if (attr.name == TEMPLATE_DEFERRED_ATTR) {
        hasDeferredComponent = true;
      }
    }
    var elementCssSelector = createElementCssSelector(nodeName, matchableAttrs);
    var directiveMetas = _parseDirectives(selectorMatcher, elementCssSelector);
    var references = <ReferenceAst>[];
    var directiveAsts = _createDirectiveAsts(
        isTemplateElement,
        element.name,
        directiveMetas,
        elementOrDirectiveProps,
        elementOrDirectiveRefs,
        element.sourceSpan,
        references,
        providerViewContext.component.exports);
    List<BoundElementPropertyAst> elementProps = this
        ._createElementPropertyAsts(
            element.name, elementOrDirectiveProps, directiveAsts);
    var isViewRoot = parent.isTemplateElement || hasInlineTemplates;
    var providerContext = new ProviderElementContext(
        providerViewContext,
        parent.providerContext,
        isViewRoot,
        directiveAsts,
        attrs,
        references,
        element.sourceSpan);
    List<TemplateAst> children = htmlVisitAll(
        preparsedElement.nonBindable ? NON_BINDABLE_VISITOR : this,
        element.children,
        ElementContext.create(
            isTemplateElement,
            directiveAsts,
            isTemplateElement ? parent.providerContext : providerContext,
            providerViewContext.component.exports)) as List<TemplateAst>;
    providerContext.afterElement();
    // Override the actual selector when the `ngProjectAs` attribute is provided
    var projectionSelector = preparsedElement.projectAs != null
        ? CssSelector.parse(preparsedElement.projectAs)[0]
        : elementCssSelector;
    var ngContentIndex = parent.findNgContentIndex(projectionSelector);
    TemplateAst parsedElement;
    if (preparsedElement.isNgContent) {
      var elementChildren = element.children;
      if (elementChildren != null && elementChildren.isNotEmpty) {
        _reportError(
            '<ng-content> element cannot have content. <ng-content> must '
            'be immediately followed by </ng-content>',
            element.sourceSpan);
      }
      parsedElement = new NgContentAst(this.ngContentCount++,
          hasInlineTemplates ? null : ngContentIndex, element.sourceSpan);
    } else if (isTemplateElement) {
      _assertAllEventsPublishedByDirectives(directiveAsts, events);
      _assertNoComponentsNorElementBindingsOnTemplate(
          directiveAsts, elementProps, element.sourceSpan);
      parsedElement = new EmbeddedTemplateAst(
          attrs,
          events,
          references,
          elementVars,
          providerContext.transformedDirectiveAsts,
          providerContext.transformProviders,
          providerContext,
          children,
          hasInlineTemplates ? null : ngContentIndex,
          element.sourceSpan);
    } else {
      this._assertOnlyOneComponent(directiveAsts, element.sourceSpan);
      var ngContentIndex = hasInlineTemplates
          ? null
          : parent.findNgContentIndex(projectionSelector);
      parsedElement = new ElementAst(
          nodeName,
          attrs,
          elementProps,
          events,
          references,
          providerContext.transformedDirectiveAsts,
          providerContext.transformProviders,
          providerContext,
          children,
          hasInlineTemplates ? null : ngContentIndex,
          element.sourceSpan);
    }
    if (hasInlineTemplates) {
      var templateCssSelector =
          createElementCssSelector(TEMPLATE_ELEMENT, templateMatchableAttrs);
      var templateDirectiveMetas =
          _parseDirectives(selectorMatcher, templateCssSelector);
      var templateDirectiveAsts = _createDirectiveAsts(
          true,
          element.name,
          templateDirectiveMetas,
          templateElementOrDirectiveProps,
          [],
          element.sourceSpan,
          [],
          providerViewContext.component.exports);
      List<BoundElementPropertyAst> templateElementProps =
          _createElementPropertyAsts(element.name,
              templateElementOrDirectiveProps, templateDirectiveAsts);
      _assertNoComponentsNorElementBindingsOnTemplate(
          templateDirectiveAsts, templateElementProps, element.sourceSpan);
      var templateProviderContext = new ProviderElementContext(
          this.providerViewContext,
          parent.providerContext,
          parent.isTemplateElement,
          templateDirectiveAsts,
          [],
          [],
          element.sourceSpan);
      templateProviderContext.afterElement();
      parsedElement = new EmbeddedTemplateAst(
          [],
          [],
          [],
          templateElementVars,
          templateProviderContext.transformedDirectiveAsts,
          templateProviderContext.transformProviders,
          templateProviderContext,
          [parsedElement],
          ngContentIndex,
          element.sourceSpan,
          hasDeferredComponent: hasDeferredComponent);
    }
    return parsedElement;
  }

  ASTWithSource _parseInterpolation(String value, SourceSpan sourceSpan,
      List<CompileIdentifierMetadata> exports) {
    var sourceInfo = sourceSpan.start.toString();
    try {
      var ast = _exprParser.parseInterpolation(value, sourceInfo, exports);
      _validatePipeNames(ast, sourceSpan);
      // Validate number of interpolations.
      if (ast != null &&
          (ast.ast as Interpolation).expressions.length >
              MAX_INTERPOLATION_VALUES) {
        throw new BaseException(
            'Only support at most $MAX_INTERPOLATION_VALUES '
            'interpolation values!');
      }
      return ast;
    } catch (e) {
      _reportError('$e', sourceSpan);
      return _exprParser.wrapLiteralPrimitive('ERROR', sourceInfo);
    }
  }

  ASTWithSource _parseAction(String value, SourceSpan sourceSpan,
      List<CompileIdentifierMetadata> exports) {
    var sourceInfo = sourceSpan.start.toString();
    try {
      var ast = _exprParser.parseAction(value, sourceInfo, exports);
      _validatePipeNames(ast, sourceSpan);
      return ast;
    } catch (e) {
      _reportError('$e', sourceSpan);
      return _exprParser.wrapLiteralPrimitive('ERROR', sourceInfo);
    }
  }

  ASTWithSource _parseBinding(String value, SourceSpan sourceSpan,
      List<CompileIdentifierMetadata> exports) {
    var sourceInfo = sourceSpan.start.toString();
    try {
      var ast = _exprParser.parseBinding(value, sourceInfo, exports);
      _validatePipeNames(ast, sourceSpan);
      return ast;
    } catch (e) {
      _reportError('$e', sourceSpan);
      return _exprParser.wrapLiteralPrimitive('ERROR', sourceInfo);
    }
  }

  List<TemplateBinding> _parseTemplateBindings(String value,
      SourceSpan sourceSpan, List<CompileIdentifierMetadata> exports) {
    var sourceInfo = sourceSpan.start.toString();
    try {
      var bindingsResult =
          _exprParser.parseTemplateBindings(value, sourceInfo, exports);
      for (TemplateBinding binding in bindingsResult.templateBindings) {
        if (binding.expression != null) {
          _validatePipeNames(binding.expression, sourceSpan);
        }
      }
      for (var warning in bindingsResult.warnings) {
        _reportError(warning, sourceSpan, ParseErrorLevel.WARNING);
      }
      return bindingsResult.templateBindings;
    } catch (e) {
      _reportError('$e', sourceSpan);
      return [];
    }
  }

  void _validatePipeNames(ASTWithSource ast, SourceSpan sourceSpan) {
    if (ast == null) return;
    var collector = new PipeCollector();
    ast.visit(collector);
    for (String pipeName in collector.pipes) {
      if (!pipesByName.containsKey(pipeName)) {
        _reportError("The pipe '$pipeName' could not be found", sourceSpan);
      }
    }
  }

  bool _parseInlineTemplateBinding(
      HtmlAttrAst attr,
      List<List<String>> targetMatchableAttrs,
      List<BoundElementOrDirectiveProperty> targetProps,
      List<VariableAst> targetVars,
      List<CompileIdentifierMetadata> exports) {
    var templateBindingsSource;
    bool isDeferredAttr = false;
    if (attr.name == TEMPLATE_ATTR) {
      templateBindingsSource = attr.value;
    } else if (attr.name.startsWith(TEMPLATE_ATTR_PREFIX)) {
      var key = attr.name.substring(TEMPLATE_ATTR_PREFIX.length);
      templateBindingsSource =
          (attr.value.length == 0) ? key : key + ' ' + attr.value;
    } else if (attr.name == TEMPLATE_DEFERRED_ATTR) {
      templateBindingsSource = attr.value;
      isDeferredAttr = true;
    }
    if (templateBindingsSource == null) return false;
    var bindings = _parseTemplateBindings(
        templateBindingsSource, attr.sourceSpan, exports);
    if (isDeferredAttr && bindings != null && bindings.isNotEmpty) {
      _reportError('"@deferred" on elements can\'t be bound to an expression.',
          attr.sourceSpan, ParseErrorLevel.FATAL);
      return false;
    }
    for (var i = 0; i < bindings.length; i++) {
      var binding = bindings[i];
      if (binding.keyIsVar) {
        targetVars
            .add(new VariableAst(binding.key, binding.name, attr.sourceSpan));
      } else if (binding.expression != null) {
        this._parsePropertyAst(binding.key, binding.expression, attr.sourceSpan,
            targetMatchableAttrs, targetProps);
      } else {
        targetMatchableAttrs.add([binding.key, '']);
        _parseLiteralAttr(
            binding.key, null, attr.sourceSpan, true, targetProps);
      }
    }
    return true;
  }

  bool _parseAttr(
      bool isTemplateElement,
      HtmlAttrAst attr,
      List<List<String>> targetMatchableAttrs,
      List<BoundElementOrDirectiveProperty> targetProps,
      List<BoundEventAst> targetEvents,
      List<ElementOrDirectiveRef> targetRefs,
      List<VariableAst> targetVars,
      List<CompileIdentifierMetadata> exports) {
    String attrName = _removeDataPrefix(attr.name);
    var attrValue = attr.value;
    var bindParts = BIND_NAME_REGEXP.firstMatch(attrName);
    var hasBinding = false;
    if (bindParts != null) {
      hasBinding = true;
      if (bindParts[1] != null) {
        // Group 1 = 'bind-'
        _parseProperty(bindParts[7], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetProps, exports);
      } else if (bindParts[2] != null) {
        // Group 2 = 'var-'
        var identifier = bindParts[7];
        if (isTemplateElement) {
          this._reportError(
              '"var-" on <template> elements is deprecated. '
              'Use "let-" instead!',
              attr.sourceSpan,
              ParseErrorLevel.WARNING);
          _parseVariable(identifier, attrValue, attr.sourceSpan, targetVars);
        } else {
          this._reportError(
              '"var-" on non <template> elements is deprecated. '
              'Use "ref-" instead!',
              attr.sourceSpan,
              ParseErrorLevel.WARNING);
          _parseReference(identifier, attrValue, attr.sourceSpan, targetRefs);
        }
      } else if (bindParts[3] != null) {
        // Group 3 = 'let-'
        if (isTemplateElement) {
          var identifierName = bindParts[7];
          _parseVariable(
              identifierName, attrValue, attr.sourceSpan, targetVars);
        } else {
          this._reportError('"let-" is only supported on template elements.',
              attr.sourceSpan);
        }
      } else if (bindParts[4] != null) {
        // Group 4 = 'ref-/#'
        var identifier = bindParts[7];
        _parseReference(identifier, attrValue, attr.sourceSpan, targetRefs);
      } else if (bindParts[5] != null) {
        // Group 5 = 'on-'
        _parseEvent(bindParts[7], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetEvents, exports);
      } else if (bindParts[6] != null) {
        // Group 6 = 'bindon-'
        _parseProperty(bindParts[7], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetProps, exports);
        _parseAssignmentEvent(bindParts[7], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetEvents, exports);
      } else if (bindParts[8] != null) {
        // Group 8 = identifier inside [()]
        _parseProperty(bindParts[8], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetProps, exports);
        _parseAssignmentEvent(bindParts[8], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetEvents, exports);
      } else if (bindParts[9] != null) {
        // Group 9 = identifier inside []
        _parseProperty(bindParts[9], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetProps, exports);
      } else if (bindParts[10] != null) {
        // Group 10 = identifier inside ()
        _parseEvent(bindParts[10], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetEvents, exports);
      }
    } else {
      hasBinding = _parsePropertyInterpolation(attrName, attrValue,
          attr.sourceSpan, targetMatchableAttrs, targetProps, exports);
    }
    if (!hasBinding) {
      _parseLiteralAttr(
          attrName, attrValue, attr.sourceSpan, attr.hasValue, targetProps);
    }
    return hasBinding;
  }

  String _removeDataPrefix(String attrName) {
    return attrName.toLowerCase().startsWith('data-')
        ? attrName.substring(5)
        : attrName;
  }

  void _parseVariable(String identifier, String value, SourceSpan sourceSpan,
      List<VariableAst> targetVars) {
    if (identifier.indexOf('-') > -1) {
      _reportError('"-" is not allowed in variable names', sourceSpan);
    }
    targetVars.add(new VariableAst(identifier, value, sourceSpan));
  }

  void _parseReference(String identifier, String value, SourceSpan sourceSpan,
      List<ElementOrDirectiveRef> targetRefs) {
    if (identifier.indexOf('-') > -1) {
      this._reportError('"-" is not allowed in reference names', sourceSpan);
    }
    targetRefs.add(new ElementOrDirectiveRef(identifier, value, sourceSpan));
  }

  void _parseProperty(
      String name,
      String expression,
      SourceSpan sourceSpan,
      List<List<String>> targetMatchableAttrs,
      List<BoundElementOrDirectiveProperty> targetProps,
      List<CompileIdentifierMetadata> exports) {
    _parsePropertyAst(name, _parseBinding(expression, sourceSpan, exports),
        sourceSpan, targetMatchableAttrs, targetProps);
  }

  bool _parsePropertyInterpolation(
      String name,
      String value,
      SourceSpan sourceSpan,
      List<List<String>> targetMatchableAttrs,
      List<BoundElementOrDirectiveProperty> targetProps,
      List<CompileIdentifierMetadata> exports) {
    var expr = _parseInterpolation(value, sourceSpan, exports);
    if (expr == null) return false;
    _parsePropertyAst(
        name, expr, sourceSpan, targetMatchableAttrs, targetProps);
    return true;
  }

  void _parsePropertyAst(
      String name,
      ASTWithSource ast,
      SourceSpan sourceSpan,
      List<List<String>> targetMatchableAttrs,
      List<BoundElementOrDirectiveProperty> targetProps) {
    targetMatchableAttrs.add([name, ast.source]);
    targetProps
        .add(new BoundElementOrDirectiveProperty(name, ast, false, sourceSpan));
  }

  void _parseAssignmentEvent(
      String name,
      String expression,
      SourceSpan sourceSpan,
      List<List<String>> targetMatchableAttrs,
      List<BoundEventAst> targetEvents,
      List<CompileIdentifierMetadata> exports) {
    _parseEvent('${name}Change', '$expression=\$event', sourceSpan,
        targetMatchableAttrs, targetEvents, exports);
  }

  void _parseEvent(
      String name,
      String expression,
      SourceSpan sourceSpan,
      List<List<String>> targetMatchableAttrs,
      List<BoundEventAst> targetEvents,
      List<CompileIdentifierMetadata> exports) {
    if (name.contains(':')) {
      _reportError('":" is not allowed in event names: $name', sourceSpan);
    }
    var ast = this._parseAction(expression, sourceSpan, exports);
    targetMatchableAttrs.add([name, ast.source]);
    targetEvents.add(new BoundEventAst(name, ast, sourceSpan));
  }

  void _parseLiteralAttr(String name, String value, SourceSpan sourceSpan,
      bool hasValue, List<BoundElementOrDirectiveProperty> targetProps) {
    AST valueAst;
    if (hasValue) {
      valueAst = _exprParser.wrapLiteralPrimitive(value, '');
    } else {
      valueAst = new EmptyExpr();
    }
    targetProps.add(
        new BoundElementOrDirectiveProperty(name, valueAst, true, sourceSpan));
  }

  List<CompileDirectiveMetadata> _parseDirectives(
      SelectorMatcher selectorMatcher, CssSelector elementCssSelector) {
    // Need to sort the directives so that we get consistent results throughout,
    // as selectorMatcher uses Maps inside.
    // Also dedupe directives as they might match more than one time!
    var directives = new List(this.directivesIndex.length);
    selectorMatcher.match(elementCssSelector, (selector, directive) {
      directives[directivesIndex[directive]] = directive;
    });
    var result = <CompileDirectiveMetadata>[];
    for (CompileDirectiveMetadata dir in directives) {
      if (dir != null) result.add(dir);
    }
    return result;
  }

  List<DirectiveAst> _createDirectiveAsts(
      bool isTemplateElement,
      String elementName,
      List<CompileDirectiveMetadata> directives,
      List<BoundElementOrDirectiveProperty> props,
      List<ElementOrDirectiveRef> elementOrDirectiveRefs,
      SourceSpan sourceSpan,
      List<ReferenceAst> targetReferences,
      List<CompileIdentifierMetadata> exports) {
    var matchedReferences = new Set<String>();
    CompileDirectiveMetadata component;
    var directiveAsts = <DirectiveAst>[];
    for (CompileDirectiveMetadata directive in directives) {
      if (directive.isComponent) {
        component = directive;
      }
      List<BoundElementPropertyAst> hostProperties =
          _createDirectiveHostPropertyAsts(
              elementName, directive.hostProperties, sourceSpan, exports);
      List<BoundEventAst> hostEvents = _createDirectiveHostEventAsts(
          directive.hostListeners, sourceSpan, exports);
      List<BoundDirectivePropertyAst> directiveProperties =
          _createDirectivePropertyAsts(directive.inputs, props);

      for (ElementOrDirectiveRef elOrDirRef in elementOrDirectiveRefs) {
        if ((elOrDirRef.value.isEmpty && directive.isComponent) ||
            (directive.exportAs == elOrDirRef.value)) {
          targetReferences.add(new ReferenceAst(elOrDirRef.name,
              identifierToken(directive.type), elOrDirRef.sourceSpan));
          matchedReferences.add(elOrDirRef.name);
        }
      }
      directiveAsts.add(new DirectiveAst(directive, directiveProperties,
          hostProperties, hostEvents, sourceSpan));
    }
    for (var elOrDirRef in elementOrDirectiveRefs) {
      if (elOrDirRef.value.isNotEmpty) {
        if (!matchedReferences.contains(elOrDirRef.name)) {
          this._reportError(
              'There is no directive with "exportAs" set '
              'to "${elOrDirRef.value}"',
              elOrDirRef.sourceSpan);
        }
      } else if (component == null) {
        var refToken;
        if (isTemplateElement) {
          refToken = identifierToken(Identifiers.TemplateRef);
        }
        targetReferences.add(
            new ReferenceAst(elOrDirRef.name, refToken, elOrDirRef.sourceSpan));
      }
    }
    return directiveAsts;
  }

  List<BoundElementPropertyAst> _createDirectiveHostPropertyAsts(
      String elementName,
      Map<String, String> hostProps,
      SourceSpan sourceSpan,
      List<CompileIdentifierMetadata> exports) {
    if (hostProps == null) return const [];
    var targetPropertyAsts = <BoundElementPropertyAst>[];
    hostProps.forEach((String propName, String expression) {
      var exprAst = _parseBinding(expression, sourceSpan, exports);
      targetPropertyAsts.add(createElementPropertyAst(elementName, propName,
          exprAst, sourceSpan, _schemaRegistry, _reportError));
    });
    return targetPropertyAsts;
  }

  List<BoundEventAst> _createDirectiveHostEventAsts(
      Map<String, String> hostListeners,
      SourceSpan sourceSpan,
      List<CompileIdentifierMetadata> exports) {
    var targetEventAsts = <BoundEventAst>[];
    if (hostListeners == null) return const [];
    hostListeners.forEach((String propName, String expression) {
      _parseEvent(
          propName, expression, sourceSpan, [], targetEventAsts, exports);
    });
    return targetEventAsts;
  }

  List<BoundDirectivePropertyAst> _createDirectivePropertyAsts(
      Map<String, String> directiveProperties,
      List<BoundElementOrDirectiveProperty> boundProps) {
    if (directiveProperties == null) return const [];
    var targetBoundDirectiveProps = <BoundDirectivePropertyAst>[];
    var boundPropsByName = new Map<String, BoundElementOrDirectiveProperty>();
    for (BoundElementOrDirectiveProperty boundProp in boundProps) {
      var prevValue = boundPropsByName[boundProp.name];
      if (prevValue == null || prevValue.isLiteral) {
        // give [a]="b" a higher precedence than a="b" on the same element
        boundPropsByName[boundProp.name] = boundProp;
      }
    }
    directiveProperties.forEach((String dirProp, String elProp) {
      var boundProp = boundPropsByName[elProp];
      // Bindings are optional, so this binding only needs to be set up
      // if an expression is given.
      if (boundProp != null) {
        targetBoundDirectiveProps.add(new BoundDirectivePropertyAst(dirProp,
            boundProp.name, boundProp.expression, boundProp.sourceSpan));
      }
    });
    return targetBoundDirectiveProps;
  }

  List<BoundElementPropertyAst> _createElementPropertyAsts(
      String elementName,
      List<BoundElementOrDirectiveProperty> props,
      List<DirectiveAst> directives) {
    var boundElementProps = <BoundElementPropertyAst>[];
    var boundDirectivePropsIndex = <String, BoundDirectivePropertyAst>{};
    for (DirectiveAst directive in directives) {
      for (BoundDirectivePropertyAst prop in directive.inputs) {
        boundDirectivePropsIndex[prop.templateName] = prop;
      }
    }
    for (BoundElementOrDirectiveProperty prop in props) {
      if (!prop.isLiteral && boundDirectivePropsIndex[prop.name] == null) {
        boundElementProps.add(createElementPropertyAst(elementName, prop.name,
            prop.expression, prop.sourceSpan, _schemaRegistry, _reportError));
      }
    }
    return boundElementProps;
  }

  List<String> _findComponentDirectiveNames(List<DirectiveAst> directives) {
    List<String> componentTypeNames = [];
    for (var directive in directives) {
      var typeName = directive.directive.type.name;
      if (directive.directive.isComponent) {
        componentTypeNames.add(typeName);
      }
    }
    return componentTypeNames;
  }

  void _assertOnlyOneComponent(
      List<DirectiveAst> directives, SourceSpan sourceSpan) {
    var componentTypeNames = this._findComponentDirectiveNames(directives);
    if (componentTypeNames.length > 1) {
      _reportError('More than one component: ${componentTypeNames.join(",")}',
          sourceSpan);
    }
  }

  void _assertNoComponentsNorElementBindingsOnTemplate(
      List<DirectiveAst> directives,
      List<BoundElementPropertyAst> elementProps,
      SourceSpan sourceSpan) {
    List<String> componentTypeNames =
        this._findComponentDirectiveNames(directives);
    if (componentTypeNames.isNotEmpty) {
      _reportError(
          'Components on an embedded template: ${componentTypeNames.join(",")}',
          sourceSpan);
    }
    elementProps.forEach((prop) {
      _reportError(
          'Property binding ${prop.name} not used by any directive on an '
          'embedded template',
          sourceSpan);
    });
  }

  void _assertAllEventsPublishedByDirectives(
      List<DirectiveAst> directives, List<BoundEventAst> events) {
    var allDirectiveEvents = new Set<String>();
    for (var directive in directives) {
      for (var eventName in directive.directive.outputs.values) {
        allDirectiveEvents.add(eventName);
      }
    }
    for (var event in events) {
      if (!allDirectiveEvents.contains(event.name)) {
        _reportError(
            'Event binding ${event.name} not emitted by any directive on '
            'an embedded template',
            event.sourceSpan);
      }
    }
  }
}

typedef void ErrorCallback(String message, SourceSpan sourceSpan,
    [ParseErrorLevel level]);

BoundElementPropertyAst createElementPropertyAst(
    String elementName,
    String name,
    AST valueExpr,
    SourceSpan sourceSpan,
    ElementSchemaRegistry schemaRegistry,
    ErrorCallback reportError) {
  var unit;
  var bindingType;
  String boundPropertyName;
  TemplateSecurityContext securityContext;
  var parts = name.split(PROPERTY_PARTS_SEPARATOR);
  if (identical(parts.length, 1)) {
    boundPropertyName = schemaRegistry.getMappedPropName(parts[0]);
    securityContext =
        schemaRegistry.securityContext(elementName, boundPropertyName);
    bindingType = PropertyBindingType.Property;
    if (!schemaRegistry.hasProperty(elementName, boundPropertyName)) {
      if (boundPropertyName == 'ngclass') {
        reportError(
            'Please use camel-case ngClass instead of ngclass in your template',
            sourceSpan);
      } else {
        reportError(
            "Can't bind to '$boundPropertyName' since it isn't a known "
            "native property or known directive. Please fix typo or add to "
            "directives list.",
            sourceSpan);
      }
    }
  } else {
    if (parts[0] == ATTRIBUTE_PREFIX) {
      boundPropertyName = parts[1];
      if (boundPropertyName.toLowerCase().startsWith('on')) {
        reportError(
            'Binding to event attribute \'$boundPropertyName\' '
            'is disallowed for security reasons, please use '
            '(${boundPropertyName.substring(2)})=...',
            sourceSpan);
      }
      // NB: For security purposes, use the mapped property name, not the
      // attribute name.
      securityContext = schemaRegistry.securityContext(
          elementName, schemaRegistry.getMappedPropName(boundPropertyName));
      var nsSeparatorIdx = boundPropertyName.indexOf(':');
      if (nsSeparatorIdx > -1) {
        var ns = boundPropertyName.substring(0, nsSeparatorIdx);
        var name = boundPropertyName.substring(nsSeparatorIdx + 1);
        boundPropertyName = mergeNsAndName(ns, name);
      }
      bindingType = PropertyBindingType.Attribute;
    } else if (parts[0] == CLASS_PREFIX) {
      boundPropertyName = parts[1];
      bindingType = PropertyBindingType.Class;
      securityContext = TemplateSecurityContext.none;
    } else if (parts[0] == STYLE_PREFIX) {
      unit = parts.length > 2 ? parts[2] : null;
      boundPropertyName = parts[1];
      bindingType = PropertyBindingType.Style;
      securityContext = TemplateSecurityContext.style;
    } else {
      reportError("Invalid property name '$name'", sourceSpan);
      bindingType = null;
      securityContext = null;
    }
  }
  return new BoundElementPropertyAst(boundPropertyName, bindingType,
      securityContext, valueExpr, unit, sourceSpan);
}

class NonBindableVisitor implements HtmlAstVisitor {
  @override
  bool visit(HtmlAst ast, dynamic context) => false;

  @override
  ElementAst visitElement(HtmlElementAst ast, dynamic context) {
    ElementContext parent = context;
    var preparsedElement = preparseElement(ast);
    if (preparsedElement.isScript ||
        preparsedElement.isStyle ||
        preparsedElement.isStyleSheet) {
      // Skipping <script> for security reasons
      // Skipping <style> and stylesheets as we already processed them
      // in the StyleCompiler
      return null;
    }
    var attrNameAndValues =
        ast.attrs.map((attrAst) => [attrAst.name, attrAst.value]).toList();
    var selector = createElementCssSelector(ast.name, attrNameAndValues);
    var ngContentIndex = parent.findNgContentIndex(selector);
    var children = htmlVisitAll(this, ast.children, EMPTY_ELEMENT_CONTEXT)
        as List<TemplateAst>;
    return new ElementAst(
        ast.name,
        htmlVisitAll(this, ast.attrs) as List<AttrAst>,
        [],
        [],
        [],
        [],
        [],
        null,
        children,
        ngContentIndex,
        ast.sourceSpan);
  }

  @override
  dynamic visitComment(HtmlCommentAst ast, dynamic context) {
    return null;
  }

  @override
  AttrAst visitAttr(HtmlAttrAst ast, dynamic context) {
    return new AttrAst(ast.name, ast.value, ast.sourceSpan);
  }

  @override
  TextAst visitText(HtmlTextAst ast, dynamic context) {
    ElementContext parent = context;
    var ngContentIndex = parent.findNgContentIndex(TEXT_CSS_SELECTOR);
    return new TextAst(ast.value, ngContentIndex, ast.sourceSpan);
  }
}

class BoundElementOrDirectiveProperty {
  String name;
  AST expression;
  bool isLiteral;
  SourceSpan sourceSpan;
  BoundElementOrDirectiveProperty(
      this.name, this.expression, this.isLiteral, this.sourceSpan);
}

class ElementOrDirectiveRef {
  String name;
  String value;
  SourceSpan sourceSpan;
  ElementOrDirectiveRef(this.name, this.value, this.sourceSpan);
}

List<String> splitClasses(String classAttrValue) {
  return jsSplit(classAttrValue.trim(), (new RegExp(r'\s+')));
}

class ElementContext {
  bool isTemplateElement;
  SelectorMatcher _ngContentIndexMatcher;
  int _wildcardNgContentIndex;
  ProviderElementContext providerContext;
  List<CompileIdentifierMetadata> exports;

  static ElementContext create(
      bool isTemplateElement,
      List<DirectiveAst> directives,
      ProviderElementContext providerContext,
      List<CompileIdentifierMetadata> exports) {
    var matcher = new SelectorMatcher();
    int wildcardNgContentIndex;
    var component = directives.firstWhere(
        (directive) => directive.directive.isComponent,
        orElse: () => null);
    if (component != null) {
      var ngContentSelectors = component.directive.template.ngContentSelectors;
      for (var i = 0; i < ngContentSelectors.length; i++) {
        var selector = ngContentSelectors[i];
        if (selector == '*') {
          wildcardNgContentIndex = i;
        } else {
          matcher.addSelectables(CssSelector.parse(ngContentSelectors[i]), i);
        }
      }
    }
    return new ElementContext(isTemplateElement, matcher,
        wildcardNgContentIndex, providerContext, exports);
  }

  ElementContext(this.isTemplateElement, this._ngContentIndexMatcher,
      this._wildcardNgContentIndex, this.providerContext, this.exports);

  int findNgContentIndex(CssSelector selector) {
    var ngContentIndices = [];
    this._ngContentIndexMatcher.match(selector, (selector, ngContentIndex) {
      ngContentIndices.add(ngContentIndex);
    });
    ngContentIndices.sort();
    if (_wildcardNgContentIndex != null) {
      ngContentIndices.add(_wildcardNgContentIndex);
    }
    return ngContentIndices.length > 0 ? ngContentIndices[0] : null;
  }
}

CssSelector createElementCssSelector(
    String elementName, List<List<String>> matchableAttrs) {
  var cssSelector = new CssSelector();
  var elNameNoNs = splitNsName(elementName)[1];
  cssSelector.setElement(elNameNoNs);
  for (var i = 0; i < matchableAttrs.length; i++) {
    var attrName = matchableAttrs[i][0];
    var attrNameNoNs = splitNsName(attrName)[1];
    var attrValue = matchableAttrs[i][1];
    // [CssSelector] is used both to define selectors, and to describe an
    // element. This is unfortunate as certain attribute selectors don't make
    // sense in context of defining an element. Since we're defining the
    // attributes of an element here, we use exact match ('=') to specify that
    // the element has this attribute value.
    cssSelector.addAttribute(attrNameNoNs, '=', attrValue);
    if (attrName.toLowerCase() == CLASS_ATTR) {
      var classes = splitClasses(attrValue);
      for (var className in classes) {
        cssSelector.addClassName(className);
      }
    }
  }
  return cssSelector;
}

var EMPTY_ELEMENT_CONTEXT =
    new ElementContext(true, new SelectorMatcher(), null, null, []);
var NON_BINDABLE_VISITOR = new NonBindableVisitor();

class PipeCollector extends RecursiveAstVisitor {
  Set<String> pipes = new Set<String>();
  dynamic visitPipe(BindingPipe ast, dynamic context) {
    this.pipes.add(ast.name);
    ast.exp.visit(this);
    this.visitAll(ast.args as List<AST>, context);
    return null;
  }
}

List<T> removeDuplicates<T>(List<T> items) {
  var res = <T>[];
  for (var item in items) {
    var hasMatch = res.where((r) {
      if (r is CompilePipeMetadata) {
        CompilePipeMetadata rMeta = r;
        CompilePipeMetadata itemMeta = item as CompilePipeMetadata;
        return rMeta.type.name == itemMeta.type.name &&
            rMeta.type.moduleUrl == itemMeta.type.moduleUrl;
      } else if (r is CompileDirectiveMetadata) {
        CompileDirectiveMetadata rMeta = r;
        CompileDirectiveMetadata itemMeta = item as CompileDirectiveMetadata;
        return rMeta.type.name == itemMeta.type.name &&
            rMeta.type.moduleUrl == itemMeta.type.moduleUrl;
      } else
        throw new ArgumentError();
    }).isNotEmpty;
    if (!hasMatch) {
      res.add(item);
    }
  }
  return res;
}
