import 'dart:collection';

import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/compiler/compile_metadata.dart'
    show
        CompileTokenMetadata,
        CompileDirectiveMetadata,
        CompileIdentifierMetadata;
import 'package:angular/src/compiler/expression_parser/ast.dart' as ast;
import 'package:angular/src/compiler/identifiers.dart';
import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/compiler/output/convert.dart'
    show typeArgumentsFrom;
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular/src/compiler/semantic_analysis/binding_converter.dart'
    show convertAllToBinding, convertHostAttributeToBinding;
import 'package:angular/src/compiler/template_ast.dart' show ElementAst;
import 'package:angular/src/core/linker/view_type.dart';

import 'compile_view.dart' show CompileView, ReadNodeReferenceExpr;
import 'constants.dart';

// List of supported namespaces.
const namespaceUris = {
  'xlink': 'http://www.w3.org/1999/xlink',
  'svg': 'http://www.w3.org/2000/svg',
  'xhtml': 'http://www.w3.org/1999/xhtml'
};

/// All properties of `RenderView` that don't need a cast to access.
final _renderViewProperties = Set<String>.from([
  'componentStyles',
  'parentIndex',
  'parentView',
]);

final _unsafeCastFn = o.importExpr(Runtime.unsafeCast);

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

    // Don't cast properties of `RenderView`.
    return replaceReadClassMemberInExpression(
        property,
        (name) => _renderViewProperties.contains(name)
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
  final viewExpr = (view.viewType == ViewType.host)
      ? o.THIS_EXPR
      : o.ReadClassMemberExpr('parentView');
  return viewExpr.callMethod(optional ? 'injectorGetOptional' : 'injectorGet', [
    createDiTokenExpression(token),
    o.ReadClassMemberExpr('parentIndex'),
  ]);
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
    o.importExpr(Runtime.isDevMode).conditional(
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

List<ir.Binding> mergeHtmlAndDirectiveAttributes(
    ElementAst elementAst, List<CompileDirectiveMetadata> directives) {
  var attrs = elementAst.attrs;
  var htmlAttrs = convertAllToBinding(attrs);
  // Create statements to initialize literal attribute values.
  // For example, a directive may have hostAttributes setting class name.
  return _mergeHtmlAndDirectiveAttrs(htmlAttrs, directives);
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
List<ir.Binding> _mergeHtmlAndDirectiveAttrs(
  List<ir.Binding> declaredHtmlAttrs,
  List<CompileDirectiveMetadata> directives,
) {
  var result = <String, ir.Binding>{};
  var mergeCount = <String, int>{};
  for (var binding in declaredHtmlAttrs) {
    var name = _nameOf(binding.target);
    result[name] = binding;
    _increment(mergeCount, name);
  }
  for (CompileDirectiveMetadata directiveMeta in directives) {
    directiveMeta.hostAttributes.forEach((name, value) {
      _increment(mergeCount, name);
    });
  }
  for (CompileDirectiveMetadata directiveMeta in directives) {
    bool isComponent = directiveMeta.isComponent;
    for (String name in directiveMeta.hostAttributes.keys) {
      var canMerge = name == classAttrName || name == styleAttrName;
      var hasMultiple = mergeCount[name] > 1;
      var shouldMerge = canMerge && hasMultiple;
      // The code for component host bindings is generated at another site, thus
      // we don't need to merge it here if there are no other bindings to the
      // same attribute.
      //
      // In the event that such a host binding collides with another directive
      // host binding or attribute binding, they're merged here and the
      // resulting code overwrites the component host binding (at runtime).
      //
      // If the attribute can't be merged and there are multiple, we skip the
      // component host binding so that an HTML attribute or directive host
      // binding that came earlier takes priority.
      if (isComponent && !shouldMerge) continue;

      var value = convertHostAttributeToBinding(
          name,
          ast.ASTWithSource.missingSource(directiveMeta.hostAttributes[name]),
          directiveMeta.analyzedClass);
      var prevValue = result[name];
      result[name] = prevValue != null
          ? _mergeAttributeValue(
              name, prevValue, value, directiveMeta.analyzedClass)
          : value;
    }
  }
  return _toSortedBindings(result);
}

String _nameOf(ir.BindingTarget target) {
  if (target is ir.ClassBinding) {
    return target.name != null ? 'class.${target.name}' : 'class';
  }
  if (target is ir.StyleBinding) {
    return 'style';
  }
  if (target is ir.TabIndexBinding) {
    return 'tabIndex';
  }
  if (target is ir.AttributeBinding) {
    return target.namespace != null
        ? '@${target.namespace}:${target.name}'
        : target.name;
  }
  throw ArgumentError.value(
      target, 'target', 'Binding target type does not have a name.');
}

void _increment(Map<String, int> mergeCount, String name) {
  mergeCount.putIfAbsent(name, () => 0);
  mergeCount[name]++;
}

ir.Binding _mergeAttributeValue(
  String attrName,
  ir.Binding attr1,
  ir.Binding attr2,
  AnalyzedClass analyzedClass,
) {
  if (attrName != classAttrName && attrName != styleAttrName) {
    return attr2;
  }
  var attrValue1 = attr1.source;
  var attrValue2 = attr2.source;
  // attrValue1 can be a literal string (from an HTML attribute), an
  // expression (from a host attribute), or an interpolation (from a previous
  // merge). attrValue2 can only be an expression (from a host attribute), it
  // CANNOT be an interpolate because attrValue2 represents the "new"
  // attribute value we need to merge in, which must always be a property
  // access. Only the "previous" attrValue can be an interpolation because we
  // are constructing the interpolation here.
  if (attrValue1 is ir.BoundExpression &&
      attrValue1.expression is ast.Interpolation) {
    attrValue1.expression as ast.Interpolation
      ..expressions.add(_asAst(attrValue2))
      ..strings.add(' ');
    return attr1;
  } else {
    return ir.Binding(
        target: attr1.target,
        source: ir.BoundExpression(
            ast.ASTWithSource.missingSource(ast.Interpolation(
                ['', ' ', ''], [_asAst(attrValue1), _asAst(attrValue2)])),
            null,
            analyzedClass));
  }
}

ast.AST _asAst(ir.BindingSource bindingSource) {
  if (bindingSource is ir.BoundExpression) {
    return bindingSource.expression.ast;
  } else if (bindingSource is ir.StringLiteral) {
    return ast.LiteralPrimitive(bindingSource.value);
  }
  throw ArgumentError.value(
      bindingSource,
      'bindingSource',
      'BindingSource implementation $bindingSource doesn\'t support conversion '
          'to an AST.');
}

List<ir.Binding> _toSortedBindings(Map<String, ir.Binding> attributes) =>
    _toSortedMap(attributes).values.toList();

Map<K, V> _toSortedMap<K, V>(Map<K, V> data) => SplayTreeMap.from(data);

final Map<String, CompileIdentifierMetadata> _tagNameToIdentifier = {
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

/// Returns strongly typed html elements to improve code generation.
CompileIdentifierMetadata identifierFromTagName(String name) =>
    _tagNameToIdentifier[name.toLowerCase()] ?? Identifiers.HTML_ELEMENT;

const _htmlTagNames = <String>{
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
  'wbr',
};

/// Returns true if tag name is HtmlElement.
///
/// Returns false if tag name is svg element or other. Used for optimizations.
/// Should not generate false positives but returning false when unknown is
/// fine since code will fallback to general Element case.
bool detectHtmlElementFromTagName(String tagName) =>
    _htmlTagNames.contains(tagName);

/// Returns statements to locally cache `AppView.ctx` as `_ctx`, if needed.
///
/// Because `AppView.ctx` isn't final, dart2js can't assume that it isn't null,
/// nor that it won't change between subsequent references. Assigning it to a
/// local, final variable eliminates the need to repeatedly load and null check
/// the field in the compiled JS code.
///
/// If `_ctx` was never used, this will return an empty list.
///
/// Pass either [statements] or [readVars]. If [readVars] is null, it will
/// be computed from [statements]
List<o.Statement> maybeCachedCtxDeclarationStatement(
    {Set<String> readVars, List<o.Statement> statements}) {
  readVars ??= o.findReadVarNames(statements);
  if (readVars.contains(DetectChangesVars.cachedCtx.name)) {
    // Cache [ctx] class field member as typed [_ctx] local for change
    // detection code to consume.
    return [
      DetectChangesVars.cachedCtx
          .set(o.ReadClassMemberExpr('ctx'))
          .toDeclStmt(null, [o.StmtModifier.Final])
    ];
  }
  return [];
}
