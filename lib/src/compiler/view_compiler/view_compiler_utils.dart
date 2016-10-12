import "package:angular2/src/facade/exceptions.dart" show BaseException;

import "../compile_metadata.dart"
    show
        CompileTokenMetadata,
        CompileDirectiveMetadata,
        CompileIdentifierMetadata;
import "../identifiers.dart" show Identifiers;
import "../output/output_ast.dart" as o;
import "compile_view.dart" show CompileView;

// List of supported namespaces.
const NAMESPACE_URIS = const {
  'xlink': 'http://www.w3.org/1999/xlink',
  'svg': 'http://www.w3.org/2000/svg',
  'xhtml': 'http://www.w3.org/1999/xhtml'
};

// Template Anchor comment.
const TEMPLATE_COMMENT_TEXT = 'template bindings={}';
// RegExp to match anchor comment when logging bindings for debugging.
var TEMPLATE_BINDINGS_EXP = new RegExp(r'^template bindings=(.*)$');

// Creates method parameters list for AppView set attribute calls.
List<o.Expression> createSetAttributeParams(
    String fieldName, String attrNs, String attrName, o.Expression valueExpr) {
  if (attrNs != null) {
    return [
      new o.ReadClassMemberExpr(fieldName),
      o.literal(attrNs),
      o.literal(attrName),
      valueExpr
    ];
  } else {
    return [
      new o.ReadClassMemberExpr(fieldName),
      o.literal(attrName),
      valueExpr
    ];
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
          ? new o.ReadClassMemberExpr('parent')
          : viewProp.prop('parent');
    }
    if (!identical(currView, definedView)) {
      throw new BaseException(
          '''Internal error: Could not calculate a property in a parent view: ${ property}''');
    }
    if (property is o.ReadClassMemberExpr) {
      o.ReadClassMemberExpr readMemberExpr = property;
      // Note: Don't cast for members of the AppView base class...
      if (definedView.fields
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
    CompileTokenMetadata token, bool optional) {
  var args = [createDiTokenExpression(token)];
  if (optional) {
    args.add(o.NULL_EXPR);
  }
  return o.THIS_EXPR.prop("parentInjector").callMethod("get", args);
}

String getViewFactoryName(
    CompileDirectiveMetadata component, num embeddedTemplateIndex) {
  return '''viewFactory_${component.type.name}${embeddedTemplateIndex}''';
}

o.Expression createDiTokenExpression(CompileTokenMetadata token) {
  if (token.value != null) {
    return o.literal(token.value);
  } else if (token.identifierIsInstance) {
    return o.importExpr(token.identifier).instantiate(
        [], o.importType(token.identifier, [], [o.TypeModifier.Const]));
  } else {
    return o.importExpr(token.identifier);
  }
}

o.Expression createFlatArray(List<o.Expression> expressions) {
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

o.Expression convertValueToOutputAst(dynamic value) {
  if (value is CompileIdentifierMetadata) {
    return o.importExpr(value);
  } else if (value is o.Expression) {
    return value;
  } else {
    return o.literal(value);
  }
}

void createPureProxy(o.Expression fn, num argCount,
    o.ReadClassMemberExpr pureProxyProp, CompileView view) {
  view.fields.add(new o.ClassField(pureProxyProp.name,
      modifiers: const [o.StmtModifier.Private]));
  var pureProxyId = argCount < Identifiers.pureProxies.length
      ? Identifiers.pureProxies[argCount]
      : null;
  if (pureProxyId == null) {
    throw new BaseException(
        '''Unsupported number of argument for pure functions: ${ argCount}''');
  }
  view.createMethod.addStmt(o.THIS_EXPR
      .prop(pureProxyProp.name)
      .set(o.importExpr(pureProxyId).callFn([fn]))
      .toStmt());
}
