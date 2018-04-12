import 'package:angular/src/facade/lang.dart' show jsSplit;
import 'package:source_span/source_span.dart';

import '../core/security.dart';
import 'compile_metadata.dart'
    show CompileDirectiveMetadata, CompilePipeMetadata;
import 'expression_parser/ast.dart' show AST;
import 'expression_parser/ast.dart';
import 'html_tags.dart' show splitNsName, mergeNsAndName;
import 'parse_util.dart' show ParseError, ParseErrorLevel;
import 'schema/element_schema_registry.dart' show ElementSchemaRegistry;
import 'selector.dart' show CssSelector;
import 'template_ast.dart'
    show BoundElementPropertyAst, PropertyBindingType, TemplateAst;

const _classAttribute = 'class';
const _propertyPartsSeparator = '.';
const _attributePrefix = 'attr';
const _classPrefix = 'class';
const _stylePrefix = 'style';

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
  var parts = name.split(_propertyPartsSeparator);
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
    if (parts[0] == _attributePrefix) {
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
    } else if (parts[0] == _classPrefix) {
      boundPropertyName = parts[1];
      bindingType = PropertyBindingType.Class;
      securityContext = TemplateSecurityContext.none;
    } else if (parts[0] == _stylePrefix) {
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

List<String> _splitClasses(String classAttrValue) {
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
    if (attrName.toLowerCase() == _classAttribute) {
      var classes = _splitClasses(attrValue);
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
