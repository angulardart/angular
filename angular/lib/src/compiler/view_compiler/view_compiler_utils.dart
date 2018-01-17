import 'package:angular/src/core/linker/view_type.dart';
import 'package:angular/src/facade/exceptions.dart' show BaseException;
import 'package:angular/src/core/app_view_consts.dart' show namespaceUris;

import '../compile_metadata.dart'
    show
        CompileTokenMetadata,
        CompileDirectiveMetadata,
        CompileIdentifierMetadata;
import '../identifiers.dart';
import '../output/output_ast.dart' as o;
import '../template_ast.dart' show AttrAst, TemplateAst;
import 'compile_view.dart' show CompileView;
import 'constants.dart';

/// Creating outlines for faster builds is preventing auto input change
/// detection for now. The following flag should be removed to reenable in the
/// future.
const bool outlinerDeprecated = false;

/// Variable name used to read viewData.parentIndex in build functions.
const String cachedParentIndexVarName = 'parentIdx';

/// Component dependency and associated identifier.
class ViewCompileDependency {
  CompileDirectiveMetadata comp;
  CompileIdentifierMetadata factoryPlaceholder;
  ViewCompileDependency(this.comp, this.factoryPlaceholder);
}

// Creates method parameters list for AppView set attribute calls.
List<o.Expression> createSetAttributeParams(o.Expression renderNode,
    String attrNs, String attrName, o.Expression valueExpr) {
  if (attrNs != null) {
    return [renderNode, o.literal(attrNs), o.literal(attrName), valueExpr];
  } else {
    return [renderNode, o.literal(attrName), valueExpr];
  }
}

o.Expression getPropertyInView(
    o.Expression property, CompileView callingView, CompileView definedView,
    {bool forceCast: false}) {
  if (identical(callingView, definedView)) {
    return property;
  } else {
    o.Expression viewProp;
    CompileView currView = callingView;
    while (!identical(currView, definedView) &&
        currView.declarationElement.view != null) {
      currView = currView.declarationElement.view;
      viewProp = viewProp == null
          ? new o.ReadClassMemberExpr('parentView')
          : viewProp.prop('parentView');
    }
    if (!identical(currView, definedView)) {
      throw new BaseException('Internal error: Could not calculate a property '
          'in a parent view: $property');
    }

    o.ReadClassMemberExpr readMemberExpr = unwrapDirective(property);

    if (readMemberExpr != null) {
      // Note: Don't cast for members of the AppView base class...
      if (definedView.nameResolver.fields
              .any((field) => field.name == readMemberExpr.name) ||
          definedView.getters
              .any((field) => field.name == readMemberExpr.name)) {
        viewProp = viewProp.cast(definedView.classType);
      }
    } else if (forceCast) {
      viewProp = viewProp.cast(definedView.classType);
    }
    return o.replaceReadClassMemberInExpression(viewProp, property);
  }
}

o.Expression injectFromViewParentInjector(
    CompileView view, CompileTokenMetadata token, bool optional) {
  o.Expression viewExpr = (view.viewType == ViewType.HOST)
      ? o.THIS_EXPR
      : new o.ReadClassMemberExpr('parentView');
  var args = [
    createDiTokenExpression(token),
    new o.ReadClassMemberExpr('viewData').prop('parentIndex')
  ];
  if (optional) {
    args.add(o.NULL_EXPR);
  }
  return viewExpr.callMethod('injectorGet', args);
}

String getViewFactoryName(CompileDirectiveMetadata component,
    [int embeddedTemplateIndex]) {
  String indexPostFix =
      embeddedTemplateIndex == null ? '' : embeddedTemplateIndex.toString();
  return 'viewFactory_${component.type.name}$indexPostFix';
}

o.Expression createDiTokenExpression(CompileTokenMetadata token) {
  if (token.identifierIsInstance) {
    return o.importExpr(token.identifier).instantiate(
        // If there is also a value, assume it is the first argument.
        //
        // i.e. const OpaqueToken('literalValue')
        token.value != null ? [o.literal(token.value)] : const <o.Expression>[],
        o.importType(token.identifier, [], [o.TypeModifier.Const]),
        // Add any generic types attached to the type.
        //
        // Only a value of `null` precisely means "no generic types", not [].
        token.identifier.genericTypes.isNotEmpty
            ? token.identifier.genericTypes
            : null);
  } else if (token.value != null) {
    return o.literal(token.value);
  } else {
    return o.importExpr(token.identifier);
  }
}

o.Expression createDebugInfoTokenExpression(CompileTokenMetadata token) {
  if (token.value != null) {
    return o.literal(token.value);
  } else if (token.identifierIsInstance) {
    return o
        .importExpr(token.identifier)
        .instantiate([], o.importType(token.identifier, []));
  } else {
    return o.importExpr(token.identifier);
  }
}

o.Expression createFlatArray(List<o.Expression> expressions) {
  // Simplify: No items.
  if (expressions.isEmpty) {
    return o.literalArr(
      const [],
      new o.ArrayType(null, const [o.TypeModifier.Const]),
    );
  }
  // Check for [].addAll([x,y,z]) case and optimize.
  if (expressions.length == 1) {
    if (expressions[0].type is o.ArrayType) {
      return expressions[0];
    } else {
      return o.literalArr([expressions[0]]);
    }
  }
  var lastNonArrayExpressions = <o.Expression>[];
  o.Expression result = o.literalArr([]);
  bool initialEmptyArray = true;
  for (var i = 0; i < expressions.length; i++) {
    var expr = expressions[i];
    if (expr.type is o.ArrayType) {
      if (lastNonArrayExpressions.length > 0) {
        if (initialEmptyArray) {
          result = o.literalArr(lastNonArrayExpressions, o.DYNAMIC_TYPE);
          initialEmptyArray = false;
        } else {
          result = result.callMethod(o.BuiltinMethod.ConcatArray,
              [o.literalArr(lastNonArrayExpressions)]);
        }
        lastNonArrayExpressions = [];
      }
      result = initialEmptyArray
          ? o.literalArr([expr], o.DYNAMIC_TYPE)
          : result.callMethod(o.BuiltinMethod.ConcatArray, [expr]);
      initialEmptyArray = false;
    } else {
      lastNonArrayExpressions.add(expr);
    }
  }
  if (lastNonArrayExpressions.length > 0) {
    if (initialEmptyArray) {
      result = o.literalArr(lastNonArrayExpressions);
    } else {
      result = result.callMethod(
          o.BuiltinMethod.ConcatArray, [o.literalArr(lastNonArrayExpressions)]);
    }
  }
  return result;
}

/// Converts a reference, literal or existing expression to provider value.
o.Expression convertValueToOutputAst(dynamic value) {
  if (value is CompileIdentifierMetadata) {
    return o.importExpr(value);
  } else if (value is CompileTokenMetadata) {
    return createDiTokenExpression(value);
  } else if (value is o.Expression) {
    return value;
  } else {
    return o.literal(value);
  }
}

CompileDirectiveMetadata componentFromDirectives(
    List<CompileDirectiveMetadata> directives) {
  for (CompileDirectiveMetadata directive in directives) {
    if (directive.isComponent) return directive;
  }
  return null;
}

// Detect _PopupSourceDirective_0_6.instance for directives that have
// change detectors and unwrap to change detector.
o.Expression unwrapDirectiveInstance(o.Expression directiveInstance) {
  if (directiveInstance is o.ReadPropExpr &&
      directiveInstance.name == 'instance' &&
      (directiveInstance.receiver is o.ReadClassMemberExpr ||
          directiveInstance.receiver is o.ReadPropExpr)) {
    return directiveInstance.receiver;
  }
  return null;
}

// Return instance of directive for both regular directives and directives
// with ChangeDetector class.
o.Expression unwrapDirective(o.Expression directiveInstance) {
  var instance = unwrapDirectiveInstance(directiveInstance);
  if (instance != null) {
    return instance;
  } else if (directiveInstance is o.ReadClassMemberExpr) {
    // Non change detector directive read.
    return directiveInstance;
  }
  return null;
}

String toTemplateExtension(String moduleUrl) {
  if (!moduleUrl.endsWith('.dart')) return moduleUrl;
  return moduleUrl.substring(0, moduleUrl.length - 5) + '.template.dart';
}

Map<String, String> astAttribListToMap(List<AttrAst> attrs) {
  Map<String, String> htmlAttrs = {};
  for (AttrAst attr in attrs) {
    htmlAttrs[attr.name] = attr.value;
  }
  return htmlAttrs;
}

String mergeAttributeValue(
    String attrName, String attrValue1, String attrValue2) {
  if (attrName == classAttrName || attrName == styleAttrName) {
    return '$attrValue1 $attrValue2';
  } else {
    return attrValue2;
  }
}

o.Statement createSetAttributeStatement(String astNodeName,
    o.Expression renderNode, String attrName, String attrValue) {
  var attrNs;
  if (attrName.startsWith('@') && attrName.contains(':')) {
    var nameParts = attrName.substring(1).split(':');
    attrNs = namespaceUris[nameParts[0]];
    attrName = nameParts[1];
  }

  /// Optimization for common attributes. Call dart:html directly without
  /// going through setAttr wrapper.
  if (attrNs == null) {
    switch (attrName) {
      case 'class':
        // Remove check below after SVGSVGElement DDC bug is fixed b2/32931607
        bool hasNamespace =
            astNodeName.startsWith('@') || astNodeName.contains(':');
        if (!hasNamespace) {
          return renderNode
              .prop('className')
              .set(o.literal(attrValue))
              .toStmt();
        }
        break;
      case 'tabindex':
        try {
          int tabValue = int.parse(attrValue);
          return renderNode.prop('tabIndex').set(o.literal(tabValue)).toStmt();
        } catch (_) {
          // fallthrough to default handler since index is not int.
        }
        break;
      default:
        break;
    }
  }
  var params = createSetAttributeParams(
      renderNode, attrNs, attrName, o.literal(attrValue));
  return new o.InvokeMemberMethodExpr(
          attrNs == null ? "createAttr" : "setAttrNS", params)
      .toStmt();
}

List<List<String>> mapToKeyValueArray(Map<String, String> data) {
  var entryArray = <List<String>>[];
  data.forEach((String name, String value) {
    entryArray.add([name, value]);
  });
  // We need to sort to get a defined output order
  // for tests and for caching generated artifacts...
  entryArray.sort((entry1, entry2) => entry1[0].compareTo(entry2[0]));
  var keyValueArray = <List<String>>[];
  for (var entry in entryArray) {
    keyValueArray.add([entry[0], entry[1]]);
  }
  return keyValueArray;
}

// Reads hostAttributes from each directive and merges with declaredHtmlAttrs
// to return a single map from name to value(expression).
List<List<String>> mergeHtmlAndDirectiveAttrs(
    Map<String, String> declaredHtmlAttrs,
    List<CompileDirectiveMetadata> directives,
    {bool excludeComponent: false}) {
  Map<String, String> result = {};
  var mergeCount = <String, int>{};
  declaredHtmlAttrs.forEach((name, value) {
    result[name] = value;
    if (mergeCount.containsKey(name)) {
      mergeCount[name]++;
    } else {
      mergeCount[name] = 1;
    }
  });
  for (CompileDirectiveMetadata directiveMeta in directives) {
    directiveMeta.hostAttributes.forEach((name, value) {
      if (mergeCount.containsKey(name)) {
        mergeCount[name]++;
      } else {
        mergeCount[name] = 1;
      }
    });
  }
  for (CompileDirectiveMetadata directiveMeta in directives) {
    bool isComponent = directiveMeta.isComponent;
    for (String name in directiveMeta.hostAttributes.keys) {
      var value = directiveMeta.hostAttributes[name];
      if (excludeComponent &&
          isComponent &&
          !((name == classAttrName || name == styleAttrName) &&
              mergeCount[name] > 1)) {
        continue;
      }
      var prevValue = result[name];
      result[name] = prevValue != null
          ? mergeAttributeValue(name, prevValue, value)
          : value;
    }
  }
  return mapToKeyValueArray(result);
}

o.Statement createDbgElementCall(
    o.Expression nodeExpr, int nodeIndex, TemplateAst ast) {
  var sourceLocation = ast?.sourceSpan?.start;
  return o.importExpr(Identifiers.dbgElm).callFn([
    o.THIS_EXPR,
    nodeExpr,
    o.literal(nodeIndex),
    sourceLocation == null ? o.NULL_EXPR : o.literal(sourceLocation.line),
    sourceLocation == null ? o.NULL_EXPR : o.literal(sourceLocation.column)
  ]).toStmt();
}

Map<String, CompileIdentifierMetadata> tagNameToIdentifier;

/// Returns strongly typed html elements to improve code generation.
CompileIdentifierMetadata identifierFromTagName(String name) {
  tagNameToIdentifier ??= {
    'a': Identifiers.HTML_ANCHOR_ELEMENT,
    'area': Identifiers.HTML_AREA_ELEMENT,
    'audio': Identifiers.HTML_AUDIO_ELEMENT,
    'button': Identifiers.HTML_BUTTON_ELEMENT,
    'canvas': Identifiers.HTML_CANVAS_ELEMENT,
    'div': Identifiers.HTML_DIV_ELEMENT,
    'form': Identifiers.HTML_FORM_ELEMENT,
    'iframe': Identifiers.HTML_IFRAME_ELEMENT,
    'input': Identifiers.HTML_INPUT_ELEMENT,
    'image': Identifiers.HTML_IMAGE_ELEMENT,
    'media': Identifiers.HTML_MEDIA_ELEMENT,
    'menu': Identifiers.HTML_MENU_ELEMENT,
    'ol': Identifiers.HTML_OLIST_ELEMENT,
    'option': Identifiers.HTML_OPTION_ELEMENT,
    'col': Identifiers.HTML_TABLE_COL_ELEMENT,
    'row': Identifiers.HTML_TABLE_ROW_ELEMENT,
    'select': Identifiers.HTML_SELECT_ELEMENT,
    'table': Identifiers.HTML_TABLE_ELEMENT,
    'text': Identifiers.HTML_TEXT_NODE,
    'textarea': Identifiers.HTML_TEXTAREA_ELEMENT,
    'ul': Identifiers.HTML_ULIST_ELEMENT,
    'svg': Identifiers.SVG_SVG_ELEMENT,
  };
  String tagName = name.toLowerCase();
  var elementType = tagNameToIdentifier[tagName];
  elementType ??= Identifiers.HTML_ELEMENT;
  // TODO: classify as HtmlElement or SvgElement to improve further.
  return elementType;
}

Set<String> _tagNameSet;

/// Returns true if tag name is HtmlElement.
///
/// Returns false if tag name is svg element or other. Used for optimizations.
/// Should not generate false positives but returning false when unknown is
/// fine since code will fallback to general Element case.
bool detectHtmlElementFromTagName(String tagName) {
  const htmlTagNames = const <String>[
    'a',
    'abbr',
    'acronym',
    'address',
    'applet',
    'area',
    'article',
    'aside',
    'audio',
    'b',
    'base',
    'basefont',
    'bdi',
    'bdo',
    'bgsound',
    'big',
    'blockquote',
    'body',
    'br',
    'button',
    'canvas',
    'caption',
    'center',
    'cite',
    'code',
    'col',
    'colgroup',
    'command',
    'data',
    'datalist',
    'dd',
    'del',
    'details',
    'dfn',
    'dialog',
    'dir',
    'div',
    'dl',
    'dt',
    'element',
    'em',
    'embed',
    'fieldset',
    'figcaption',
    'figure',
    'font',
    'footer',
    'form',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'head',
    'header',
    'hr',
    'i',
    'iframe',
    'img',
    'input',
    'ins',
    'kbd',
    'keygen',
    'label',
    'legend',
    'li',
    'link',
    'listing',
    'main',
    'map',
    'mark',
    'menu',
    'menuitem',
    'meta',
    'meter',
    'nav',
    'object',
    'ol',
    'optgroup',
    'option',
    'output',
    'p',
    'param',
    'picture',
    'pre',
    'progress',
    'q',
    'rp',
    'rt',
    'rtc',
    'ruby',
    's',
    'samp',
    'script',
    'section',
    'select',
    'shadow',
    'small',
    'source',
    'span',
    'strong',
    'style',
    'sub',
    'summary',
    'sup',
    'table',
    'tbody',
    'td',
    'template',
    'textarea',
    'tfoot',
    'th',
    'thead',
    'time',
    'title',
    'tr',
    'track',
    'tt',
    'u',
    'ul',
    'var',
    'video',
    'wbr'
  ];
  if (_tagNameSet == null) {
    _tagNameSet = new Set<String>();
    for (String name in htmlTagNames) {
      _tagNameSet.add(name);
    }
  }
  return _tagNameSet.contains(tagName);
}
