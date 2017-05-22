import 'package:source_span/source_span.dart';

import "../output/output_ast.dart" as o;
import "../template_ast.dart" show TemplateAst;
import "compile_view.dart" show CompileView;

class _DebugState {
  num nodeIndex;
  TemplateAst sourceAst;
  _DebugState(this.nodeIndex, this.sourceAst);
}

var NULL_DEBUG_STATE = new _DebugState(null, null);

/// Creates a list of statements for a method body that include debug context.
///
/// Use resetDebugInfo to provide an anchor to the ast node for which we are
/// about to generate code for.
///
/// Use addStmt/addStmts to add statements at the current checkpoint.
class CompileMethod {
  _DebugState _newState = NULL_DEBUG_STATE;
  _DebugState _currState = NULL_DEBUG_STATE;
  bool _debugEnabled;
  final _bodyStatements = <o.Statement>[];
  int _curNodeIndex;
  SourceLocation _curSourceLocation;

  CompileMethod(CompileView view) {
    _debugEnabled = view.genConfig.genDebugInfo;
  }
  void _updateDebugContextIfNeeded() {
    if ((_newState.nodeIndex != _currState.nodeIndex) ||
        (_newState.sourceAst != _currState.sourceAst)) {
      var expr = _updateDebugContext(this._newState);
      if (expr != null) {
        _bodyStatements.add(expr.toStmt());
      }
    }
  }

  o.Expression _updateDebugContext(_DebugState newState) {
    _currState = _newState = newState;
    if (_debugEnabled) {
      var sourceLocation = newState.sourceAst != null
          ? newState.sourceAst.sourceSpan.start
          : null;
      if (_curNodeIndex == newState.nodeIndex &&
          sourceLocation?.line == _curSourceLocation?.line &&
          sourceLocation?.column == _curSourceLocation?.column) {
        return null;
      }
      _curNodeIndex = newState.nodeIndex;
      _curSourceLocation = sourceLocation;
      return new o.InvokeMemberMethodExpr('dbg', [
        o.literal(newState.nodeIndex),
        sourceLocation != null ? o.literal(sourceLocation.line) : o.NULL_EXPR,
        sourceLocation != null ? o.literal(sourceLocation.column) : o.NULL_EXPR
      ]);
    } else {
      return null;
    }
  }

  o.Expression resetDebugInfoExpr(num nodeIndex, TemplateAst templateAst) {
    var res = _updateDebugContext(new _DebugState(nodeIndex, templateAst));
    return res ?? o.NULL_EXPR;
  }

  void resetDebugInfo(num nodeIndex, TemplateAst templateAst) {
    _newState = new _DebugState(nodeIndex, templateAst);
  }

  void addStmt(o.Statement stmt) {
    _updateDebugContextIfNeeded();
    _bodyStatements.add(stmt);
  }

  void addStmts(List<o.Statement> stmts) {
    _updateDebugContextIfNeeded();
    _bodyStatements.addAll(stmts);
  }

  List<o.Statement> finish() {
    return _bodyStatements;
  }

  bool get isEmpty => _bodyStatements.isEmpty;
}
