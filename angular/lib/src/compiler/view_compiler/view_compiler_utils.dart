import 'dart:collection';

import 'package:angular/src/core/linker/view_type.dart';

import '../compile_metadata.dart'
    show
        CompileTokenMetadata,
        CompileDirectiveMetadata,
        CompileIdentifierMetadata;
import '../expression_parser/ast.dart' as ast;
import '../identifiers.dart';
import '../output/convert.dart' show typeArgumentsFrom;
import '../output/output_ast.dart' as o;
import '../template_ast.dart' show AttrAst, LiteralAttributeValue;
import 'compile_view.dart' show CompileView, ReadNodeReferenceExpr;
import 'constants.dart';

// List of supported namespaces.
const namespaceUris = {
  'xlink': 'http://www.w3.org/1999/xlink',
  'svg': 'http://www.w3.org/2000/svg',
  'xhtml': 'http://www.w3.org/1999/xhtml'
};

/// Variable name used to read viewData.parentIndex in build functions.
const String cachedParentIndexVarName = 'parentIdx';

/// All fields and getters defined on [AppView] that don't need a cast in
/// getPropertyInView.
final _appViewFields = Set<String>.from([
  'viewData',
  'locals',
  'parentView',
  'componentType',
  'rootEl',
  'ctx',
  'cdMode',
  'cdState',
  'ref',
  'projectableNodes',
  'changeDetectorRef',
  'inlinedNodes',
  'flatRootNodes',
  'lastRootNode',
]);

// Creates method parameters list for AppView set attribute calls.
List<o.Expression> createSetAttributeParams(o.Expression renderNode,
    String attrNs, String attrName, o.Expression valueExpr) {
  if (attrNs != null) {
    return [renderNode, o.literal(attrNs), o.literal(attrName), valueExpr];
  } else {
    return [renderNode, o.literal(attrName), valueExpr];
  }
}

final _unsafeCastFn = o.importExpr(Identifiers.unsafeCast);

/// Returns `unsafeCast<{Cast}>(expression)`.
o.Expression unsafeCast(o.Expression expression, [o.OutputType cast]) {
  return _unsafeCastFn.callFn(
    [expression],
    typeArguments: cast != null ? [cast] : const [],
  );
}

o.Expression getPropertyInView(
  o.Expression property,
  CompileView callingView,
  CompileView definedView,
) {
  if (identical(callingView, definedView)) {
    return property;
  } else {
    o.Expression viewProp;
    CompileView currView = callingView;
    while (!identical(currView, definedView) &&
        currView.declarationElement.view != null) {
      currView = currView.declarationElement.view;
      viewProp = viewProp == null
          ? o.ReadClassMemberExpr('parentView')
          : viewProp.prop('parentView');
    }
    if (!identical(currView, definedView)) {
      throw StateError('Internal error: Could not calculate a property '
          'in a parent view: $property');
    }

    // Note: Don't cast for members of the AppView base class...
    return replaceReadClassMemberInExpression(
        property,
        (String name) => _appViewFields.contains(name)
            ? viewProp
            : unsafeCast(viewProp, definedView.classType));
  }
}

typedef o.Expression ReplaceWithName(String name);

/// Returns [expression] with every [ReadClassMemberExpr] replaced with an
/// equivalently named [ReadPropExpr] invoked on the receiver returned from
/// [replacer].
///
/// [replacer] is passed the name of the [ReadClassMemberExpr] being replaced.
///
/// Any [ReadNodeReferenceExpr] encountered are promoted to class members and
/// replaced in the same way.
o.Expression replaceReadClassMemberInExpression(
    o.Expression expression, ReplaceWithName replacer) {
  var transformer = _ReplaceReadClassMemberTransformer(replacer);
  return expression.visitExpression(transformer, null);
}

class _ReplaceReadClassMemberTransformer extends o.ExpressionTransformer<void> {
  final ReplaceWithName _replacer;
  _ReplaceReadClassMemberTransformer(this._replacer);

  @override
  o.Expression visitReadVarExpr(o.ReadVarExpr ast, _) {
    if (ast is ReadNodeReferenceExpr) {
      ast.node.promoteToClassMember();
      return _replace(ast.name);
    }
    return ast;
  }

  @override
  o.Expression visitReadClassMemberExpr(o.ReadClassMemberExpr ast, _) =>
      _replace(ast.name);

  o.Expression _replace(String name) => o.ReadPropExpr(_replacer(name), name);
}

o.Expression injectFromViewParentInjector(
  CompileView view,
  CompileTokenMetadata token,
  bool optional,
) {
  o.Expression viewExpr = (view.viewType == ViewType.host)
      ? o.THIS_EXPR
      : o.ReadClassMemberExpr('parentView');
  var args = [
    createDiTokenExpression(token),
    o.ReadClassMemberExpr('viewData').prop('parentIndex')
  ];
  if (optional) {
    args.add(o.NULL_EXPR);
  }
  return viewExpr.callMethod('injectorGet', args);
}

o.Statement debugInjectorEnter(o.Expression identifier) =>
    o.importExpr(Identifiers.debugInjectorEnter).callFn([
      identifier,
    ]).toStmt();

o.Statement debugInjectorLeave(o.Expression identifier) =>
    o.importExpr(Identifiers.debugInjectorLeave).callFn([
      identifier,
    ]).toStmt();

o.Expression debugInjectorWrap(o.Expression identifier, o.Expression wrap) =>
    o.importExpr(Identifiers.isDevMode).conditional(
          o.importExpr(Identifiers.debugInjectorWrap).callFn([
            identifier,
            o.fn([], [
              o.ReturnStatement(wrap),
            ])
          ]),
          wrap,
        );

/// Returns the name of a [component] view factory for [index].
///
/// Each generated view of [component], be it component, host, or embedded has
/// an associated [index] that is used to distinguish between embedded views.
String getViewFactoryName(CompileDirectiveMetadata component, int index) =>
    _viewFactoryName(component.type.name, index);

String getHostViewFactoryName(CompileDirectiveMetadata component) =>
    _viewFactoryName('${component.type.name}Host', 0);

String _viewFactoryName(String componentName, int index) =>
    'viewFactory_$componentName$index';

/// Returns a callable expression for the [component] view factory named [name].
///
/// If [component] is generic, the view factory will flow the type parameters of
/// the parent view as type arguments to the embedded view.
///
/// **Note:** It's assumed that [name] originates from an invocation of
/// [getViewFactoryName] with the same [component].
o.Expression getViewFactory(
  CompileDirectiveMetadata component,
  String name,
) {
  final viewFactoryVar = o.variable(name);
  if (component.originType.typeParameters.isEmpty) {
    return viewFactoryVar;
  }
  final parameters = [o.FnParam('parentView'), o.FnParam('parentIndex')];
  final arguments = parameters.map((p) => o.variable(p.name)).toList();
  return o.FunctionExpr(parameters, [
    o.ReturnStatement(o.InvokeFunctionExpr(
      viewFactoryVar,
      arguments,
      typeArgumentsFrom(component.originType.typeParameters),
    )),
  ]);
}

o.Expression createDiTokenExpression(CompileTokenMetadata token) {
  if (token.identifierIsInstance) {
    return o.importExpr(token.identifier).instantiate(
        // If there is also a value, assume it is the first argument.
        //
        // i.e. const OpaqueToken('literalValue')
        token.value != null ? [o.literal(token.value)] : const <o.Expression>[],
        type: o.importType(token.identifier, [], [o.TypeModifier.Const]),
        // Add any generic types attached to the type.
        //
        // Only a value of `null` precisely means "no generic types", not [].
        genericTypes: token.identifier.typeArguments.isNotEmpty
            ? token.identifier.typeArguments
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
        .instantiate([], type: o.importType(token.identifier, []));
  } else {
    return o.importExpr(token.identifier);
  }
}

o.Expression createFlatArray(List<o.Expression> expressions,
    {bool constForEmpty = true}) {
  // Simplify: No items.
  if (expressions.isEmpty) {
    return o.literalArr(
      const [],
      o.ArrayType(
          null, constForEmpty ? const [o.TypeModifier.Const] : const []),
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
      if (lastNonArrayExpressions.isNotEmpty) {
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
  if (lastNonArrayExpressions.isNotEmpty) {
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

Map<String, AttrAst> astAttribListToMap(List<AttrAst> attrs) {
  Map<String, AttrAst> htmlAttrs = {};
  for (AttrAst attr in attrs) {
    htmlAttrs[attr.name] = attr;
  }
  return htmlAttrs;
}

ast.AST _mergeAttributeValue(
    String attrName, ast.AST attrValue1, ast.AST attrValue2) {
  if (attrName == classAttrName || attrName == styleAttrName) {
    // attrValue1 can be a literal string (from an HTML attribute), an
    // expression (from a host attribute), or an interpolation (from a previous
    // merge). attrValue2 can only be an expression (from a host attribute), it
    // CANNOT be an interpolate because attrValue2 represents the "new"
    // attribute value we need to merge in, which must always be a property
    // access. Only the "previous" attrValue can be an interpolation because we
    // are constructing the interpolation here.
    if (attrValue1 is ast.Interpolation) {
      attrValue1.expressions.add(attrValue2);
      attrValue1.strings.add(' ');
      return attrValue1;
    } else {
      return ast.Interpolation(['', ' ', ''], [attrValue1, attrValue2]);
    }
  } else {
    return attrValue2;
  }
}

o.Statement createSetAttributeStatement(String astNodeName,
    o.Expression renderNode, String attrName, o.Expression attrValue) {
  String attrNs;
  // Copy of the logic in property_binder.dart.
  //
  // Unfortunately host attributes are treated differently (for historic
  // reasons), and they do run through property_binder. We should eventually
  // refactor and not have duplicate code here.
  if (attrName.endsWith('.if')) {
    attrName = attrName.substring(0, attrName.length - 3);
    attrValue = attrValue.conditional(o.literal(''), o.NULL_EXPR);
  }
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
          return renderNode.prop('className').set(attrValue).toStmt();
        }
        break;
      case 'tabindex':
      case 'tabIndex':
        try {
          if (attrValue is o.LiteralExpr) {
            final value = attrValue.value;
            if (value is String) {
              final tabValue = int.parse(value);
              return renderNode
                  .prop('tabIndex')
                  .set(o.literal(tabValue))
                  .toStmt();
            }
          } else {
            // Assume it's an int field
            return renderNode.prop('tabIndex').set(attrValue).toStmt();
          }
        } catch (_) {
          // fallthrough to default handler since index is not int.
        }
        break;
      default:
        break;
    }
  }
  var params =
      createSetAttributeParams(renderNode, attrNs, attrName, attrValue);
  return o.InvokeMemberMethodExpr(
          attrNs == null ? "createAttr" : "setAttrNS", params)
      .toStmt();
}

Map<String, ast.AST> _toSortedMap(Map<String, ast.AST> data) {
  var result = SplayTreeMap<String, ast.AST>();
  return result..addAll(data);
}

/// Merges host attributes from [directives] with [declaredHtmlAttrs].
///
/// Note that only values for `class` and `style` attributes are actually merged
/// together. For all other attributes, any collisions are overridden in the
/// following priority (lowest to highest).
///
///   1. Component host attributes.
///   2. HTML attributes.
///   3. Directive host attributes.
///
/// Note that internationalized (`@i18n:`) attributes are skipped, and handled
/// separately at the call site. These should be treated with the same priority
/// as HTML attributes (2), meaning that any merged attribute returned by this
/// function takes priority over an internationalized attribute of the same name
/// (since it must have originated from a directive). There's currently a subtle
/// but where the priority isn't entirely respected, since this logic actually
/// puts component host attributes ahead of `@i18n` HTML attributes. See
/// https://github.com/dart-lang/angular/issues/1600.
Map<String, ast.AST> mergeHtmlAndDirectiveAttrs(
    Map<String, AttrAst> declaredHtmlAttrs,
    List<CompileDirectiveMetadata> directives) {
  var result = <String, ast.AST>{};
  var mergeCount = <String, int>{};
  declaredHtmlAttrs.forEach((name, value) {
    final attributeValue = value.value;
    // Only HTML attributes with literal values are merged here.
    // Internationalized attributes are handled separately.
    if (attributeValue is LiteralAttributeValue) {
      result[name] = ast.LiteralPrimitive(attributeValue.value);
      if (mergeCount.containsKey(name)) {
        mergeCount[name]++;
      } else {
        mergeCount[name] = 1;
      }
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
      if (isComponent &&
          !((name == classAttrName || name == styleAttrName) &&
              mergeCount[name] > 1)) {
        continue;
      }
      var prevValue = result[name];
      result[name] = prevValue != null
          ? _mergeAttributeValue(name, prevValue, value)
          : value;
    }
  }
  return _toSortedMap(result);
}

Map<String, CompileIdentifierMetadata> _tagNameToIdentifier;

/// Returns strongly typed html elements to improve code generation.
CompileIdentifierMetadata identifierFromTagName(String name) {
  _tagNameToIdentifier ??= {
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
  var elementType = _tagNameToIdentifier[tagName];
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
  const htmlTagNames = <String>[
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
    _tagNameSet = Set<String>();
    for (String name in htmlTagNames) {
      _tagNameSet.add(name);
    }
  }
  return _tagNameSet.contains(tagName);
}
