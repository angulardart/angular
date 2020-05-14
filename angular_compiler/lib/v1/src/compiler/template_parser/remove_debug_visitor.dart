import 'package:meta/meta.dart';
import 'package:angular_ast/angular_ast.dart';

/// Removes attributes that start with `'debug'`.
///
/// TODO(b/155218654): This code is intended to be **EXPERIMENTAL**.
@experimental
class RemoveDebugAttributesVisitor extends RecursiveTemplateAstVisitor<void> {
  const RemoveDebugAttributesVisitor();

  @override
  TemplateAst visitAttribute(AttributeAst astNode, [_]) {
    if (astNode.name.toLowerCase().startsWith('debug')) {
      return null;
    }
    return super.visitAttribute(astNode);
  }
}
