import '../identifiers.dart';
import '../output/output_ast.dart' as o;
import 'compile_pipe.dart' show CompilePipe;
import 'compile_view.dart' show CompileView;
import 'constants.dart' show EventHandlerVars;
import 'expression_converter.dart';
import 'view_compiler_utils.dart' show getPropertyInView, unsafeCast;

/// State shared amongst all name resolvers of a view, regardless of scope.
class _ViewNameResolverState {
  final Map<String, o.Expression> locals = {};
  final Map<String, o.OutputType> localTypes = {};
  final Map<String, o.DeclareVarStmt> localDeclarations = {};
  final CompileView view;

  /// Used to generate unique field names for literal list bindings.
  var literalListCount = 0;

  /// Used to generate unique field names for literal map bindings.
  var literalMapCount = 0;

  /// Used to generate unique field names for property bindings.
  var bindingCount = 0;

  _ViewNameResolverState(this.view);
}

/// Name resolver for binding expressions that resolves locals and pipes.
///
/// Provides unique names for literal arrays and maps for the view.
class ViewNameResolver implements NameResolver {
  final _localsInScope = <String>{};
  final _ViewNameResolverState _state;

  /// Creates a name resolver for [view].
  ViewNameResolver(CompileView view) : _state = _ViewNameResolverState(view);

  /// Creates a scoped name resolver with shared [_state].
  ViewNameResolver._scope(this._state);

  void addLocal(String name, o.Expression e, [o.OutputType type]) {
    _state.locals[name] = e;
    _state.localTypes[name] = type;
  }

  @override
  o.Expression getLocal(String name) {
    if (name == EventHandlerVars.event.name) {
      return EventHandlerVars.event;
    }
    if (!_state.localDeclarations.containsKey(name)) {
      // Check if a local for `name` exists.
      var currView = _state.view;
      var result = _state.locals[name];
      while (result == null && currView.declarationElement.view != null) {
        currView = currView.declarationElement.view;
        result = currView.nameResolver._state.locals[name];
      }
      if (result == null) return null; // No local for `name`.
      var expression = getPropertyInView(result, _state.view, currView);
      final type = currView.nameResolver._state.localTypes[name];
      if (type != null && type != o.DYNAMIC_TYPE) {
        expression = unsafeCast(expression, type);
      }
      final modifiers = [o.StmtModifier.Final];
      // Cache in shared view state for reuse if requested in other scopes.
      // Since locals are view wide, the variable name is guaranteed to be
      // unique in any generated method.
      _state.localDeclarations[name] = o.DeclareVarStmt(
        'local_$name',
        expression,
        null,
        modifiers,
      );
    }
    _localsInScope.add(name); // Cache local in this method scope.
    return o.ReadVarExpr(_state.localDeclarations[name].name);
  }

  @override
  List<o.Statement> getLocalDeclarations() {
    final declarations = <o.Statement>[];
    for (final name in _localsInScope) {
      declarations.add(_state.localDeclarations[name]);
    }
    return declarations;
  }

  @override
  o.Expression callPipe(
    String name,
    o.Expression input,
    List<o.Expression> args,
  ) {
    return CompilePipe.createCallPipeExpression(_state.view, name, input, args);
  }

  @override
  o.Expression createLiteralList(
    List<o.Expression> values, {
    o.OutputType type,
  }) {
    if (values.isEmpty) {
      return o.importExpr(Identifiers.emptyListLiteral);
    }
    final proxyFieldName = '_arr_${_state.literalListCount++}';
    final proxyExpr = o.ReadClassMemberExpr(proxyFieldName);
    final proxyParams = <o.FnParam>[];
    final proxyReturnEntries = <o.Expression>[];
    final valueCount = values.length;
    for (var i = 0; i < valueCount; i++) {
      final paramName = 'p$i';
      proxyParams.add(o.FnParam(paramName));
      proxyReturnEntries.add(o.variable(paramName));
    }
    final listType = _createListTypeFrom(type);
    final pureProxyType = o.FunctionType(
      listType,
      List.filled(valueCount, listType.of),
    );
    _state.view.createPureProxy(
      o.fn(
        proxyParams,
        [o.ReturnStatement(o.literalArr(proxyReturnEntries))],
        o.ArrayType(o.DYNAMIC_TYPE),
      ),
      valueCount,
      proxyExpr,
      pureProxyType: pureProxyType,
    );
    return proxyExpr.callFn(values);
  }

  @override
  int createUniqueBindIndex() => _state.bindingCount++;

  @override
  ViewNameResolver scope() => ViewNameResolver._scope(_state);
}

/// Creates a List<T> type assignable to [type].
///
/// It's possible that [type] can't be assigned a list, in which case we rely on
/// analysis of the generated code to report the incompatibility.
o.ArrayType _createListTypeFrom(o.OutputType type) {
  if (type is o.ExternalType &&
      type.typeParams.isNotEmpty &&
      (type.value.name == 'List' ||
          type.value.name == 'Iterable' ||
          type.value.name == 'dynamic')) {
    return o.ArrayType(type.typeParams.first);
  }
  return o.ArrayType(o.DYNAMIC_TYPE);
}
