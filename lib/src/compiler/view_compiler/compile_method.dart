import "../output/output_ast.dart" as o;
import "../template_ast.dart" show TemplateAst;
import "compile_view.dart" show CompileView;

class _DebugState {
  num nodeIndex;
  TemplateAst sourceAst;
  _DebugState(this.nodeIndex, this.sourceAst);
}

var NULL_DEBUG_STATE = new _DebugState(null, null);

class CompileMethod {
  CompileView _view;
  _DebugState _newState = NULL_DEBUG_STATE;
  _DebugState _currState = NULL_DEBUG_STATE;
  bool _debugEnabled;
  List<o.Statement> _bodyStatements = [];
  CompileMethod(this._view) {
    this._debugEnabled = this._view.genConfig.genDebugInfo;
  }
  void _updateDebugContextIfNeeded() {
    if (!identical(this._newState.nodeIndex, this._currState.nodeIndex) ||
        !identical(this._newState.sourceAst, this._currState.sourceAst)) {
      var expr = this._updateDebugContext(this._newState);
      if (expr != null) {
        this._bodyStatements.add(expr.toStmt());
      }
    }
  }

  o.Expression _updateDebugContext(_DebugState newState) {
    this._currState = this._newState = newState;
    if (this._debugEnabled) {
      var sourceLocation = newState.sourceAst != null
          ? newState.sourceAst.sourceSpan.start
          : null;
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
    var res = this._updateDebugContext(new _DebugState(nodeIndex, templateAst));
    return res ?? o.NULL_EXPR;
  }

  void resetDebugInfo(num nodeIndex, TemplateAst templateAst) {
    this._newState = new _DebugState(nodeIndex, templateAst);
  }

  void addStmt(o.Statement stmt) {
    this._updateDebugContextIfNeeded();
    this._bodyStatements.add(stmt);
  }

  void addStmts(List<o.Statement> stmts) {
    this._updateDebugContextIfNeeded();
    this._bodyStatements.addAll(stmts);
  }

  List<o.Statement> finish() {
    return this._bodyStatements;
  }

  bool isEmpty() {
    return identical(this._bodyStatements.length, 0);
  }
}
