library angular2.src.compiler.template_parser;

import "package:angular2/src/facade/collection.dart"
    show ListWrapper, StringMapWrapper, SetWrapper, MapWrapper;
import "package:angular2/src/facade/lang.dart"
    show RegExpWrapper, isPresent, StringWrapper, isBlank, isArray;
import "package:angular2/core.dart"
    show Injectable, Inject, OpaqueToken, Optional;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "expression_parser/ast.dart"
    show
        AST,
        Interpolation,
        ASTWithSource,
        TemplateBinding,
        RecursiveAstVisitor,
        BindingPipe;
import "expression_parser/parser.dart" show Parser;
import "compile_metadata.dart"
    show
        CompileTokenMap,
        CompileDirectiveMetadata,
        CompilePipeMetadata,
        CompileMetadataWithType,
        CompileProviderMetadata,
        CompileTokenMetadata,
        CompileTypeMetadata;
import "html_parser.dart" show HtmlParser;
import "html_tags.dart" show splitNsName, mergeNsAndName;
import "parse_util.dart" show ParseSourceSpan, ParseError, ParseLocation;
import "package:angular2/src/core/linker/view_utils.dart"
    show MAX_INTERPOLATION_VALUES;
import "template_ast.dart"
    show
        ElementAst,
        BoundElementPropertyAst,
        BoundEventAst,
        VariableAst,
        TemplateAst,
        TemplateAstVisitor,
        templateVisitAll,
        TextAst,
        BoundTextAst,
        EmbeddedTemplateAst,
        AttrAst,
        NgContentAst,
        PropertyBindingType,
        DirectiveAst,
        BoundDirectivePropertyAst,
        ProviderAst,
        ProviderAstType;
import "package:angular2/src/compiler/selector.dart"
    show CssSelector, SelectorMatcher;
import "package:angular2/src/compiler/schema/element_schema_registry.dart"
    show ElementSchemaRegistry;
import "template_preparser.dart"
    show preparseElement, PreparsedElement, PreparsedElementType;
import "style_url_resolver.dart" show isStyleUrlResolvable;
import "html_ast.dart"
    show
        HtmlAstVisitor,
        HtmlAst,
        HtmlElementAst,
        HtmlAttrAst,
        HtmlTextAst,
        HtmlCommentAst,
        HtmlExpansionAst,
        HtmlExpansionCaseAst,
        htmlVisitAll;
import "util.dart" show splitAtColon;
import "provider_parser.dart" show ProviderElementContext, ProviderViewContext;
// Group 1 = "bind-"

// Group 2 = "var-" or "#"

// Group 3 = "on-"

// Group 4 = "bindon-"

// Group 5 = the identifier after "bind-", "var-/#", or "on-"

// Group 6 = identifier inside [()]

// Group 7 = identifier inside []

// Group 8 = identifier inside ()
var BIND_NAME_REGEXP = new RegExp(
    r'^(?:(?:(?:(bind-)|(var-|#)|(on-)|(bindon-))(.+))|\[\(([^\)]+)\)\]|\[([^\]]+)\]|\(([^\)]+)\))$');
const TEMPLATE_ELEMENT = "template";
const TEMPLATE_ATTR = "template";
const TEMPLATE_ATTR_PREFIX = "*";
const CLASS_ATTR = "class";
var PROPERTY_PARTS_SEPARATOR = ".";
const ATTRIBUTE_PREFIX = "attr";
const CLASS_PREFIX = "class";
const STYLE_PREFIX = "style";
var TEXT_CSS_SELECTOR = CssSelector.parse("*")[0];
/**
 * Provides an array of [TemplateAstVisitor]s which will be used to transform
 * parsed templates before compilation is invoked, allowing custom expression syntax
 * and other advanced transformations.
 *
 * This is currently an internal-only feature and not meant for general use.
 */
const TEMPLATE_TRANSFORMS = const OpaqueToken("TemplateTransforms");

class TemplateParseError extends ParseError {
  TemplateParseError(String message, ParseSourceSpan span)
      : super(span, message) {
    /* super call moved to initializer */;
  }
}

class TemplateParseResult {
  List<TemplateAst> templateAst;
  List<ParseError> errors;
  TemplateParseResult([this.templateAst, this.errors]) {}
}

@Injectable()
class TemplateParser {
  Parser _exprParser;
  ElementSchemaRegistry _schemaRegistry;
  HtmlParser _htmlParser;
  List<TemplateAstVisitor> transforms;
  TemplateParser(this._exprParser, this._schemaRegistry, this._htmlParser,
      @Optional() @Inject(TEMPLATE_TRANSFORMS) this.transforms) {}
  List<TemplateAst> parse(
      CompileDirectiveMetadata component,
      String template,
      List<CompileDirectiveMetadata> directives,
      List<CompilePipeMetadata> pipes,
      String templateUrl) {
    var result =
        this.tryParse(component, template, directives, pipes, templateUrl);
    if (isPresent(result.errors)) {
      var errorString = result.errors.join("\n");
      throw new BaseException('''Template parse errors:
${ errorString}''');
    }
    return result.templateAst;
  }

  TemplateParseResult tryParse(
      CompileDirectiveMetadata component,
      String template,
      List<CompileDirectiveMetadata> directives,
      List<CompilePipeMetadata> pipes,
      String templateUrl) {
    var htmlAstWithErrors = this._htmlParser.parse(template, templateUrl);
    List<ParseError> errors = htmlAstWithErrors.errors;
    var result;
    if (htmlAstWithErrors.rootNodes.length > 0) {
      var uniqDirectives =
          (removeDuplicates(directives) as List<CompileDirectiveMetadata>);
      var uniqPipes = (removeDuplicates(pipes) as List<CompilePipeMetadata>);
      var providerViewContext = new ProviderViewContext(
          component, htmlAstWithErrors.rootNodes[0].sourceSpan);
      var parseVisitor = new TemplateParseVisitor(providerViewContext,
          uniqDirectives, uniqPipes, this._exprParser, this._schemaRegistry);
      result = htmlVisitAll(
          parseVisitor, htmlAstWithErrors.rootNodes, EMPTY_ELEMENT_CONTEXT);
      errors =
          (new List.from((new List.from(errors)..addAll(parseVisitor.errors)))
            ..addAll(providerViewContext.errors));
    } else {
      result = [];
    }
    if (errors.length > 0) {
      return new TemplateParseResult(result, errors);
    }
    if (isPresent(this.transforms)) {
      this.transforms.forEach((TemplateAstVisitor transform) {
        result = templateVisitAll(transform, result);
      });
    }
    return new TemplateParseResult(result);
  }
}

class TemplateParseVisitor implements HtmlAstVisitor {
  ProviderViewContext providerViewContext;
  Parser _exprParser;
  ElementSchemaRegistry _schemaRegistry;
  SelectorMatcher selectorMatcher;
  List<TemplateParseError> errors = [];
  var directivesIndex = new Map<CompileDirectiveMetadata, num>();
  num ngContentCount = 0;
  Map<String, CompilePipeMetadata> pipesByName;
  TemplateParseVisitor(
      this.providerViewContext,
      List<CompileDirectiveMetadata> directives,
      List<CompilePipeMetadata> pipes,
      this._exprParser,
      this._schemaRegistry) {
    this.selectorMatcher = new SelectorMatcher();
    ListWrapper.forEachWithIndex(directives,
        (CompileDirectiveMetadata directive, num index) {
      var selector = CssSelector.parse(directive.selector);
      this.selectorMatcher.addSelectables(selector, directive);
      this.directivesIndex[directive] = index;
    });
    this.pipesByName = new Map<String, CompilePipeMetadata>();
    pipes.forEach((pipe) => this.pipesByName[pipe.name] = pipe);
  }
  _reportError(String message, ParseSourceSpan sourceSpan) {
    this.errors.add(new TemplateParseError(message, sourceSpan));
  }

  ASTWithSource _parseInterpolation(String value, ParseSourceSpan sourceSpan) {
    var sourceInfo = sourceSpan.start.toString();
    try {
      var ast = this._exprParser.parseInterpolation(value, sourceInfo);
      this._checkPipes(ast, sourceSpan);
      if (isPresent(ast) &&
          ((ast.ast as Interpolation)).expressions.length >
              MAX_INTERPOLATION_VALUES) {
        throw new BaseException(
            '''Only support at most ${ MAX_INTERPOLATION_VALUES} interpolation values!''');
      }
      return ast;
    } catch (e, e_stack) {
      this._reportError('''${ e}''', sourceSpan);
      return this._exprParser.wrapLiteralPrimitive("ERROR", sourceInfo);
    }
  }

  ASTWithSource _parseAction(String value, ParseSourceSpan sourceSpan) {
    var sourceInfo = sourceSpan.start.toString();
    try {
      var ast = this._exprParser.parseAction(value, sourceInfo);
      this._checkPipes(ast, sourceSpan);
      return ast;
    } catch (e, e_stack) {
      this._reportError('''${ e}''', sourceSpan);
      return this._exprParser.wrapLiteralPrimitive("ERROR", sourceInfo);
    }
  }

  ASTWithSource _parseBinding(String value, ParseSourceSpan sourceSpan) {
    var sourceInfo = sourceSpan.start.toString();
    try {
      var ast = this._exprParser.parseBinding(value, sourceInfo);
      this._checkPipes(ast, sourceSpan);
      return ast;
    } catch (e, e_stack) {
      this._reportError('''${ e}''', sourceSpan);
      return this._exprParser.wrapLiteralPrimitive("ERROR", sourceInfo);
    }
  }

  List<TemplateBinding> _parseTemplateBindings(
      String value, ParseSourceSpan sourceSpan) {
    var sourceInfo = sourceSpan.start.toString();
    try {
      var bindings = this._exprParser.parseTemplateBindings(value, sourceInfo);
      bindings.forEach((binding) {
        if (isPresent(binding.expression)) {
          this._checkPipes(binding.expression, sourceSpan);
        }
      });
      return bindings;
    } catch (e, e_stack) {
      this._reportError('''${ e}''', sourceSpan);
      return [];
    }
  }

  _checkPipes(ASTWithSource ast, ParseSourceSpan sourceSpan) {
    if (isPresent(ast)) {
      var collector = new PipeCollector();
      ast.visit(collector);
      collector.pipes.forEach((pipeName) {
        if (!this.pipesByName.containsKey(pipeName)) {
          this._reportError(
              '''The pipe \'${ pipeName}\' could not be found''', sourceSpan);
        }
      });
    }
  }

  dynamic visitExpansion(HtmlExpansionAst ast, dynamic context) {
    return null;
  }

  dynamic visitExpansionCase(HtmlExpansionCaseAst ast, dynamic context) {
    return null;
  }

  dynamic visitText(HtmlTextAst ast, ElementContext parent) {
    var ngContentIndex = parent.findNgContentIndex(TEXT_CSS_SELECTOR);
    var expr = this._parseInterpolation(ast.value, ast.sourceSpan);
    if (isPresent(expr)) {
      return new BoundTextAst(expr, ngContentIndex, ast.sourceSpan);
    } else {
      return new TextAst(ast.value, ngContentIndex, ast.sourceSpan);
    }
  }

  dynamic visitAttr(HtmlAttrAst ast, dynamic contex) {
    return new AttrAst(ast.name, ast.value, ast.sourceSpan);
  }

  dynamic visitComment(HtmlCommentAst ast, dynamic context) {
    return null;
  }

  dynamic visitElement(HtmlElementAst element, ElementContext parent) {
    var nodeName = element.name;
    var preparsedElement = preparseElement(element);
    if (identical(preparsedElement.type, PreparsedElementType.SCRIPT) ||
        identical(preparsedElement.type, PreparsedElementType.STYLE)) {
      // Skipping <script> for security reasons

      // Skipping <style> as we already processed them

      // in the StyleCompiler
      return null;
    }
    if (identical(preparsedElement.type, PreparsedElementType.STYLESHEET) &&
        isStyleUrlResolvable(preparsedElement.hrefAttr)) {
      // Skipping stylesheets with either relative urls or package scheme as we already processed

      // them in the StyleCompiler
      return null;
    }
    List<List<String>> matchableAttrs = [];
    List<BoundElementOrDirectiveProperty> elementOrDirectiveProps = [];
    List<VariableAst> vars = [];
    List<BoundEventAst> events = [];
    List<BoundElementOrDirectiveProperty> templateElementOrDirectiveProps = [];
    List<VariableAst> templateVars = [];
    List<List<String>> templateMatchableAttrs = [];
    var hasInlineTemplates = false;
    var attrs = [];
    element.attrs.forEach((attr) {
      var hasBinding = this._parseAttr(
          attr, matchableAttrs, elementOrDirectiveProps, events, vars);
      var hasTemplateBinding = this._parseInlineTemplateBinding(
          attr,
          templateMatchableAttrs,
          templateElementOrDirectiveProps,
          templateVars);
      if (!hasBinding && !hasTemplateBinding) {
        // don't include the bindings as attributes as well in the AST
        attrs.add(this.visitAttr(attr, null));
        matchableAttrs.add([attr.name, attr.value]);
      }
      if (hasTemplateBinding) {
        hasInlineTemplates = true;
      }
    });
    var lcElName = splitNsName(nodeName.toLowerCase())[1];
    var isTemplateElement = lcElName == TEMPLATE_ELEMENT;
    var elementCssSelector = createElementCssSelector(nodeName, matchableAttrs);
    var directiveMetas =
        this._parseDirectives(this.selectorMatcher, elementCssSelector);
    var directiveAsts = this._createDirectiveAsts(
        element.name,
        directiveMetas,
        elementOrDirectiveProps,
        isTemplateElement ? [] : vars,
        element.sourceSpan);
    List<BoundElementPropertyAst> elementProps = this
        ._createElementPropertyAsts(
            element.name, elementOrDirectiveProps, directiveAsts);
    var isViewRoot = parent.isTemplateElement || hasInlineTemplates;
    var providerContext = new ProviderElementContext(
        this.providerViewContext,
        parent.providerContext,
        isViewRoot,
        directiveAsts,
        attrs,
        vars,
        element.sourceSpan);
    var children = htmlVisitAll(
        preparsedElement.nonBindable ? NON_BINDABLE_VISITOR : this,
        element.children,
        ElementContext.create(isTemplateElement, directiveAsts,
            isTemplateElement ? parent.providerContext : providerContext));
    providerContext.afterElement();
    // Override the actual selector when the `ngProjectAs` attribute is provided
    var projectionSelector = isPresent(preparsedElement.projectAs)
        ? CssSelector.parse(preparsedElement.projectAs)[0]
        : elementCssSelector;
    var ngContentIndex = parent.findNgContentIndex(projectionSelector);
    var parsedElement;
    if (identical(preparsedElement.type, PreparsedElementType.NG_CONTENT)) {
      if (isPresent(element.children) && element.children.length > 0) {
        this._reportError(
            '''<ng-content> element cannot have content. <ng-content> must be immediately followed by </ng-content>''',
            element.sourceSpan);
      }
      parsedElement = new NgContentAst(this.ngContentCount++,
          hasInlineTemplates ? null : ngContentIndex, element.sourceSpan);
    } else if (isTemplateElement) {
      this._assertAllEventsPublishedByDirectives(directiveAsts, events);
      this._assertNoComponentsNorElementBindingsOnTemplate(
          directiveAsts, elementProps, element.sourceSpan);
      parsedElement = new EmbeddedTemplateAst(
          attrs,
          events,
          vars,
          providerContext.transformedDirectiveAsts,
          providerContext.transformProviders,
          providerContext.transformedHasViewContainer,
          children,
          hasInlineTemplates ? null : ngContentIndex,
          element.sourceSpan);
    } else {
      this._assertOnlyOneComponent(directiveAsts, element.sourceSpan);
      var elementExportAsVars =
          vars.where((varAst) => identical(varAst.value.length, 0)).toList();
      var ngContentIndex = hasInlineTemplates
          ? null
          : parent.findNgContentIndex(projectionSelector);
      parsedElement = new ElementAst(
          nodeName,
          attrs,
          elementProps,
          events,
          elementExportAsVars,
          providerContext.transformedDirectiveAsts,
          providerContext.transformProviders,
          providerContext.transformedHasViewContainer,
          children,
          hasInlineTemplates ? null : ngContentIndex,
          element.sourceSpan);
    }
    if (hasInlineTemplates) {
      var templateCssSelector =
          createElementCssSelector(TEMPLATE_ELEMENT, templateMatchableAttrs);
      var templateDirectiveMetas =
          this._parseDirectives(this.selectorMatcher, templateCssSelector);
      var templateDirectiveAsts = this._createDirectiveAsts(
          element.name,
          templateDirectiveMetas,
          templateElementOrDirectiveProps,
          [],
          element.sourceSpan);
      List<BoundElementPropertyAst> templateElementProps = this
          ._createElementPropertyAsts(element.name,
              templateElementOrDirectiveProps, templateDirectiveAsts);
      this._assertNoComponentsNorElementBindingsOnTemplate(
          templateDirectiveAsts, templateElementProps, element.sourceSpan);
      var templateProviderContext = new ProviderElementContext(
          this.providerViewContext,
          parent.providerContext,
          parent.isTemplateElement,
          templateDirectiveAsts,
          [],
          templateVars,
          element.sourceSpan);
      templateProviderContext.afterElement();
      parsedElement = new EmbeddedTemplateAst(
          [],
          [],
          templateVars,
          templateProviderContext.transformedDirectiveAsts,
          templateProviderContext.transformProviders,
          templateProviderContext.transformedHasViewContainer,
          [parsedElement],
          ngContentIndex,
          element.sourceSpan);
    }
    return parsedElement;
  }

  bool _parseInlineTemplateBinding(
      HtmlAttrAst attr,
      List<List<String>> targetMatchableAttrs,
      List<BoundElementOrDirectiveProperty> targetProps,
      List<VariableAst> targetVars) {
    var templateBindingsSource = null;
    if (attr.name == TEMPLATE_ATTR) {
      templateBindingsSource = attr.value;
    } else if (attr.name.startsWith(TEMPLATE_ATTR_PREFIX)) {
      var key = attr.name.substring(TEMPLATE_ATTR_PREFIX.length);
      templateBindingsSource =
          (attr.value.length == 0) ? key : key + " " + attr.value;
    }
    if (isPresent(templateBindingsSource)) {
      var bindings =
          this._parseTemplateBindings(templateBindingsSource, attr.sourceSpan);
      for (var i = 0; i < bindings.length; i++) {
        var binding = bindings[i];
        if (binding.keyIsVar) {
          targetVars
              .add(new VariableAst(binding.key, binding.name, attr.sourceSpan));
          targetMatchableAttrs.add([binding.key, binding.name]);
        } else if (isPresent(binding.expression)) {
          this._parsePropertyAst(binding.key, binding.expression,
              attr.sourceSpan, targetMatchableAttrs, targetProps);
        } else {
          targetMatchableAttrs.add([binding.key, ""]);
          this._parseLiteralAttr(
              binding.key, null, attr.sourceSpan, targetProps);
        }
      }
      return true;
    }
    return false;
  }

  bool _parseAttr(
      HtmlAttrAst attr,
      List<List<String>> targetMatchableAttrs,
      List<BoundElementOrDirectiveProperty> targetProps,
      List<BoundEventAst> targetEvents,
      List<VariableAst> targetVars) {
    var attrName = this._normalizeAttributeName(attr.name);
    var attrValue = attr.value;
    var bindParts = RegExpWrapper.firstMatch(BIND_NAME_REGEXP, attrName);
    var hasBinding = false;
    if (isPresent(bindParts)) {
      hasBinding = true;
      if (isPresent(bindParts[1])) {
        this._parseProperty(bindParts[5], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetProps);
      } else if (isPresent(bindParts[2])) {
        var identifier = bindParts[5];
        this._parseVariable(identifier, attrValue, attr.sourceSpan, targetVars);
      } else if (isPresent(bindParts[3])) {
        this._parseEvent(bindParts[5], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetEvents);
      } else if (isPresent(bindParts[4])) {
        this._parseProperty(bindParts[5], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetProps);
        this._parseAssignmentEvent(bindParts[5], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetEvents);
      } else if (isPresent(bindParts[6])) {
        this._parseProperty(bindParts[6], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetProps);
        this._parseAssignmentEvent(bindParts[6], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetEvents);
      } else if (isPresent(bindParts[7])) {
        this._parseProperty(bindParts[7], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetProps);
      } else if (isPresent(bindParts[8])) {
        this._parseEvent(bindParts[8], attrValue, attr.sourceSpan,
            targetMatchableAttrs, targetEvents);
      }
    } else {
      hasBinding = this._parsePropertyInterpolation(attrName, attrValue,
          attr.sourceSpan, targetMatchableAttrs, targetProps);
    }
    if (!hasBinding) {
      this._parseLiteralAttr(attrName, attrValue, attr.sourceSpan, targetProps);
    }
    return hasBinding;
  }

  String _normalizeAttributeName(String attrName) {
    return attrName.toLowerCase().startsWith("data-")
        ? attrName.substring(5)
        : attrName;
  }

  _parseVariable(String identifier, String value, ParseSourceSpan sourceSpan,
      List<VariableAst> targetVars) {
    if (identifier.indexOf("-") > -1) {
      this._reportError('''"-" is not allowed in variable names''', sourceSpan);
    }
    targetVars.add(new VariableAst(identifier, value, sourceSpan));
  }

  _parseProperty(
      String name,
      String expression,
      ParseSourceSpan sourceSpan,
      List<List<String>> targetMatchableAttrs,
      List<BoundElementOrDirectiveProperty> targetProps) {
    this._parsePropertyAst(name, this._parseBinding(expression, sourceSpan),
        sourceSpan, targetMatchableAttrs, targetProps);
  }

  bool _parsePropertyInterpolation(
      String name,
      String value,
      ParseSourceSpan sourceSpan,
      List<List<String>> targetMatchableAttrs,
      List<BoundElementOrDirectiveProperty> targetProps) {
    var expr = this._parseInterpolation(value, sourceSpan);
    if (isPresent(expr)) {
      this._parsePropertyAst(
          name, expr, sourceSpan, targetMatchableAttrs, targetProps);
      return true;
    }
    return false;
  }

  _parsePropertyAst(
      String name,
      ASTWithSource ast,
      ParseSourceSpan sourceSpan,
      List<List<String>> targetMatchableAttrs,
      List<BoundElementOrDirectiveProperty> targetProps) {
    targetMatchableAttrs.add([name, ast.source]);
    targetProps
        .add(new BoundElementOrDirectiveProperty(name, ast, false, sourceSpan));
  }

  _parseAssignmentEvent(
      String name,
      String expression,
      ParseSourceSpan sourceSpan,
      List<List<String>> targetMatchableAttrs,
      List<BoundEventAst> targetEvents) {
    this._parseEvent('''${ name}Change''', '''${ expression}=\$event''',
        sourceSpan, targetMatchableAttrs, targetEvents);
  }

  _parseEvent(
      String name,
      String expression,
      ParseSourceSpan sourceSpan,
      List<List<String>> targetMatchableAttrs,
      List<BoundEventAst> targetEvents) {
    // long format: 'target: eventName'
    var parts = splitAtColon(name, [null, name]);
    var target = parts[0];
    var eventName = parts[1];
    var ast = this._parseAction(expression, sourceSpan);
    targetMatchableAttrs.add([name, ast.source]);
    targetEvents.add(new BoundEventAst(eventName, target, ast, sourceSpan));
  }

  _parseLiteralAttr(String name, String value, ParseSourceSpan sourceSpan,
      List<BoundElementOrDirectiveProperty> targetProps) {
    targetProps.add(new BoundElementOrDirectiveProperty(name,
        this._exprParser.wrapLiteralPrimitive(value, ""), true, sourceSpan));
  }

  List<CompileDirectiveMetadata> _parseDirectives(
      SelectorMatcher selectorMatcher, CssSelector elementCssSelector) {
    var directives = [];
    selectorMatcher.match(elementCssSelector, (selector, directive) {
      directives.add(directive);
    });
    // Need to sort the directives so that we get consistent results throughout,

    // as selectorMatcher uses Maps inside.

    // Also need to make components the first directive in the array
    ListWrapper.sort(directives,
        (CompileDirectiveMetadata dir1, CompileDirectiveMetadata dir2) {
      var dir1Comp = dir1.isComponent;
      var dir2Comp = dir2.isComponent;
      if (dir1Comp && !dir2Comp) {
        return -1;
      } else if (!dir1Comp && dir2Comp) {
        return 1;
      } else {
        return this.directivesIndex[dir1] - this.directivesIndex[dir2];
      }
    });
    return directives;
  }

  List<DirectiveAst> _createDirectiveAsts(
      String elementName,
      List<CompileDirectiveMetadata> directives,
      List<BoundElementOrDirectiveProperty> props,
      List<VariableAst> possibleExportAsVars,
      ParseSourceSpan sourceSpan) {
    var matchedVariables = new Set<String>();
    var directiveAsts = directives.map((CompileDirectiveMetadata directive) {
      List<BoundElementPropertyAst> hostProperties = [];
      List<BoundEventAst> hostEvents = [];
      List<BoundDirectivePropertyAst> directiveProperties = [];
      this._createDirectiveHostPropertyAsts(
          elementName, directive.hostProperties, sourceSpan, hostProperties);
      this._createDirectiveHostEventAsts(
          directive.hostListeners, sourceSpan, hostEvents);
      this._createDirectivePropertyAsts(
          directive.inputs, props, directiveProperties);
      var exportAsVars = [];
      possibleExportAsVars.forEach((varAst) {
        if ((identical(varAst.value.length, 0) && directive.isComponent) ||
            (directive.exportAs == varAst.value)) {
          exportAsVars.add(varAst);
          matchedVariables.add(varAst.name);
        }
      });
      return new DirectiveAst(directive, directiveProperties, hostProperties,
          hostEvents, exportAsVars, sourceSpan);
    }).toList();
    possibleExportAsVars.forEach((varAst) {
      if (varAst.value.length > 0 &&
          !SetWrapper.has(matchedVariables, varAst.name)) {
        this._reportError(
            '''There is no directive with "exportAs" set to "${ varAst . value}"''',
            varAst.sourceSpan);
      }
    });
    return directiveAsts;
  }

  _createDirectiveHostPropertyAsts(
      String elementName,
      Map<String, String> hostProps,
      ParseSourceSpan sourceSpan,
      List<BoundElementPropertyAst> targetPropertyAsts) {
    if (isPresent(hostProps)) {
      StringMapWrapper.forEach(hostProps, (String expression, String propName) {
        var exprAst = this._parseBinding(expression, sourceSpan);
        targetPropertyAsts.add(this._createElementPropertyAst(
            elementName, propName, exprAst, sourceSpan));
      });
    }
  }

  _createDirectiveHostEventAsts(Map<String, String> hostListeners,
      ParseSourceSpan sourceSpan, List<BoundEventAst> targetEventAsts) {
    if (isPresent(hostListeners)) {
      StringMapWrapper.forEach(hostListeners,
          (String expression, String propName) {
        this._parseEvent(propName, expression, sourceSpan, [], targetEventAsts);
      });
    }
  }

  _createDirectivePropertyAsts(
      Map<String, String> directiveProperties,
      List<BoundElementOrDirectiveProperty> boundProps,
      List<BoundDirectivePropertyAst> targetBoundDirectiveProps) {
    if (isPresent(directiveProperties)) {
      var boundPropsByName = new Map<String, BoundElementOrDirectiveProperty>();
      boundProps.forEach((boundProp) {
        var prevValue = boundPropsByName[boundProp.name];
        if (isBlank(prevValue) || prevValue.isLiteral) {
          // give [a]="b" a higher precedence than a="b" on the same element
          boundPropsByName[boundProp.name] = boundProp;
        }
      });
      StringMapWrapper.forEach(directiveProperties,
          (String elProp, String dirProp) {
        var boundProp = boundPropsByName[elProp];
        // Bindings are optional, so this binding only needs to be set up if an expression is given.
        if (isPresent(boundProp)) {
          targetBoundDirectiveProps.add(new BoundDirectivePropertyAst(dirProp,
              boundProp.name, boundProp.expression, boundProp.sourceSpan));
        }
      });
    }
  }

  List<BoundElementPropertyAst> _createElementPropertyAsts(
      String elementName,
      List<BoundElementOrDirectiveProperty> props,
      List<DirectiveAst> directives) {
    List<BoundElementPropertyAst> boundElementProps = [];
    var boundDirectivePropsIndex = new Map<String, BoundDirectivePropertyAst>();
    directives.forEach((DirectiveAst directive) {
      directive.inputs.forEach((BoundDirectivePropertyAst prop) {
        boundDirectivePropsIndex[prop.templateName] = prop;
      });
    });
    props.forEach((BoundElementOrDirectiveProperty prop) {
      if (!prop.isLiteral && isBlank(boundDirectivePropsIndex[prop.name])) {
        boundElementProps.add(this._createElementPropertyAst(
            elementName, prop.name, prop.expression, prop.sourceSpan));
      }
    });
    return boundElementProps;
  }

  BoundElementPropertyAst _createElementPropertyAst(
      String elementName, String name, AST ast, ParseSourceSpan sourceSpan) {
    var unit = null;
    var bindingType;
    var boundPropertyName;
    var parts = name.split(PROPERTY_PARTS_SEPARATOR);
    if (identical(parts.length, 1)) {
      boundPropertyName = this._schemaRegistry.getMappedPropName(parts[0]);
      bindingType = PropertyBindingType.Property;
      if (!this._schemaRegistry.hasProperty(elementName, boundPropertyName)) {
        this._reportError(
            '''Can\'t bind to \'${ boundPropertyName}\' since it isn\'t a known native property''',
            sourceSpan);
      }
    } else {
      if (parts[0] == ATTRIBUTE_PREFIX) {
        boundPropertyName = parts[1];
        var nsSeparatorIdx = boundPropertyName.indexOf(":");
        if (nsSeparatorIdx > -1) {
          var ns = boundPropertyName.substring(0, nsSeparatorIdx);
          var name = boundPropertyName.substring(nsSeparatorIdx + 1);
          boundPropertyName = mergeNsAndName(ns, name);
        }
        bindingType = PropertyBindingType.Attribute;
      } else if (parts[0] == CLASS_PREFIX) {
        boundPropertyName = parts[1];
        bindingType = PropertyBindingType.Class;
      } else if (parts[0] == STYLE_PREFIX) {
        unit = parts.length > 2 ? parts[2] : null;
        boundPropertyName = parts[1];
        bindingType = PropertyBindingType.Style;
      } else {
        this._reportError('''Invalid property name \'${ name}\'''', sourceSpan);
        bindingType = null;
      }
    }
    return new BoundElementPropertyAst(
        boundPropertyName, bindingType, ast, unit, sourceSpan);
  }

  List<String> _findComponentDirectiveNames(List<DirectiveAst> directives) {
    List<String> componentTypeNames = [];
    directives.forEach((directive) {
      var typeName = directive.directive.type.name;
      if (directive.directive.isComponent) {
        componentTypeNames.add(typeName);
      }
    });
    return componentTypeNames;
  }

  _assertOnlyOneComponent(
      List<DirectiveAst> directives, ParseSourceSpan sourceSpan) {
    var componentTypeNames = this._findComponentDirectiveNames(directives);
    if (componentTypeNames.length > 1) {
      this._reportError(
          '''More than one component: ${ componentTypeNames . join ( "," )}''',
          sourceSpan);
    }
  }

  _assertNoComponentsNorElementBindingsOnTemplate(List<DirectiveAst> directives,
      List<BoundElementPropertyAst> elementProps, ParseSourceSpan sourceSpan) {
    List<String> componentTypeNames =
        this._findComponentDirectiveNames(directives);
    if (componentTypeNames.length > 0) {
      this._reportError(
          '''Components on an embedded template: ${ componentTypeNames . join ( "," )}''',
          sourceSpan);
    }
    elementProps.forEach((prop) {
      this._reportError(
          '''Property binding ${ prop . name} not used by any directive on an embedded template''',
          sourceSpan);
    });
  }

  _assertAllEventsPublishedByDirectives(
      List<DirectiveAst> directives, List<BoundEventAst> events) {
    var allDirectiveEvents = new Set<String>();
    directives.forEach((directive) {
      StringMapWrapper.forEach(directive.directive.outputs,
          (String eventName, _) {
        allDirectiveEvents.add(eventName);
      });
    });
    events.forEach((event) {
      if (isPresent(event.target) ||
          !SetWrapper.has(allDirectiveEvents, event.name)) {
        this._reportError(
            '''Event binding ${ event . fullName} not emitted by any directive on an embedded template''',
            event.sourceSpan);
      }
    });
  }
}

class NonBindableVisitor implements HtmlAstVisitor {
  ElementAst visitElement(HtmlElementAst ast, ElementContext parent) {
    var preparsedElement = preparseElement(ast);
    if (identical(preparsedElement.type, PreparsedElementType.SCRIPT) ||
        identical(preparsedElement.type, PreparsedElementType.STYLE) ||
        identical(preparsedElement.type, PreparsedElementType.STYLESHEET)) {
      // Skipping <script> for security reasons

      // Skipping <style> and stylesheets as we already processed them

      // in the StyleCompiler
      return null;
    }
    var attrNameAndValues =
        ast.attrs.map((attrAst) => [attrAst.name, attrAst.value]).toList();
    var selector = createElementCssSelector(ast.name, attrNameAndValues);
    var ngContentIndex = parent.findNgContentIndex(selector);
    var children = htmlVisitAll(this, ast.children, EMPTY_ELEMENT_CONTEXT);
    return new ElementAst(ast.name, htmlVisitAll(this, ast.attrs), [], [], [],
        [], [], false, children, ngContentIndex, ast.sourceSpan);
  }

  dynamic visitComment(HtmlCommentAst ast, dynamic context) {
    return null;
  }

  AttrAst visitAttr(HtmlAttrAst ast, dynamic context) {
    return new AttrAst(ast.name, ast.value, ast.sourceSpan);
  }

  TextAst visitText(HtmlTextAst ast, ElementContext parent) {
    var ngContentIndex = parent.findNgContentIndex(TEXT_CSS_SELECTOR);
    return new TextAst(ast.value, ngContentIndex, ast.sourceSpan);
  }

  dynamic visitExpansion(HtmlExpansionAst ast, dynamic context) {
    return ast;
  }

  dynamic visitExpansionCase(HtmlExpansionCaseAst ast, dynamic context) {
    return ast;
  }
}

class BoundElementOrDirectiveProperty {
  String name;
  AST expression;
  bool isLiteral;
  ParseSourceSpan sourceSpan;
  BoundElementOrDirectiveProperty(
      this.name, this.expression, this.isLiteral, this.sourceSpan) {}
}

List<String> splitClasses(String classAttrValue) {
  return StringWrapper.split(classAttrValue.trim(), new RegExp(r'\s+'));
}

class ElementContext {
  bool isTemplateElement;
  SelectorMatcher _ngContentIndexMatcher;
  num _wildcardNgContentIndex;
  ProviderElementContext providerContext;
  static ElementContext create(bool isTemplateElement,
      List<DirectiveAst> directives, ProviderElementContext providerContext) {
    var matcher = new SelectorMatcher();
    var wildcardNgContentIndex = null;
    var component = directives.firstWhere(
        (directive) => directive.directive.isComponent,
        orElse: () => null);
    if (isPresent(component)) {
      var ngContentSelectors = component.directive.template.ngContentSelectors;
      for (var i = 0; i < ngContentSelectors.length; i++) {
        var selector = ngContentSelectors[i];
        if (StringWrapper.equals(selector, "*")) {
          wildcardNgContentIndex = i;
        } else {
          matcher.addSelectables(CssSelector.parse(ngContentSelectors[i]), i);
        }
      }
    }
    return new ElementContext(
        isTemplateElement, matcher, wildcardNgContentIndex, providerContext);
  }

  ElementContext(this.isTemplateElement, this._ngContentIndexMatcher,
      this._wildcardNgContentIndex, this.providerContext) {}
  num findNgContentIndex(CssSelector selector) {
    var ngContentIndices = [];
    this._ngContentIndexMatcher.match(selector, (selector, ngContentIndex) {
      ngContentIndices.add(ngContentIndex);
    });
    ListWrapper.sort(ngContentIndices);
    if (isPresent(this._wildcardNgContentIndex)) {
      ngContentIndices.add(this._wildcardNgContentIndex);
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
    cssSelector.addAttribute(attrNameNoNs, attrValue);
    if (attrName.toLowerCase() == CLASS_ATTR) {
      var classes = splitClasses(attrValue);
      classes.forEach((className) => cssSelector.addClassName(className));
    }
  }
  return cssSelector;
}

var EMPTY_ELEMENT_CONTEXT =
    new ElementContext(true, new SelectorMatcher(), null, null);
var NON_BINDABLE_VISITOR = new NonBindableVisitor();

class PipeCollector extends RecursiveAstVisitor {
  Set<String> pipes = new Set<String>();
  dynamic visitPipe(BindingPipe ast, dynamic context) {
    this.pipes.add(ast.name);
    ast.exp.visit(this);
    this.visitAll(ast.args, context);
    return null;
  }
}

List<CompileMetadataWithType> removeDuplicates(
    List<CompileMetadataWithType> items) {
  var res = [];
  items.forEach((item) {
    var hasMatch = res
            .where((r) =>
                r.type.name == item.type.name &&
                r.type.moduleUrl == item.type.moduleUrl &&
                r.type.runtime == item.type.runtime)
            .toList()
            .length >
        0;
    if (!hasMatch) {
      res.add(item);
    }
  });
  return res;
}
