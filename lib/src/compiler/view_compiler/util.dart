import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show isPresent, isBlank;

import "../compile_metadata.dart"
    show
        CompileTokenMetadata,
        CompileDirectiveMetadata,
        CompileIdentifierMetadata;
import "../identifiers.dart" show Identifiers;
import "../output/output_ast.dart" as o;
import "compile_view.dart" show CompileView;

o.Expression getPropertyInView(
    o.Expression property, CompileView callingView, CompileView definedView) {
  if (identical(callingView, definedView)) {
    return property;
  } else {
    o.Expression viewProp = o.THIS_EXPR;
    CompileView currView = callingView;
    while (!identical(currView, definedView) &&
        isPresent(currView.declarationElement.view)) {
      currView = currView.declarationElement.view;
      viewProp = viewProp.prop("parent");
    }
    if (!identical(currView, definedView)) {
      throw new BaseException(
          '''Internal error: Could not calculate a property in a parent view: ${ property}''');
    }
    if (property is o.ReadPropExpr) {
      o.ReadPropExpr readPropExpr = property;
      // Note: Don't cast for members of the AppView base class...
      if (definedView.fields.any((field) => field.name == readPropExpr.name) ||
          definedView.getters.any((field) => field.name == readPropExpr.name)) {
        viewProp = viewProp.cast(definedView.classType);
      }
    }
    return o.replaceVarInExpression(o.THIS_EXPR.name, viewProp, property);
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
  return '''viewFactory_${ component . type . name}${ embeddedTemplateIndex}''';
}

o.Expression createDiTokenExpression(CompileTokenMetadata token) {
  if (isPresent(token.value)) {
    return o.literal(token.value);
  } else if (token.identifierIsInstance) {
    return o.importExpr(token.identifier).instantiate(
        [], o.importType(token.identifier, [], [o.TypeModifier.Const]));
  } else {
    return o.importExpr(token.identifier);
  }
}

o.Expression createFlatArray(List<o.Expression> expressions) {
  var lastNonArrayExpressions = <o.Expression>[];
  o.Expression result = o.literalArr([]);
  for (var i = 0; i < expressions.length; i++) {
    var expr = expressions[i];
    if (expr.type is o.ArrayType) {
      if (lastNonArrayExpressions.length > 0) {
        result = result.callMethod(o.BuiltinMethod.ConcatArray,
            [o.literalArr(lastNonArrayExpressions)]);
        lastNonArrayExpressions = [];
      }
      result = result.callMethod(o.BuiltinMethod.ConcatArray, [expr]);
    } else {
      lastNonArrayExpressions.add(expr);
    }
  }
  if (lastNonArrayExpressions.length > 0) {
    result = result.callMethod(
        o.BuiltinMethod.ConcatArray, [o.literalArr(lastNonArrayExpressions)]);
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

createPureProxy(o.Expression fn, num argCount, o.ReadPropExpr pureProxyProp,
    CompileView view) {
  view.fields.add(
      new o.ClassField(pureProxyProp.name, null, [o.StmtModifier.Private]));
  var pureProxyId = argCount < Identifiers.pureProxies.length
      ? Identifiers.pureProxies[argCount]
      : null;
  if (isBlank(pureProxyId)) {
    throw new BaseException(
        '''Unsupported number of argument for pure functions: ${ argCount}''');
  }
  view.createMethod.addStmt(o.THIS_EXPR
      .prop(pureProxyProp.name)
      .set(o.importExpr(pureProxyId).callFn([fn]))
      .toStmt());
}
