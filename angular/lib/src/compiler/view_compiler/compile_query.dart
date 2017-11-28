import "../compile_metadata.dart" show CompileQueryMetadata, CompileTokenMap;
import "../output/output_ast.dart" as o;
import "compile_element.dart" show CompileElement;
import "compile_method.dart" show CompileMethod;
import "compile_view.dart" show CompileView;
import "view_compiler_utils.dart" show getPropertyInView;

class _QueryValues {
  /// Compiled template associated to [values].
  final CompileView view;

  /// Either [o.Expression] or [_QueryValues] for nested `<template>` views.
  final List values = [];

  _QueryValues(this.view);
}

class CompileQuery {
  final CompileQueryMetadata meta;
  final o.Expression queryList;
  final o.Expression ownerDirectiveExpression;
  final CompileView view;
  final _QueryValues _values;

  CompileQuery(
    this.meta,
    this.queryList,
    this.ownerDirectiveExpression,
    CompileView view,
  )
      : _values = new _QueryValues(view),
        view = view;

  void addValue(o.Expression value, CompileView view) {
    var currentView = view;
    List<CompileElement> elPath = [];
    while (currentView != null && !identical(currentView, this.view)) {
      var parentEl = currentView.declarationElement;
      (elPath..insert(0, parentEl)).length;
      currentView = parentEl.view;
    }
    var queryListForDirtyExpr =
        getPropertyInView(this.queryList, view, this.view);
    var viewValues = this._values;
    for (var el in elPath) {
      var last = viewValues.values.length > 0
          ? viewValues.values[viewValues.values.length - 1]
          : null;
      if (last is _QueryValues && identical(last.view, el.embeddedView)) {
        viewValues = last;
      } else {
        var newViewValues = new _QueryValues(el.embeddedView);
        viewValues.values.add(newViewValues);
        viewValues = newViewValues;
      }
    }
    viewValues.values.add(value);
    if (elPath.length > 0) {
      view.dirtyParentQueriesMethod
          .addStmt(queryListForDirtyExpr.callMethod("setDirty", []).toStmt());
    }
  }

  bool _isStatic() {
    var isStatic = true;
    for (var value in _values.values) {
      if (value is _QueryValues) {
        // querying a nested view makes the query content dynamic
        isStatic = false;
      }
    }
    return isStatic;
  }

  bool get _isSingleStaticQuery => meta.first && _isStatic();

  /// For queries that don't change and user is querying a single element such
  /// as ViewContainerRef, create immediate code in createMethod to
  /// reset value.
  ///
  /// We don't do this for QueryLists for now as this
  /// would break the timing when we call QueryList listeners...
  void generateImmediateUpdate(CompileMethod targetMethod) {
    if (!_isSingleStaticQuery) return;
    var values = _createQueryValues(this._values);
    var statements = [
      queryList.callMethod("reset", [o.literalArr(values)]).toStmt()
    ];
    if (ownerDirectiveExpression != null) {
      statements.add(ownerDirectiveExpression
          .prop(meta.propertyName)
          .set(queryList.prop("first"))
          .toStmt());
    }
    targetMethod.addStmts(statements);
  }

  void generateDynamicUpdate(CompileMethod targetMethod) {
    if (_isSingleStaticQuery) return;
    var values = _createQueryValues(this._values);
    var statements = [
      queryList.callMethod("reset", [o.literalArr(values)]).toStmt()
    ];
    if (ownerDirectiveExpression != null) {
      var valueExpr = meta.first ? queryList.prop("first") : queryList;
      statements.add(ownerDirectiveExpression
          .prop(meta.propertyName)
          .set(valueExpr)
          .toStmt());
    }
    if (!meta.first) {
      statements.add(queryList.callMethod("notifyOnChanges", []).toStmt());
    }
    targetMethod.addStmt(new o.IfStmt(queryList.prop("dirty"), statements));
  }
}

List<o.Expression> _createQueryValues(_QueryValues viewValues) {
  return viewValues.values.map((entry) {
    if (entry is _QueryValues) {
      return _mapNestedViews(entry.view.declarationElement.appViewContainer,
          entry.view, _createQueryValues(entry));
    } else {
      return (entry as o.Expression);
    }
  }).toList();
}

o.Expression _mapNestedViews(o.Expression declarationViewContainer,
    CompileView view, List<o.Expression> expressions) {
  List<o.Expression> adjustedExpressions = expressions.map((expr) {
    return o.replaceReadClassMemberInExpression(o.variable("nestedView"), expr);
  }).toList();
  return declarationViewContainer.callMethod("mapNestedViews", [
    o.variable(view.className),
    o.fn([new o.FnParam("nestedView", view.classType)],
        [new o.ReturnStatement(o.literalArr(adjustedExpressions))])
  ]);
}

void addQueryToTokenMap(
    CompileTokenMap<List<CompileQuery>> map, CompileQuery query) {
  for (var selector in query.meta.selectors) {
    var entry = map.get(selector);
    if (entry == null) {
      entry = [];
      map.add(selector, entry);
    }
    entry.add(query);
  }
}
