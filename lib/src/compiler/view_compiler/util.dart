library angular2.src.compiler.view_compiler.util;

import "package:angular2/src/facade/lang.dart" show isPresent, isBlank;
import "../output/output_ast.dart" as o;
import "../compile_metadata.dart"
    show
        CompileTokenMetadata,
        CompileDirectiveMetadata,
        CompileIdentifierMetadata;
import "compile_view.dart" show CompileView;

o.Expression getPropertyInView(
    o.Expression property, List<CompileView> viewPath) {
  if (identical(viewPath.length, 0)) {
    return property;
  } else {
    o.Expression viewProp = o.THIS_EXPR;
    for (var i = 0; i < viewPath.length; i++) {
      viewProp = viewProp.prop("declarationAppElement").prop("parentView");
    }
    if (property is o.ReadPropExpr) {
      var lastView = viewPath[viewPath.length - 1];
      o.ReadPropExpr readPropExpr = property;
      // Note: Don't cast for members of the AppView base class...
      if (lastView.fields.any((field) => field.name == readPropExpr.name) ||
          lastView.getters.any((field) => field.name == readPropExpr.name)) {
        viewProp = viewProp.cast(lastView.classType);
      }
    }
    return o.replaceVarInExpression(o.THIS_EXPR.name, viewProp, property);
  }
}

o.Expression injectFromViewParentInjector(
    CompileTokenMetadata token, bool optional) {
  var method = optional ? "getOptional" : "get";
  return o.THIS_EXPR
      .prop("parentInjector")
      .callMethod(method, [createDiTokenExpression(token)]);
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
  var lastNonArrayExpressions = [];
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
