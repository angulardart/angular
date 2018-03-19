import 'package:source_span/source_span.dart';
import 'package:angular/src/facade/exceptions.dart' show BaseException;
import 'package:angular/src/facade/lang.dart' show jsSplit;

import '../core/security.dart';
import 'compile_metadata.dart'
    show CompileDirectiveMetadata, CompilePipeMetadata;
import 'expression_parser/ast.dart' show AST;
import 'expression_parser/ast.dart';
import 'html_tags.dart' show splitNsName, mergeNsAndName;
import 'logging.dart' show logger;
import 'parse_util.dart' show ParseError, ParseErrorLevel;
import 'schema/element_schema_registry.dart' show ElementSchemaRegistry;
import 'selector.dart' show CssSelector;
import 'template_ast.dart'
    show BoundElementPropertyAst, PropertyBindingType, TemplateAst;

// TODO: Remove the following lines (for --no-implicit-casts).
// ignore_for_file: argument_type_not_assignable
// ignore_for_file: invalid_assignment
// ignore_for_file: list_element_type_not_assignable
// ignore_for_file: non_bool_operand
// ignore_for_file: return_of_invalid_type

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
abstract class TemplateParser {
  ElementSchemaRegistry get schemaRegistry;

  List<TemplateAst> parse(
      CompileDirectiveMetadata compMeta,
      String template,
      List<CompileDirectiveMetadata> directives,
      List<CompilePipeMetadata> pipes,
      String name);
}

void handleParseErrors(List<ParseError> parseErrors) {
  var warnings = <ParseError>[];
  var errors = <ParseError>[];
  for (ParseError error in parseErrors) {
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
  String unit;
  PropertyBindingType bindingType;
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

List<String> splitClasses(String classAttrValue) {
  return jsSplit(classAttrValue.trim(), (new RegExp(r'\s+')));
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
