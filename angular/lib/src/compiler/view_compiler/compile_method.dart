import '../output/output_ast.dart' as o;

import 'constants.dart';

/// Creates a list of statements for a method body that include debug context.
///
/// Use addStmt/addStmts to add statements at the current checkpoint.
class CompileMethod {
  static final _isFirstCheckIfBlock = Expando<bool>();
  final _bodyStatements = <o.Statement>[];

  void addStmt(o.Statement stmt) {
    _bodyStatements.add(stmt);
  }

  void addStmts(List<o.Statement> stmts) {
    if (stmts.isEmpty) return;
    _bodyStatements.addAll(stmts);
  }

  /// If the last added statement is an `if (firstCheck)`, re-use that if-block.
  ///
  /// Otherwise, creates a new if-block and inserts it.
  void addStmtsIfFirstCheck(List<o.Statement> stmts) {
    // This is not the cleanest solution (i.e. it pollutes this class), but
    // otherwise you would need similar code in 10+ places.
    //
    // https://github.com/dart-lang/angular/issues/712#issuecomment-403189258
    final lastStmt = _bodyStatements.isNotEmpty ? _bodyStatements.last : null;
    if (lastStmt is o.IfStmt && _isFirstCheckIfBlock[lastStmt] == true) {
      lastStmt.trueCase.addAll(stmts);
    } else {
      final ifStmt = o.IfStmt(DetectChangesVars.firstCheck, stmts);
      _isFirstCheckIfBlock[ifStmt] = true;
      addStmt(ifStmt);
    }
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
