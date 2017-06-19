import '../../debug/profile_keys.dart';
import '../identifiers.dart';
import '../output/output_ast.dart' as o;
import 'compile_view.dart';

void genProfileSetup(List<o.Statement> statements) {
  statements.add(o.importExpr(Identifiers.profileSetup).callFn([]).toStmt());
}

void genProfileBuildStart(CompileView view, List<o.Statement> statements) {
  var typeName = _viewToTypeName(view);
  if (typeName == null) return;
  _genProfileMarkStart(
      typeName, view.viewIndex, profileCategoryBuild, statements);
}

void genProfileBuildEnd(CompileView view, List<o.Statement> statements) {
  var typeName = _viewToTypeName(view);
  if (typeName == null) return;
  _genProfileMarkEnd(
      typeName, view.viewIndex, profileCategoryBuild, statements);
}

void genProfileCdStart(CompileView view, List<o.Statement> statements) {
  var typeName = _viewToTypeName(view);
  if (typeName == null) return;
  _genProfileMarkStart(
      typeName, view.viewIndex, profileCategoryChangeDetection, statements);
}

void genProfileCdEnd(CompileView view, List<o.Statement> statements) {
  var typeName = _viewToTypeName(view);
  if (typeName == null) return;
  _genProfileMarkEnd(
      typeName, view.viewIndex, profileCategoryChangeDetection, statements);
}

String _viewToTypeName(CompileView view) =>
    view.component?.type?.name ?? view.declarationElement.component?.type?.name;

void _genProfileMarkStart(String componentTypeName, int viewIndex,
    String category, List<o.Statement> statements) {
  var profileStartExpr = o.importExpr(Identifiers.profileMarkStart).callFn([
    o.literal('$category:$componentTypeName:$viewIndex'),
  ]);
  statements.add(profileStartExpr.toStmt());
}

void _genProfileMarkEnd(String componentTypeName, int viewIndex,
    String category, List<o.Statement> statements) {
  var profileEndExpr = o
      .importExpr(Identifiers.profileMarkEnd)
      .callFn([o.literal('$category:$componentTypeName:$viewIndex')]);
  statements.add(profileEndExpr.toStmt());
}
