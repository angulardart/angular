import "package:meta/meta.dart";

import "../compile_metadata.dart" show CompileQueryMetadata, CompileTokenMap;
import "../identifiers.dart" show Identifiers;
import "../output/output_ast.dart" as o;
import "compile_element.dart" show CompileElement;
import "compile_view.dart" show CompileView;
import "view_compiler_utils.dart" show getPropertyInView;

class _QueryValues {
  /// Compiled template associated to [values] and embedded [templates].
  final CompileView view;

  /// Values or embedded templates of the query.
  final valuesOrTemplates = <dynamic>[];

  _QueryValues(this.view);

  /// Whether there are nested embedded views in this instance.
  bool get hasNestedViews => valuesOrTemplates.any((v) => v is _QueryValues);
}

/// Compiles `@{Content|View}Child[ren]` to template IR.
///
/// Uses a conditional compilation strategy in order to deprecate `QueryList`:
/// https://github.com/dart-lang/angular/issues/688
abstract class CompileQuery {
  static bool _useNewQuery(CompileQueryMetadata metadata) =>
      // We don't use the new-style queries with .first yet.
      !metadata.first && metadata.isListType;

  /// An expression that accesses the component's instance.
  ///
  /// In practice, this is almost always `this.ctx`.
  final o.Expression _boundField;

  /// Extracted metadata information from the user-code.
  final CompileQueryMetadata metadata;

  /// Compiled view of the `@Component` that this query originated from.
  ///
  /// **NOTE**: A component whose template has `<template>` tags will have
  /// additional generated views (embedded views), which are expressed as part
  /// of [todoSomeProperty].
  final CompileView _queryRoot;

  /// A combination of direct expressions and nested templates needed.
  ///
  /// This is built-up during the lifetime of this class.
  final _QueryValues _values;

  factory CompileQuery({
    @required CompileQueryMetadata metadata,
    @required CompileView queryRoot,
    @required o.Expression boundField,
    @required int nodeIndex,
    @required int queryIndex,
  }) {
    if (_useNewQuery(metadata)) {
      return new _ListCompileQuery(
        metadata,
        queryRoot,
        boundField,
        nodeIndex: nodeIndex,
        queryIndex: queryIndex,
      );
    }
    return new _QueryListCompileQuery(
      metadata,
      queryRoot,
      boundField,
      nodeIndex: nodeIndex,
      queryIndex: queryIndex,
    );
  }

  factory CompileQuery.viewQuery({
    @required CompileQueryMetadata metadata,
    @required CompileView queryRoot,
    @required o.Expression boundField,
    @required int queryIndex,
  }) {
    if (_useNewQuery(metadata)) {
      return new _ListCompileQuery(
        metadata,
        queryRoot,
        boundField,
        nodeIndex: 1,
        queryIndex: queryIndex,
      );
    }
    return new _QueryListCompileQuery(
      metadata,
      queryRoot,
      boundField,
      nodeIndex: -1,
      queryIndex: queryIndex,
    );
  }

  CompileQuery._base(
    this.metadata,
    this._queryRoot,
    this._boundField,
  )
      : _values = new _QueryValues(_queryRoot);

  /// Whether the query is entirely static, i.e. there are no `<template>`s.
  bool get _isStatic => !_values.hasNestedViews;

  /// Whether the query is only setting a single value, not a list-like object.
  ///
  /// This aligns with `@QueryChild` and `@ContentChild`.
  // ignore: unused_element
  bool get _isSingle => metadata.first;

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
      final valuesOrTemplates = viewValues.valuesOrTemplates;
      final last = valuesOrTemplates.isNotEmpty ? valuesOrTemplates.last : null;
      if (last is _QueryValues && last.view == element.embeddedView) {
        viewValues = last;
      } else {
        assert(element.hasEmbeddedView);
        final newViewValues = new _QueryValues(element.embeddedView);
        valuesOrTemplates.add(newViewValues);
        viewValues = newViewValues;
      }
    }

    // Add it to the applicable part of the view (either root or embedded).
    viewValues.valuesOrTemplates.add(result);

    // Finally, if this result doesn't come from the root, it means that some
    // change in an embedded view needs to invalidate the state of the previous
    // query.
    if (elementPath.isNotEmpty) {
      _setParentQueryAsDirty(
        origin,
      );
    }
  }

  /// Returns the literal values of the list that the user-code receives.
  List<o.Expression> _buildQueryResult(_QueryValues viewValues) {
    final result = <o.Expression>[];
    if (!viewValues.hasNestedViews) {
      // Fast-path when there are no nested views.
      for (final o.Expression expression in viewValues.valuesOrTemplates) {
        result.add(expression);
      }
    } else {
      for (final valueOrTemplate in viewValues.valuesOrTemplates) {
        // It's easier to reason/flatten if everything is a List.
        //
        // If we _don't_ do this, then we lose type inference as well:
        //   [
        //     [1],
        //     [2],
        //   ] ==> List<List<int>>
        //
        //   [
        //     1,
        //     [2],
        //   ] ==> List<Object>
        if (valueOrTemplate is o.Expression) {
          result.add(o.literalArr([valueOrTemplate]));
        } else if (valueOrTemplate is _QueryValues) {
          result.add(
            _mapNestedViews(
              valueOrTemplate.view.declarationElement.appViewContainer,
              valueOrTemplate.view,
              _buildQueryResult(valueOrTemplate),
            ),
          );
        }
      }
    }
    return result;
  }

  /// Returns an expression that invokes `AppView.mapNestedViews`.
  ///
  /// This is required to traverse embedded `<template>` views for query matches.
  o.Expression _mapNestedViews(
    o.Expression declarationViewContainer,
    CompileView view,
    List<o.Expression> expressions,
  ) {
    final adjustedExpressions = expressions.map((expr) {
      return o.replaceReadClassMemberInExpression(
        o.variable('nestedView'),
        expr,
      );
    }).toList();
    return declarationViewContainer.callMethod('mapNestedViews', [
      o.fn(
        [new o.FnParam('nestedView', view.classType)],
        [new o.ReturnStatement(o.literalArr(adjustedExpressions))],
      ),
    ]);
  }

  static final _flattenNodesFn = o.importExpr(Identifiers.flattenNodes);

  /// Flattens a `List<List<?>>` into a `List<?>`.
  o.Expression _flattenNodes(o.Expression nodeExpressions) =>
      _flattenNodesFn.callFn([nodeExpressions]);

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

  /// Create class-member level field in order to store persistent state.
  ///
  /// For example, in the original implementation this wrote the following:
  /// ```dart
  /// import2.QueryList _query_ChildDirective_0;
  /// ```
  o.AbstractClassPart createClassField();

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

class _QueryListCompileQuery extends CompileQuery {
  o.Expression _queryList;
  o.ClassField _classField;

  _QueryListCompileQuery(
    CompileQueryMetadata metadata,
    CompileView queryRoot,
    o.Expression boundField, {
    @required int nodeIndex,
    @required int queryIndex,
  })
      : super._base(metadata, queryRoot, boundField) {
    _queryList = _createQueryListField(
      metadata: metadata,
      nodeIndex: nodeIndex,
      queryIndex: queryIndex,
    );
  }

  /// Inserts a `QueryList {property}` field in the generated view.
  ///
  /// Returns an expression pointing to that field.
  o.Expression _createQueryListField({
    @required CompileQueryMetadata metadata,
    @required int nodeIndex,
    @required int queryIndex,
  }) {
    final selector = metadata.selectors.first.name;
    // This is to avoid churn in the golden files/output while debugging.
    //
    // We can rename the properties after we decide to keep this code branch.
    String property;
    if (nodeIndex == -1) {
      // @ViewChild[ren].
      property = '_viewQuery_${selector}_$queryIndex';
    } else {
      // @ContentChild[ren].
      property = '_query_${selector}_${nodeIndex}_$queryIndex';
    }
    // final QueryList _query_foo_0_0 = new QueryList();
    _classField = new o.ClassField(
      property,
      outputType: o.importType(Identifiers.QueryList),
      modifiers: [o.StmtModifier.Private, o.StmtModifier.Final],
      initializer: o.importExpr(Identifiers.QueryList).instantiate([]),
    );
    return new o.ReadClassMemberExpr(property);
  }

  @override
  void _setParentQueryAsDirty(CompileView origin) {
    final queryListField = getPropertyInView(_queryList, origin, _queryRoot);
    origin.dirtyParentQueriesMethod.addStmt(
      queryListField.callMethod('setDirty', []).toStmt(),
    );
  }

  @override
  o.AbstractClassPart createClassField({bool viewQuery: false}) => _classField;

  @override
  List<o.Statement> createDynamicUpdates() {
    if (_isSingle && _isStatic) {
      return const [];
    }
    return _createUpdates();
  }

  @override
  List<o.Statement> createImmediateUpdates() {
    if (_isStatic && _isSingle) {
      return _createUpdates();
    }
    return const [];
  }

  List<o.Statement> _createUpdates() {
    final values = _buildQueryResult(_values);
    final statements = [
      _queryList.callMethod('reset', [o.literalArr(values)]).toStmt(),
    ];
    if (_boundField != null) {
      final valueExpr = _isSingle ? _queryList.prop('first') : _queryList;
      statements.add(
        _boundField.prop(metadata.propertyName).set(valueExpr).toStmt(),
      );
    }
    if (!_isSingle) {
      statements.add(
        _queryList.callMethod('notifyOnChanges', []).toStmt(),
      );
    }
    if (_isStatic && _isSingle) {
      return statements;
    }
    return [new o.IfStmt(_queryList.prop('dirty'), statements)];
  }
}

class _ListCompileQuery extends CompileQuery {
  o.ReadPropExpr _queryDirtyField;
  o.ClassField _classField;

  _ListCompileQuery(
    CompileQueryMetadata metadata,
    CompileView queryRoot,
    o.Expression boundField, {
    @required int nodeIndex,
    @required int queryIndex,
  })
      : super._base(metadata, queryRoot, boundField) {
    _queryDirtyField = _createQueryDirtyField(
      metadata: metadata,
      nodeIndex: nodeIndex,
      queryIndex: queryIndex,
    );
  }

  /// Inserts a `bool {property}` field in the generated view.
  ///
  /// Returns an expression pointing to that field.
  o.Expression _createQueryDirtyField({
    @required CompileQueryMetadata metadata,
    @required int nodeIndex,
    @required int queryIndex,
  }) {
    final selector = metadata.selectors.first.name;
    // This is to avoid churn in the golden files/output while debugging.
    //
    // We can rename the properties after we decide to keep this code branch.
    String property;
    if (nodeIndex == -1) {
      // @ViewChild[ren].
      property = '_viewQuery_${selector}_${queryIndex}_isDirty';
    } else {
      // @ContentChild[ren].
      property = '_query_${selector}_${nodeIndex}_${queryIndex}_isDirty';
    }
    // bool _query_foo_0_0_isDirty = true;
    _classField = new o.ClassField(property,
        outputType: o.BOOL_TYPE,
        modifiers: [o.StmtModifier.Private],
        initializer: o.literal(true));
    return new o.ReadClassMemberExpr(property);
  }

  @override
  void _setParentQueryAsDirty(CompileView origin) {
    final o.ReadPropExpr queryDirtyField = getPropertyInView(
      _queryDirtyField,
      origin,
      _queryRoot,
    );
    origin.dirtyParentQueriesMethod.addStmt(
      queryDirtyField.set(o.literal(true)).toStmt(),
    );
  }

  @override
  o.AbstractClassPart createClassField() => _classField;

  @override
  List<o.Statement> createDynamicUpdates() {
    final statements = <o.Statement>[]
      ..addAll(_createUpdates())
      ..add(_queryDirtyField.set(o.literal(false)).toStmt());
    return [
      new o.IfStmt(
        _queryDirtyField,
        statements,
      ),
    ];
  }

  @override
  List<o.Statement> createImmediateUpdates() {
    return _isStatic ? _createUpdates() : const [];
  }

  List<o.Statement> _createUpdates() {
    o.Expression values = o.literalArr(_buildQueryResult(_values));
    if (_isSingle) {
      values = values.prop('first');
    }
    if (_values.hasNestedViews) {
      values = _flattenNodes(values);
    }
    return [_boundField.prop(metadata.propertyName).set(values).toStmt()];
  }
}

void addQueryToTokenMap(
  CompileTokenMap<List<CompileQuery>> map,
  CompileQuery query,
) {
  for (final selector in query.metadata.selectors) {
    var entry = map.get(selector);
    if (entry == null) {
      entry = [];
      map.add(selector, entry);
    }
    entry.add(query);
  }
}
