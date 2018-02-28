import 'package:angular/src/compiler/output/output_ast.dart' as o;

/// Interface implemented by compiler backend to provide persistant storage
/// of instances for AppView.
abstract class ViewStorage {
  ViewStorageItem allocate(String name,
      {o.OutputType outputType,
      List<o.StmtModifier> modifiers,
      o.Expression initializer});

  o.Expression buildWriteExpr(ViewStorageItem item, o.Expression value);
  o.Expression buildReadExpr(ViewStorageItem item);
}

class ViewStorageItem {
  final String name;
  final o.OutputType outputType;
  final List<o.StmtModifier> modifiers;
  final o.Expression initializer;
  ViewStorageItem(this.name,
      {this.outputType, this.modifiers, this.initializer});
}
