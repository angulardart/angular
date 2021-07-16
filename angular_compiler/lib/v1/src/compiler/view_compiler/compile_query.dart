import '../compile_metadata.dart' show CompileQueryMetadata, CompileTokenMap;
import '../identifiers.dart';
import '../output/output_ast.dart' as o;
import 'compile_element.dart' show CompileElement;
import 'compile_view.dart' show CompileView;
import 'ir/provider_source.dart';
import 'ir/view_storage.dart';
import 'view_compiler_utils.dart'
    show getPropertyInView, replaceReadClassMemberInExpression;

const _viewQueryNodeIndex = -1;

/// The value of a static query result.
class _QueryValue {
  _QueryValue(this.value, this.changeDetectorRef);

  /// A reference to the value of this query result.
  final o.Expression value;

  /// A reference to the associated `ChangeDetectorRef` of the query result.
  final o.Expression? changeDetectorRef;

  /// Whether this value is an OnPush component with a `ChangeDetectorRef`.
  bool get hasChangeDetectorRef => changeDetectorRef != null;
}

/// The values of all query results nested within an embedded view.
class _NestedQueryValues {
  _NestedQueryValues(this.view);

  /// Compiled template associated with [valuesOrTemplates].
  final CompileView? view;

  /// Values or embedded templates of the query.
  ///
  /// Elements should be either a [_QueryValue] or [_NestedQueryValues].
  final valuesOrTemplates = <Object>[];

  /// Whether there are query results immediately available to this view.
  ///
  /// These are results *not* in nested embedded views.
  bool get hasStaticValues => valuesOrTemplates.any((v) => v is _QueryValue);

  /// Whether there are nested embedded views in this instance.
  bool get hasNestedViews =>
      valuesOrTemplates.any((v) => v is _NestedQueryValues);
}

/// The query results of a view.
class _QueryResults {
  _QueryResults(this.values, this.withChangeDetectorRefs);

  /// The expressions used to populate a query.
  final List<o.Expression> values;

  /// A subset of [values] with associated change detectors.
  ///
  /// These [values] are backed by OnPush components, whose change detectors
  /// must be registered to implement `ChangeDetectorRef.markChildForCheck()`.
  final List<_QueryValue> withChangeDetectorRefs;
}

/// Compiles `@{Content|View}Child[ren]` to template IR.
abstract class CompileQuery {
  /// An expression that accesses the component's instance.
  ///
  /// In practice, this is almost always `this.ctx`.
  final ProviderSource? _boundDirective;

  /// Extracted metadata information from the user-code.
  final CompileQueryMetadata metadata;

  /// Compiled view of the `@Component` that this query originated from.
  final CompileView _queryRoot;

  /// A combination of direct expressions and nested templates needed.
  ///
  /// This is built-up during the lifetime of this class.
  final _NestedQueryValues _values;

  factory CompileQuery({
    required CompileQueryMetadata metadata,
    required ViewStorage storage,
    required CompileView queryRoot,
    required ProviderSource? boundDirective,
    required int? nodeIndex,
    required int queryIndex,
  }) {
    return _ListCompileQuery(
      metadata,
      storage,
      queryRoot,
      boundDirective,
      nodeIndex: nodeIndex,
      queryIndex: queryIndex,
    );
  }

  factory CompileQuery.viewQuery({
    required CompileQueryMetadata metadata,
    required ViewStorage storage,
    required CompileView queryRoot,
    required ProviderSource boundDirective,
    required int queryIndex,
  }) {
    return _ListCompileQuery(
      metadata,
      storage,
      queryRoot,
      boundDirective,
      nodeIndex: _viewQueryNodeIndex,
      queryIndex: queryIndex,
    );
  }

  CompileQuery._base(
    this.metadata,
    this._queryRoot,
    this._boundDirective,
  ) : _values = _NestedQueryValues(_queryRoot);

  /// Whether the query is only setting a single value, not a list-like object.
  ///
  /// This aligns with `@ViewChild` and `@ContentChild`.
  bool get _isSingle => metadata.first;

  /// Whether the query is entirely static, i.e. there are no `<template>`s.
  bool get _isStatic => !_shouldMapNestedViews(_values);

  /// Whether a nested query for [values] returns multiple results.
  ///
  /// These could be in the form of a list literal, or a call to
  /// `mapNestedViews` or `flattenNodes`.
  bool _hasMultipleResults(_NestedQueryValues values) {
    final results = values.valuesOrTemplates;
    if (_isSingle) {
      return results.isNotEmpty && results.first is _NestedQueryValues;
    } else {
      return values.hasNestedViews || results.length > 1;
    }
  }

  /// Whether the query for [values] requires use of `mapNestedViews`.
  bool _shouldMapNestedViews(_NestedQueryValues values) {
    if (_isSingle) {
      // When querying for a single result, `mapNestedViews` is only necessary
      // if the first value is nested in an embedded view.
      final results = values.valuesOrTemplates;
      return results.isNotEmpty && results.first is _NestedQueryValues;
    } else {
      return values.hasNestedViews;
    }
  }

  /// Adds an expression [result] that originates from an [origin] view.
  ///
  /// The result of a given query is the sum of all invocations to this method.
  /// Some of the expressions are simple (i.e. reads from an existing class
  /// field) and others require proxy-ing through `mapNestedViews` in order to
  /// determine what `<template>`s are currently active.
  ///
  /// If [result] is a component instance that uses the OnPush change detection
  /// strategy, [changeDetectorRef] should be its associated `ChangeDetectorRef`
  /// instance. Otherwise this parameter should be null.
  void addQueryResult(
    CompileView origin,
    o.Expression result,
    o.Expression? changeDetectorRef,
  ) {
    // Determine if we have a path of embedded templates.
    final elementPath = _resolvePathToRoot(origin);
    var viewValues = _values;

    // If we do, then continue building QueryValues, a tree-like data structure.
    for (final element in elementPath) {
      final valuesOrTemplates = viewValues.valuesOrTemplates;
      final last = valuesOrTemplates.isNotEmpty ? valuesOrTemplates.last : null;
      if (last is _NestedQueryValues && last.view == element.embeddedView) {
        viewValues = last;
      } else {
        assert(element.hasEmbeddedView);
        final newViewValues = _NestedQueryValues(element.embeddedView);
        valuesOrTemplates.add(newViewValues);
        viewValues = newViewValues;
      }
    }

    // Add it to the applicable part of the view (either root or embedded).
    viewValues.valuesOrTemplates.add(_QueryValue(result, changeDetectorRef));

    // Finally, if this result doesn't come from the root, it means that some
    // change in an embedded view needs to invalidate the state of the previous
    // query.
    if (elementPath.isNotEmpty) {
      _setParentQueryAsDirty(origin);
    }
  }

  /// Returns the query results that the user-code receives.
  _QueryResults _buildQueryResults(_NestedQueryValues values) {
    // The final list of results. This may either be a flat list of static
    // results, or a nested list of static results and `mapNestedViews` calls:
    //
    //  * [staticResult, staticResult]
    //  * [staticResult, staticResult, ...mapNestedViews]
    //
    final results = <o.Expression>[];
    final valuesWithChangeDetectorRefs = <_QueryValue>[];
    final valuesOrTemplates = values.valuesOrTemplates;

    for (final value in valuesOrTemplates) {
      if (value is _QueryValue) {
        results.add(value.value);
        if (value.hasChangeDetectorRef) {
          valuesWithChangeDetectorRefs.add(value);
        }
        // For queries that set a single value, it's unnecessary to include any
        // results after the first static value.
        if (_isSingle) break;
      } else if (value is _NestedQueryValues) {
        var mappedResult = _mapNestedViews(value);
        // If there are other values to query, we want to spread these results
        // into the final list. Otherwise, we want to return these results as-is
        // which are already a list.
        if (valuesOrTemplates.length > 1) {
          mappedResult = mappedResult.spread();
        }
        results.add(mappedResult);
      } else {
        throw StateError('Unexpected type: $value');
      }
    }

    return _QueryResults(results, valuesWithChangeDetectorRefs);
  }

  /// Returns an expression that invokes `_appEl_N.mapNestedViews`.
  ///
  /// This is required to traverse embedded `<template>` views for query matches.
  o.Expression _mapNestedViews(_NestedQueryValues value) {
    final appElementN = value.view!.declarationElement.appViewContainer!;
    // Should return:
    //
    //   appElementN.mapNestedViews(({view.Type} nestedView) {
    //     return /* {expressions} that is List<T> */
    //   });

    // Changes `_el_0` to `nestedView._el_0`.
    o.Expression readFromNestedView(o.Expression expr) {
      return replaceReadClassMemberInExpression(
        expr,
        (_) => o.variable('nestedView'),
      );
    }

    final results = _buildQueryResults(value);
    // If the nested query has multiple results, wrap them in a list.
    final expressions = results.values.length > 1
        ? [o.literalArr(results.values)]
        : results.values;

    final adjustedExpressions = expressions.map(readFromNestedView).toList();
    final adjustedValuesWithChangeDetectorRefs =
        results.withChangeDetectorRefs.map((value) => _QueryValue(
              readFromNestedView(value.value),
              readFromNestedView(value.changeDetectorRef!),
            ));

    // Choose which function to use based on whether the nested query returns
    // multiple results or a single result.
    final mapNestedViews = _hasMultipleResults(value)
        ? 'mapNestedViews'
        : 'mapNestedViewsWithSingleResult';

    // Invokes `appElementN.mapNestedView`.
    return appElementN.callMethod(mapNestedViews, [
      o.fn(
        [o.FnParam('nestedView', value.view!.classType)],
        [
          ..._createAddQueryChangeDetectorRefs(
              adjustedValuesWithChangeDetectorRefs),
          o.ReturnStatement(o.literalVargs(adjustedExpressions)),
        ],
      ),
    ]);
  }

  /// Invoked by [addQueryResult] when the [_queryRoot] is now dirty.
  ///
  /// This means during the next change detection cycle we need to rebuild the
  /// result of the query and invoke the bound setter or field accessor.
  void _setParentQueryAsDirty(CompileView origin);

  /// Returns the path required to traverse back to the [_queryRoot].
  ///
  /// This information is used to build up the [_NestedQueryValues] required to
  /// express and retrieve the contents of the query at runtime.
  ///
  /// * For a simple query of static elements in a template, this is `[]`.
  /// * For a more complex query with embedded `<template>`s, this will be
  ///   the path to that embedded template. So for example, this might be a
  ///   single `[ViewComponent0]` when nested in a single `<template>` and a
  ///   longer `[ViewComponent0, ViewComponent1]` when nested even deeper.
  List<CompileElement> _resolvePathToRoot(CompileView? view) {
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

class _ListCompileQuery extends CompileQuery {
  final ViewStorage _storage;
  final int? _nodeIndex;
  final int _queryIndex;

  /// [CompileView]s that contain a result for this query.
  final _queryResultOrigins = <CompileView>{};

  _ListCompileQuery(
    CompileQueryMetadata metadata,
    this._storage,
    CompileView queryRoot,
    ProviderSource? boundDirective, {
    required int? nodeIndex,
    required int queryIndex,
  })  : _nodeIndex = nodeIndex,
        _queryIndex = queryIndex,
        super._base(metadata, queryRoot, boundDirective);

  ViewStorageItem? _dirtyFieldIfNeeded;

  ViewStorageItem get _dirtyField {
    return _dirtyFieldIfNeeded ??= _createQueryDirtyField(
      metadata: metadata,
      storage: _storage,
      nodeIndex: _nodeIndex,
      queryIndex: _queryIndex,
    );
  }

  /// Inserts a `bool {property}` field in the generated view.
  ///
  /// Returns an expression pointing to that field.
  static ViewStorageItem _createQueryDirtyField({
    required CompileQueryMetadata metadata,
    required ViewStorage storage,
    required int? nodeIndex,
    required int queryIndex,
  }) {
    final selector = metadata.selectors!.first.name;
    // This is to avoid churn in the golden files/output while debugging.
    //
    // We can rename the properties after we decide to keep this code branch.
    String property;
    if (nodeIndex == _viewQueryNodeIndex) {
      // @ViewChild[ren].
      property = '_viewQuery_${selector}_${queryIndex}_isDirty';
    } else {
      // @ContentChild[ren].
      property = '_query_${selector}_${nodeIndex}_${queryIndex}_isDirty';
    }
    // bool _query_foo_0_0_isDirty = true;
    return storage.allocate(
      property,
      outputType: o.BOOL_TYPE,
      modifiers: [o.StmtModifier.Private],
      initializer: o.literal(true),
    );
  }

  @override
  void _setParentQueryAsDirty(CompileView origin) {
    // We do not need a dirty field for queries that never change.
    if (_isStatic) {
      return;
    }
    // Only generate a statement to mark the query dirty in `origin` once.
    if (!_queryResultOrigins.add(origin)) {
      return;
    }
    final queryDirtyField = getPropertyInView(
      _storage.buildReadExpr(_dirtyField),
      origin,
      _queryRoot,
    ) as o.ReadPropExpr;
    origin.dirtyParentQueriesMethod.addStmt(
      queryDirtyField.set(o.literal(true)).toStmt(),
    );
  }

  @override
  List<o.Statement> createDynamicUpdates() {
    if (_isStatic) {
      return const [];
    }
    final statements = <o.Statement>[
      ..._createUpdates(),
      _storage.buildWriteExpr(_dirtyField, o.literal(false)).toStmt()
    ];
    return [
      o.IfStmt(
        _storage.buildReadExpr(_dirtyField),
        statements,
      ),
    ];
  }

  @override
  List<o.Statement> createImmediateUpdates() {
    return _isStatic ? _createUpdates() : const [];
  }

  List<o.Statement> _createUpdates() {
    final results = _buildQueryResults(_values);
    o.Expression result;

    if (_isStatic) {
      // Optimization: Avoid .singleChild = null.
      //
      // Otherwise in build() we would write:
      //   build() {
      //     context.childField = null;
      //   }
      //
      // ... which should be skip-able in the following condition:
      if (_isSingle && results.values.isEmpty) {
        return const [];
      }
      result = _createUpdatesStaticOnly(results.values);
    } else {
      result = _createUpdatesNested(results.values);
    }
    return [
      ..._createAddQueryChangeDetectorRefs(results.withChangeDetectorRefs),
      _boundDirective!
          .build()
          .prop(metadata.propertyName!)
          .set(result)
          .toStmt(),
    ];
  }

  // Only static elements are the result of the query.
  //
  // * If this is for @{Content|View}Child, use the first value.
  // * Else, return the element(s) as a List.
  o.Expression _createUpdatesStaticOnly(List<o.Expression> values) =>
      _isSingle ? values.first : o.literalArr(values);

  // Returns the equivalent of `{list}.isNotEmpty ? {list}.first : null`.
  o.Expression _firstIfNotEmpty(o.Expression list) {
    // If the list contains a static result, it's guaranteed to contain an
    // element so we can safely call `List.first` (which throws on an empty
    // list). Otherwise, if all the results are from nested views, we call
    // `firstOrNull()` to handle a potentially empty list.
    return _values.hasStaticValues ? list.prop('first') : _firstOrNull(list);
  }

  // A single call to "mapNestedViews" or a list literal is the result.
  //
  // * If this is for @{Content|View}Child, return the first value if not empty.
  // * Else, just return the {expression} itself (already a List).
  o.Expression _createUpdatesNested(List<o.Expression> values) {
    // We know there are nested views, so if the length is 1, then it must be a
    // `mapNestedViews` expression which returns a list. Otherwise, we wrap the
    // results in a list literal.
    final value = values.length != 1 ? o.literalArr(values) : values.first;
    return _isSingle ? _firstIfNotEmpty(value) : value;
  }
}

void addQueryToTokenMap(
  CompileTokenMap<List<CompileQuery>> map,
  CompileQuery query,
) {
  for (final selector in query.metadata.selectors!) {
    var entry = map.get(selector);
    if (entry == null) {
      entry = [];
      map.add(selector, entry);
    }
    entry.add(query);
  }
}

/// Returns statements to populate `View.queryChangeDetectorRefs`.
///
/// Generates the following line for each item in [changeDetectorRefs]:
///
/// ```
/// View.queryChangeDetectorRefs[query.value] = query.changeDetectorRef;
/// ```
List<o.Statement> _createAddQueryChangeDetectorRefs(
  Iterable<_QueryValue> queriesWithChangeDetectorRefs,
) {
  final queryChangeDetectorRefs =
      o.importExpr(Views.view).prop('queryChangeDetectorRefs');
  return [
    for (final query in queriesWithChangeDetectorRefs)
      queryChangeDetectorRefs
          .key(query.value)
          .set(query.changeDetectorRef!)
          .toStmt()
  ];
}

final _firstOrNullFn = o.importExpr(Queries.firstOrNull);

/// Returns `listExpression.isNotEmpty ? listExpression.first : null`.
o.Expression _firstOrNull(o.Expression listExpression) =>
    _firstOrNullFn.callFn([listExpression]);
