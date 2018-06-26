import "../output/output_ast.dart" as o;

/// Creates a list of statements for a method body that include debug context.
///
/// Use resetDebugInfo to provide an anchor to the ast node for which we are
/// about to generate code for.
///
/// Use addStmt/addStmts to add statements at the current checkpoint.
class CompileMethod {
  final _bodyStatements = <o.Statement>[];
  final bool genDebugInfo;

  CompileMethod(this.genDebugInfo);

  void addStmt(o.Statement stmt) {
    _bodyStatements.add(stmt);
  }

  void addStmts(List<o.Statement> stmts) {
    if (stmts.isEmpty) return;
    _bodyStatements.addAll(stmts);
  }

  /// Returns set of variable reads in method.
  Set<String> findReadVarNames() {
    return o.findReadVarNames(_bodyStatements);
  }

  List<o.Statement> finish() {
    return _bodyStatements;
  }

  bool get isEmpty => _bodyStatements.isEmpty;

  bool get isNotEmpty => _bodyStatements.isNotEmpty;
}
