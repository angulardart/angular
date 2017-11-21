import '../identifiers.dart';
import '../output/output_ast.dart' as o;
import 'compile_pipe.dart' show CompilePipe;
import 'compile_view.dart' show CompileView;
import 'constants.dart' show EventHandlerVars;
import 'expression_converter.dart';
import "view_compiler_utils.dart" show getPropertyInView;

/// State shared amongst all name resolvers of a view, regardless of scope.
class _ViewNameResolverState {
  final List<o.ClassField> fields = [];
  final Map<String, o.Expression> locals = {};
  final Map<String, o.OutputType> localTypes = {};
  final Map<String, o.DeclareVarStmt> localDeclarations = {};
  final CompileView view;

  /// Used to generate unique field names for literal list bindings.
  int literalListCount = 0;

  /// Used to generate unique field names for literal map bindings.
  int literalMapCount = 0;

  /// Used to generate unique field names for property bindings.
  int bindingCount = 0;

  _ViewNameResolverState(this.view);
}

/// Name resolver for binding expressions that resolves locals and pipes.
///
/// Provides unique names for literal arrays and maps for the view.
class ViewNameResolver implements NameResolver {
  final Set<String> _localsInScope = new Set<String>();
  final _ViewNameResolverState _state;

  /// Creates a name resolver for [view].
  ViewNameResolver(CompileView view)
      : _state = new _ViewNameResolverState(view);

  /// Creates a scoped name resolver with shared [_state].
  ViewNameResolver._scope(this._state);

  void addLocal(String name, o.Expression e, [o.OutputType type]) {
    _state.locals[name] = e;
    _state.localTypes[name] = type;
  }

  void addField(o.ClassField field) {
    _state.fields.add(field);
  }

  List<o.ClassField> get fields => _state.fields;

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
      final expression = getPropertyInView(result, _state.view, currView);
      final type = currView.nameResolver._state.localTypes[name];
      final modifiers = [o.StmtModifier.Final];
      // Cache in shared view state for reuse if requested in other scopes.
      // Since locals are view wide, the variable name is guaranteed to be
      // unique in any generated method.
      _state.localDeclarations[name] =
          new o.DeclareVarStmt('local_$name', expression, type, modifiers);
    }
    _localsInScope.add(name); // Cache local in this method scope.
    return new o.ReadVarExpr(_state.localDeclarations[name].name);
  }

  @override
  List<o.Statement> getLocalDeclarations() {
    final declarations = <o.Statement>[];
    for (var name in _localsInScope) {
      declarations.add(_state.localDeclarations[name]);
    }
    return declarations;
  }

  @override
  o.Expression callPipe(
      String name, o.Expression input, List<o.Expression> args) {
    return CompilePipe.createCallPipeExpression(_state.view, name, input, args);
  }

  @override
  o.Expression createLiteralList(List<o.Expression> values) {
    if (identical(values.length, 0)) {
      return o.importExpr(Identifiers.EMPTY_ARRAY);
    }
    var proxyExpr =
        new o.ReadClassMemberExpr('_arr_${_state.literalListCount++}');
    List<o.FnParam> proxyParams = [];
    List<o.Expression> proxyReturnEntries = [];
    for (var i = 0; i < values.length; i++) {
      var paramName = 'p$i';
      proxyParams.add(new o.FnParam(paramName));
      proxyReturnEntries.add(o.variable(paramName));
    }
    _state.view.createPureProxy(
        o.fn(
            proxyParams,
            [new o.ReturnStatement(o.literalArr(proxyReturnEntries))],
            new o.ArrayType(o.DYNAMIC_TYPE)),
        values.length,
        proxyExpr);
    return proxyExpr.callFn(values);
  }

  @override
  o.Expression createLiteralMap(
      List<List<dynamic /* String | o . Expression */ >> entries) {
    if (identical(entries.length, 0)) {
      return o.importExpr(Identifiers.EMPTY_MAP);
    }
    var proxyExpr =
        new o.ReadClassMemberExpr('_map_${_state.literalMapCount++}');
    List<o.FnParam> proxyParams = [];
    List<List<dynamic /* String | o . Expression */ >> proxyReturnEntries = [];
    List<o.Expression> values = [];
    for (var i = 0; i < entries.length; i++) {
      var paramName = 'p$i';
      proxyParams.add(new o.FnParam(paramName));
      proxyReturnEntries.add([entries[i][0], o.variable(paramName)]);
      values.add((entries[i][1] as o.Expression));
    }
    _state.view.createPureProxy(
        o.fn(
            proxyParams,
            [new o.ReturnStatement(o.literalMap(proxyReturnEntries))],
            new o.MapType(o.DYNAMIC_TYPE)),
        entries.length,
        proxyExpr);
    return proxyExpr.callFn(values);
  }

  @override
  int createUniqueBindIndex() => _state.bindingCount++;

  @override
  ViewNameResolver scope() => new ViewNameResolver._scope(_state);
}
