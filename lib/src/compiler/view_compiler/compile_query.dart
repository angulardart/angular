import "../compile_metadata.dart" show CompileQueryMetadata, CompileTokenMap;
import "../identifiers.dart" show Identifiers;
import "../output/output_ast.dart" as o;
import "compile_element.dart" show CompileElement;
import "compile_method.dart" show CompileMethod;
import "compile_view.dart" show CompileView;
import "view_compiler_utils.dart" show getPropertyInView;

class ViewQueryValues {
  CompileView view;
  List<dynamic /* o . Expression | ViewQueryValues */ > values;
  ViewQueryValues(this.view, this.values);
}

class CompileQuery {
  CompileQueryMetadata meta;
  o.Expression queryList;
  o.Expression ownerDirectiveExpression;
  CompileView view;
  ViewQueryValues _values;
  CompileQuery(
      this.meta, this.queryList, this.ownerDirectiveExpression, this.view) {
    this._values = new ViewQueryValues(view, []);
  }
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
    elPath.forEach((el) {
      var last = viewValues.values.length > 0
          ? viewValues.values[viewValues.values.length - 1]
          : null;
      if (last is ViewQueryValues && identical(last.view, el.embeddedView)) {
        viewValues = last;
      } else {
        var newViewValues = new ViewQueryValues(el.embeddedView, []);
        viewValues.values.add(newViewValues);
        viewValues = newViewValues;
      }
    });
    viewValues.values.add(value);
    if (elPath.length > 0) {
      view.dirtyParentQueriesMethod
          .addStmt(queryListForDirtyExpr.callMethod("setDirty", []).toStmt());
    }
  }

  bool _isStatic() {
    var isStatic = true;
    this._values.values.forEach((value) {
      if (value is ViewQueryValues) {
        // querying a nested view makes the query content dynamic
        isStatic = false;
      }
    });
    return isStatic;
  }

  void afterChildren(
      CompileMethod targetStaticMethod, CompileMethod targetDynamicMethod) {
    var values = createQueryValues(this._values);
    var updateStmts = [
      this.queryList.callMethod("reset", [o.literalArr(values)]).toStmt()
    ];
    if (this.ownerDirectiveExpression != null) {
      var valueExpr =
          this.meta.first ? this.queryList.prop("first") : this.queryList;
      updateStmts.add(this
          .ownerDirectiveExpression
          .prop(this.meta.propertyName)
          .set(valueExpr)
          .toStmt());
    }
    if (!this.meta.first) {
      updateStmts
          .add(this.queryList.callMethod("notifyOnChanges", []).toStmt());
    }
    if (this.meta.first && this._isStatic()) {
      // for queries that don't change and the user asked for a single element,

      // set it immediately. That is e.g. needed for querying for ViewContainerRefs, ...

      // we don't do this for QueryLists for now as this would break the timing when

      // we call QueryList listeners...
      targetStaticMethod.addStmts(updateStmts);
    } else {
      targetDynamicMethod
          .addStmt(new o.IfStmt(this.queryList.prop("dirty"), updateStmts));
    }
  }
}

List<o.Expression> createQueryValues(ViewQueryValues viewValues) {
  return viewValues.values.map/*<o.Expression>*/((entry) {
    if (entry is ViewQueryValues) {
      return mapNestedViews(entry.view.declarationElement.appElement,
          entry.view, createQueryValues(entry));
    } else {
      return (entry as o.Expression);
    }
  }).toList();
}

o.Expression mapNestedViews(o.Expression declarationAppElement,
    CompileView view, List<o.Expression> expressions) {
  List<o.Expression> adjustedExpressions = expressions.map((expr) {
    return o.replaceReadClassMemberInExpression(o.variable("nestedView"), expr);
  }).toList();
  return declarationAppElement.callMethod("mapNestedViews", [
    o.variable(view.className),
    o.fn([new o.FnParam("nestedView", view.classType)],
        [new o.ReturnStatement(o.literalArr(adjustedExpressions))])
  ]);
}

o.Expression createQueryList(
    CompileQueryMetadata query,
    o.Expression directiveInstance,
    String propertyName,
    CompileView compileView) {
  compileView.fields.add(new o.ClassField(propertyName,
      outputType: o.importType(Identifiers.QueryList),
      modifiers: [o.StmtModifier.Private]));
  var expr = new o.ReadClassMemberExpr(propertyName);
  compileView.createMethod.addStmt(new o.WriteClassMemberExpr(
          propertyName, o.importExpr(Identifiers.QueryList).instantiate([]))
      .toStmt());
  return expr;
}

void addQueryToTokenMap(
    CompileTokenMap<List<CompileQuery>> map, CompileQuery query) {
  query.meta.selectors.forEach((selector) {
    var entry = map.get(selector);
    if (entry == null) {
      entry = [];
      map.add(selector, entry);
    }
    entry.add(query);
  });
}
