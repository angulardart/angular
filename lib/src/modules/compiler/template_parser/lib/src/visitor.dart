library angular2_template_parser.src.visitor;

import 'ast.dart';

part 'visitor/unparser.dart';

/// [Visitor] interface is provided to an [NgAstNode] node via
/// the `visit(Visitor visitor)` method, and can be used to do
/// all the things that visitors do.
///
abstract class Visitor {
  const Visitor();

  void visitAttribute(NgAttribute node);

  void visitBinding(NgBinding node);

  void visitComment(NgComment node);

  void visitElement(NgElement node);

  void visitInterpolation(NgInterpolation node);

  void visitProperty(NgProperty node);

  void visitEvent(NgEvent node);

  void visitText(NgText node);
}
