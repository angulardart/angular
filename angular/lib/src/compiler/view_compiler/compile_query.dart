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

class _QueryValues2 {
  /// Compiled template associated to [values] and embedded [templates].
  final CompileView view;

  /// Values of the query to be compiled in as expressions.
  final values = <o.Expression>[];

  /// Embedded templates that have additional values.
  final templates = <_QueryValues2>[];

  _QueryValues2(this.view);

  /// Whether there are nested embedded views in this instance.
  bool get hasNestedViews => templates.isNotEmpty;
}

/// Compiles `@{Content|View}Child[ren]` to template IR.
///
/// Uses a conditional compilation strategy in order to deprecate `QueryList`:
/// https://github.com/dart-lang/angular/issues/688
abstract class CompileQuery2 {
  /// An expression that accesses the component's instance.
  ///
  /// In practice, this is almost always `this.ctx`.
  // ignore: unused_field
  final o.Expression _boundField;

  /// Extracted metadata information from the user-code.
  // ignore: unused_field
  final CompileQueryMetadata _metadata;

  /// Compiled view of the `@Component` that this query originated from.
  ///
  /// **NOTE**: A component whose template has `<template>` tags will have
  /// additional generated views (embedded views), which are expressed as part
  /// of [todoSomeProperty].
  // ignore: unused_field
  final CompileView _queryRoot;

  /// A combination of direct expressions and nested templates needed.
  ///
  /// This is built-up during the lifetime of this class.
  final _QueryValues2 _values;

  CompileQuery2._base(this._metadata, this._queryRoot, this._boundField)
      : _values = new _QueryValues2(_queryRoot);

  /// Whether the query is entirely static, i.e. there are no `<template>`s.
  bool get _isStatic;

  /// Whether the query is only setting a single value, not a list-like object.
  ///
  /// This aligns with `@QueryChild` and `@ContentChild`.
  // ignore: unused_element
  bool get _isSingle => _metadata.first;

  /// Adds an expression [result] that originates from an [origin] view.
  ///
  /// The result of a given query is the sum of all invocations to this method.
  /// Some of the expressions are simple (i.e. reads from an existing class
  /// field) and others require proxy-ing through `mapNestedViews` in order to
  /// determine what `<template>`s are currently active.
  void addQueryResult(CompileView origin, o.Expression result) {
    // Determine if we have a path of embedded templates.
    final elementPath = _resolvePathToRoot(origin);
    var viewValues = _values;

    // If we do, then continue building QueryValues, a tree-like data structure.
    for (final element in elementPath) {
      if (viewValues.hasNestedViews) {
        viewValues = viewValues.templates.last;
      } else {
        assert(element.hasEmbeddedView);
        final newViewValues = new _QueryValues2(element.embeddedView);
        viewValues.templates.add(newViewValues);
        viewValues = newViewValues;
      }
    }

    // Add it to the applicable part of the view (either root or embedded).
    viewValues.values.add(result);

    // Finally, if this result doesn't come from the root, it means that some
    // change in an embedded view needs to invalidate the state of the previous
    // query.
    if (elementPath.isNotEmpty) {
      _setParentQueryAsDirty(
        origin,
      );
    }
  }

  /// Invoked by [addQueryResult] when the [_queryRoot] is now dirty.
  ///
  /// This means during the next change detection cycle we need to rebuild the
  /// result of the query and invoke the bound setter or field accessor.
  void _setParentQueryAsDirty(CompileView origin);

  /// Returns the path required to traverse back to the [_queryRoot].
  ///
  /// This information is used to build up the [_QueryValues] required to
  /// express and retrieve the contents of the query at runtime.
  ///
  /// * For a simple query of static elements in a template, this is `[]`.
  /// * For a more complex query with embedded `<template>`s, this will be
  ///   the path to that embedded template. So for example, this might be a
  ///   single `[ViewComponent0]` when nested in a single `<template>` and a
  ///   longer `[ViewComponent0, ViewComponent1]` when nested even deeper.
  List<CompileElement> _resolvePathToRoot(CompileView view) {
    if (view == _queryRoot) {
      return const [];
    }
    final pathToRoot = <CompileElement>[];
    var currentView = view;
    while (currentView != null && currentView != _queryRoot) {
      final parentElement = currentView.declarationElement;
      pathToRoot.insert(0, parentElement);
      currentView = parentElement.view;
    }
    return pathToRoot;
  }

  /// Create class-member level fields in order to store persistent state.
  ///
  /// For example, in the original implementation this wrote the following:
  /// ```dart
  /// import2.QueryList _viewQuery_ChildDirective_0;
  /// ```
  List<o.Statement> createClassFields();

  /// Return code that will set the query contents at change-detection time.
  ///
  /// This is the general case, where the value of the query is not known at
  /// compile time (changes as embedded `<template>`s are created or destroyed)
  /// or we want to have more predictable timing of the setter being invoked.
  List<o.Statement> createDynamicUpdates();

  /// Return code that will immediately set the query contents at build-time.
  ///
  /// This is an optimization over [createDynamicUpdates] and requires that:
  /// * The query origin is `@ViewChild` or `@ContentChild` (single item).
  /// * No part of the query could be inside of a `<template>` (embedded).
  ///
  /// In practice, most queries are compiled through [createDynamicUpdates], In
  /// the future it will be possible to optimize further and use this method for
  /// more query types.
  List<o.Statement> createImmediateUpdates();
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
    this.view,
  )
      : _values = new _QueryValues(view);

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
