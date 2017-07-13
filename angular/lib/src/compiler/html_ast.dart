import 'package:source_span/source_span.dart';

abstract class HtmlAst {
  SourceSpan get sourceSpan;

  visit(HtmlAstVisitor visitor, dynamic context);
}

class HtmlTextAst implements HtmlAst {
  final String value;
  @override
  final SourceSpan sourceSpan;

  HtmlTextAst(this.value, this.sourceSpan);

  @override
  visit(HtmlAstVisitor visitor, dynamic context) {
    return visitor.visitText(this, context);
  }
}

class HtmlAttrAst implements HtmlAst {
  final String name;
  final String value;

  @override
  final SourceSpan sourceSpan;

  /// True if this attribute has an explicit value.
  final bool hasValue;

  HtmlAttrAst(this.name, this.value, this.sourceSpan, this.hasValue);

  @override
  visit(HtmlAstVisitor visitor, dynamic context) {
    return visitor.visitAttr(this, context);
  }
}

class HtmlElementAst implements HtmlAst {
  final String name;
  final List<HtmlAttrAst> attrs;
  final List<HtmlAst> children;
  @override
  final SourceSpan sourceSpan;
  final SourceSpan startSourceSpan;

  SourceSpan endSourceSpan;

  HtmlElementAst(
    this.name,
    this.attrs,
    this.children,
    this.sourceSpan,
    this.startSourceSpan,
    this.endSourceSpan,
  );

  @override
  visit(HtmlAstVisitor visitor, dynamic context) {
    return visitor.visitElement(this, context);
  }
}

class HtmlCommentAst implements HtmlAst {
  final String value;
  @override
  final SourceSpan sourceSpan;

  HtmlCommentAst(this.value, this.sourceSpan);

  @override
  visit(HtmlAstVisitor visitor, dynamic context) {
    return visitor.visitComment(this, context);
  }
}

abstract class HtmlAstVisitor {
  /// Intercepts node visit for all nodes. If [visit] returns true, it indicates
  /// that the ast node was handled and will prevent visitAll from calling
  /// specific typed visit methods for that node.
  bool visit(HtmlAst astNode, dynamic context) => false;
  dynamic visitElement(HtmlElementAst ast, dynamic context);
  dynamic visitAttr(HtmlAttrAst ast, dynamic context);
  dynamic visitText(HtmlTextAst ast, dynamic context);
  dynamic visitComment(HtmlCommentAst ast, dynamic context);
}

List htmlVisitAll(
  HtmlAstVisitor visitor,
  List<HtmlAst> asts, [
  context,
]) {
  var result = [];
  for (var ast in asts) {
    bool handled = visitor.visit(ast, context);
    if (!handled) {
      var astResult = ast.visit(visitor, context);
      if (astResult != null) {
        result.add(astResult);
      }
    }
  }
  return result;
}
