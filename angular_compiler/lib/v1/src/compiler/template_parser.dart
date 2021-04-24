import 'package:source_span/source_span.dart';
import 'package:angular_compiler/v1/src/compiler/js_split_facade.dart';
import 'package:angular_compiler/v2/context.dart';

import 'compile_metadata.dart'
    show
        CompileDirectiveMetadata,
        CompileIdentifierMetadata,
        CompilePipeMetadata;
import 'expression_parser/parser.dart' show ExpressionParser;
import 'schema/element_schema_registry.dart' show ElementSchemaRegistry;
import 'security.dart';
import 'selector.dart' show CssSelector;
import 'template_ast.dart'
    show BoundElementPropertyAst, BoundValue, PropertyBindingType;

const _classAttribute = 'class';
const _propertyPartsSeparator = '.';
const _attributePrefix = 'attr';
const _classPrefix = 'class';
const _stylePrefix = 'style';

class TemplateContext {
  final ExpressionParser parser;
  final ElementSchemaRegistry schemaRegistry;
  final CompileDirectiveMetadata component;
  final List<CompileDirectiveMetadata> directives;

  TemplateContext({
    required this.parser,
    required this.schemaRegistry,
    required this.component,
    required this.directives,
  });

  List<CompileIdentifierMetadata> get exports => component.exports;
}

BoundElementPropertyAst createElementPropertyAst(
  String elementName,
  String name,
  BoundValue value,
  SourceSpan sourceSpan,
  ElementSchemaRegistry schemaRegistry,
) {
  String? unit;
  String? namespace;
  PropertyBindingType? bindingType;
  String? boundPropertyName;
  TemplateSecurityContext? securityContext;
  var parts = name.split(_propertyPartsSeparator);
  if (identical(parts.length, 1)) {
    boundPropertyName = schemaRegistry.getMappedPropName(parts[0]);
    securityContext =
        schemaRegistry.securityContext(elementName, boundPropertyName);
    bindingType = PropertyBindingType.property;
    if (!schemaRegistry.hasProperty(elementName, boundPropertyName)) {
      if (boundPropertyName == 'ngclass') {
        CompileContext.current.reportAndRecover(BuildError.forSourceSpan(
          sourceSpan,
          'Please use camel-case ngClass instead of ngclass in your template',
        ));
      } else {
        CompileContext.current.reportAndRecover(BuildError.forSourceSpan(
          sourceSpan,
          "Can't bind to '$boundPropertyName' since it isn't a known "
          'native property or known directive. Please fix typo or add to '
          'directives list.',
        ));
      }
    }
  } else {
    if (parts[0] == _attributePrefix) {
      boundPropertyName = parts[1];
      if (boundPropertyName.toLowerCase().startsWith('on')) {
        CompileContext.current.reportAndRecover(BuildError.forSourceSpan(
          sourceSpan,
          'Binding to event attribute \'$boundPropertyName\' '
          'is disallowed for security reasons, please use '
          '(${boundPropertyName.substring(2)})=...',
        ));
      }
      unit = parts.length > 2 ? parts[2] : null;
      if (unit != null && unit != 'if') {
        CompileContext.current.reportAndRecover(BuildError.forSourceSpan(
          sourceSpan,
          'Invalid attribute unit "$unit"',
        ));
      }
      // NB: For security purposes, use the mapped property name, not the
      // attribute name.
      securityContext = schemaRegistry.securityContext(
          elementName, schemaRegistry.getMappedPropName(boundPropertyName));
      var nsSeparatorIdx = boundPropertyName.indexOf(':');
      if (nsSeparatorIdx > -1) {
        namespace = boundPropertyName.substring(0, nsSeparatorIdx);
        boundPropertyName = boundPropertyName.substring(nsSeparatorIdx + 1);
      }
      bindingType = PropertyBindingType.attribute;
    } else if (parts[0] == _classPrefix) {
      boundPropertyName = parts[1];
      bindingType = PropertyBindingType.cssClass;
      securityContext = TemplateSecurityContext.none;
    } else if (parts[0] == _stylePrefix) {
      unit = parts.length > 2 ? parts[2] : null;
      boundPropertyName = parts[1];
      bindingType = PropertyBindingType.style;
      securityContext = TemplateSecurityContext.style;
    } else {
      // Throw an error, otherwise it builds a BoundElementPropertyAst with null
      // fields that will result in a crash when trying to transform this Ast
      // node to an IR node.
      CompileContext.current.reportAndRecover(BuildError.forSourceSpan(
        sourceSpan,
        "Invalid property name '$name'",
      ));
      bindingType = null;
      securityContext = null;
    }
  }
  return BoundElementPropertyAst(
    namespace,
    boundPropertyName,
    bindingType,
    securityContext,
    value,
    unit,
    sourceSpan,
  );
}

List<String> _splitClasses(String classAttrValue) {
  return jsSplit(classAttrValue.trim(), RegExp(r'\s+'));
}

CssSelector createElementCssSelector(
    String elementName, List<List<String?>> matchableAttrs) {
  var cssSelector = CssSelector();
  var elNameNoNs = _splitNsName(elementName)[1];
  cssSelector.setElement(elNameNoNs);
  for (var i = 0; i < matchableAttrs.length; i++) {
    var attrName = matchableAttrs[i][0]!;
    var attrNameNoNs = _splitNsName(attrName)[1]!;
    var attrValue = matchableAttrs[i][1];
    // [CssSelector] is used both to define selectors, and to describe an
    // element. This is unfortunate as certain attribute selectors don't make
    // sense in context of defining an element. Since we're defining the
    // attributes of an element here, we use exact match ('=') to specify that
    // the element has this attribute value.
    cssSelector.addAttribute(attrNameNoNs, '=', attrValue);
    if (attrName.toLowerCase() == _classAttribute && attrValue != null) {
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
        var itemMeta = item as CompilePipeMetadata;
        return rMeta.type!.name == itemMeta.type!.name &&
            rMeta.type!.moduleUrl == itemMeta.type!.moduleUrl;
      } else if (r is CompileDirectiveMetadata) {
        CompileDirectiveMetadata rMeta = r;
        var itemMeta = item as CompileDirectiveMetadata;
        return rMeta.type!.name == itemMeta.type!.name &&
            rMeta.type!.moduleUrl == itemMeta.type!.moduleUrl;
      } else {
        throw ArgumentError();
      }
    }).isNotEmpty;
    if (!hasMatch) {
      res.add(item);
    }
  }
  return res;
}

String mergeNsAndName(String? prefix, String localName) {
  if (prefix == null) return localName;
  // At least one part is empty, this is not a valid namespaced token.
  if (prefix == '' || localName == '') return '$prefix:$localName';
  return '@$prefix:$localName';
}

final _nsPrefixRegExp = RegExp(r'^@([^:]+):(.+)');
List<String?> _splitNsName(String elementName) {
  if (elementName[0] != '@') {
    return [null, elementName];
  }
  var match = _nsPrefixRegExp.firstMatch(elementName)!;
  return [match[1], match[2]];
}
