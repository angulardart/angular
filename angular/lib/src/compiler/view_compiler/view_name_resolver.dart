import '../identifiers.dart';
import '../output/output_ast.dart' as o;
import 'compile_pipe.dart' show CompilePipe;
import 'compile_view.dart' show CompileView;
import 'constants.dart' show EventHandlerVars;
import 'expression_converter.dart';
import "view_compiler_utils.dart" show getPropertyInView, createPureProxy;

/// Name resolver for binding expressions that resolves locals and pipes.
///
/// Provides unique names for literal arrays and maps for the view.
class ViewNameResolver implements NameResolver {
  final CompileView view;
  final _locals = new Map<String, o.Expression>();
  final List<o.ClassField> _fields = [];

  var literalArrayCount = 0;
  var literalMapCount = 0;
  // Used to generate unique index to use in bound class fields.
  int _bindingIndexCounter = 0;

  ViewNameResolver(this.view);

  void addLocal(String name, o.Expression e) {
    _locals[name] = e;
  }

  void addField(o.ClassField field) {
    _fields.add(field);
  }

  List<o.ClassField> get fields => _fields;

  @override
  o.Expression getLocal(String name) {
    if (name == EventHandlerVars.event.name) {
      return EventHandlerVars.event;
    }
    CompileView currView = view;
    var result = _locals[name];
    while (result == null && currView.declarationElement.view != null) {
      currView = currView.declarationElement.view;
      result = currView.nameResolver._locals[name];
    }
    if (result != null) {
      return getPropertyInView(result, view, currView);
    } else {
      return null;
    }
  }

  @override
  o.Expression callPipe(
      String name, o.Expression input, List<o.Expression> args) {
    return CompilePipe.call(view, name, (new List.from([input])..addAll(args)));
  }

  @override
  o.Expression createLiteralArray(List<o.Expression> values) {
    if (identical(values.length, 0)) {
      return o.importExpr(Identifiers.EMPTY_ARRAY);
    }
    var proxyExpr = new o.ReadClassMemberExpr('_arr_${literalArrayCount++}');
    List<o.FnParam> proxyParams = [];
    List<o.Expression> proxyReturnEntries = [];
    for (var i = 0; i < values.length; i++) {
      var paramName = 'p$i';
      proxyParams.add(new o.FnParam(paramName));
      proxyReturnEntries.add(o.variable(paramName));
    }
    createPureProxy(
        o.fn(
            proxyParams,
            [new o.ReturnStatement(o.literalArr(proxyReturnEntries))],
            new o.ArrayType(o.DYNAMIC_TYPE)),
        values.length,
        proxyExpr,
        view);
    return proxyExpr.callFn(values);
  }

  @override
  o.Expression createLiteralMap(
      List<List<dynamic /* String | o . Expression */ >> entries) {
    if (identical(entries.length, 0)) {
      return o.importExpr(Identifiers.EMPTY_MAP);
    }
    var proxyExpr = new o.ReadClassMemberExpr('_map_${this.literalMapCount++}');
    List<o.FnParam> proxyParams = [];
    List<List<dynamic /* String | o . Expression */ >> proxyReturnEntries = [];
    List<o.Expression> values = [];
    for (var i = 0; i < entries.length; i++) {
      var paramName = 'p$i';
      proxyParams.add(new o.FnParam(paramName));
      proxyReturnEntries.add([entries[i][0], o.variable(paramName)]);
      values.add((entries[i][1] as o.Expression));
    }
    createPureProxy(
        o.fn(
            proxyParams,
            [new o.ReturnStatement(o.literalMap(proxyReturnEntries))],
            new o.MapType(o.DYNAMIC_TYPE)),
        entries.length,
        proxyExpr,
        view);
    return proxyExpr.callFn(values);
  }

  @override
  int createUniqueBindIndex() => _bindingIndexCounter++;
}
