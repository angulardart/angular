import "package:angular2/src/facade/collection.dart" show ListWrapper;
import "package:angular2/src/facade/lang.dart" show isPresent;

import "../output/output_ast.dart" as o;
import "../template_ast.dart" show TemplateAst;
import "compile_view.dart" show CompileView;

class _DebugState {
  num nodeIndex;
  TemplateAst sourceAst;
  _DebugState(this.nodeIndex, this.sourceAst) {}
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
  _updateDebugContextIfNeeded() {
    if (!identical(this._newState.nodeIndex, this._currState.nodeIndex) ||
        !identical(this._newState.sourceAst, this._currState.sourceAst)) {
      var expr = this._updateDebugContext(this._newState);
      if (isPresent(expr)) {
        this._bodyStatements.add(expr.toStmt());
      }
    }
  }

  o.Expression _updateDebugContext(_DebugState newState) {
    this._currState = this._newState = newState;
    if (this._debugEnabled) {
      var sourceLocation = isPresent(newState.sourceAst)
          ? newState.sourceAst.sourceSpan.start
          : null;
      return o.THIS_EXPR.callMethod("debug", [
        o.literal(newState.nodeIndex),
        isPresent(sourceLocation)
            ? o.literal(sourceLocation.line)
            : o.NULL_EXPR,
        isPresent(sourceLocation) ? o.literal(sourceLocation.col) : o.NULL_EXPR
      ]);
    } else {
      return null;
    }
  }

  o.Expression resetDebugInfoExpr(num nodeIndex, TemplateAst templateAst) {
    var res = this._updateDebugContext(new _DebugState(nodeIndex, templateAst));
    return isPresent(res) ? res : o.NULL_EXPR;
  }

  resetDebugInfo(num nodeIndex, TemplateAst templateAst) {
    this._newState = new _DebugState(nodeIndex, templateAst);
  }

  addStmt(o.Statement stmt) {
    this._updateDebugContextIfNeeded();
    this._bodyStatements.add(stmt);
  }

  addStmts(List<o.Statement> stmts) {
    this._updateDebugContextIfNeeded();
    ListWrapper.addAll(this._bodyStatements, stmts);
  }

  List<o.Statement> finish() {
    return this._bodyStatements;
  }

  bool isEmpty() {
    return identical(this._bodyStatements.length, 0);
  }
}
