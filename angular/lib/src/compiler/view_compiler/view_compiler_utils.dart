import 'package:angular/src/core/linker/view_type.dart';
import 'package:angular/src/facade/exceptions.dart' show BaseException;

import '../compile_metadata.dart'
    show
        CompileTokenMetadata,
        CompileDirectiveMetadata,
        CompileIdentifierMetadata;
import '../identifiers.dart' show Identifiers;
import '../output/output_ast.dart' as o;
import 'compile_view.dart' show CompileView;

/// Creating outlines for faster builds is preventing auto input change
/// detection for now. The following flag should be removed to reenable in the
/// future.
const bool outlinerDeprecated = false;

// Creates method parameters list for AppView set attribute calls.
List<o.Expression> createSetAttributeParams(
    String fieldName, String attrNs, String attrName, o.Expression valueExpr) {
  if (attrNs != null) {
    return [
      o.variable(fieldName),
      o.literal(attrNs),
      o.literal(attrName),
      valueExpr
    ];
  } else {
    return [o.variable(fieldName), o.literal(attrName), valueExpr];
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
  if (token.value != null) {
    return o.literal(token.value);
  } else if (token.identifierIsInstance) {
    return o.importExpr(token.identifier).instantiate(
        [], o.importType(token.identifier, [], [o.TypeModifier.Const]));
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

void createPureProxy(o.Expression fn, num argCount,
    o.ReadClassMemberExpr pureProxyProp, CompileView view) {
  view.nameResolver.addField(new o.ClassField(pureProxyProp.name,
      modifiers: const [o.StmtModifier.Private]));
  var pureProxyId = argCount < Identifiers.pureProxies.length
      ? Identifiers.pureProxies[argCount]
      : null;
  if (pureProxyId == null) {
    throw new BaseException(
        'Unsupported number of argument for pure functions: $argCount');
  }
  view.createMethod.addStmt(o.THIS_EXPR
      .prop(pureProxyProp.name)
      .set(o.importExpr(pureProxyId).callFn([fn]))
      .toStmt());
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
