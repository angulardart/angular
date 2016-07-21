import "parse_util.dart" show ParseSourceSpan;

abstract class HtmlAst {
  ParseSourceSpan sourceSpan;
  dynamic visit(HtmlAstVisitor visitor, dynamic context);
}

class HtmlTextAst implements HtmlAst {
  String value;
  ParseSourceSpan sourceSpan;
  HtmlTextAst(this.value, this.sourceSpan) {}
  dynamic visit(HtmlAstVisitor visitor, dynamic context) {
    return visitor.visitText(this, context);
  }
}

class HtmlExpansionAst implements HtmlAst {
  String switchValue;
  String type;
  List<HtmlExpansionCaseAst> cases;
  ParseSourceSpan sourceSpan;
  ParseSourceSpan switchValueSourceSpan;
  HtmlExpansionAst(this.switchValue, this.type, this.cases, this.sourceSpan,
      this.switchValueSourceSpan) {}
  dynamic visit(HtmlAstVisitor visitor, dynamic context) {
    return visitor.visitExpansion(this, context);
  }
}

class HtmlExpansionCaseAst implements HtmlAst {
  String value;
  List<HtmlAst> expression;
  ParseSourceSpan sourceSpan;
  ParseSourceSpan valueSourceSpan;
  ParseSourceSpan expSourceSpan;
  HtmlExpansionCaseAst(this.value, this.expression, this.sourceSpan,
      this.valueSourceSpan, this.expSourceSpan) {}
  dynamic visit(HtmlAstVisitor visitor, dynamic context) {
    return visitor.visitExpansionCase(this, context);
  }
}

class HtmlAttrAst implements HtmlAst {
  String name;
  String value;
  ParseSourceSpan sourceSpan;
  HtmlAttrAst(this.name, this.value, this.sourceSpan) {}
  dynamic visit(HtmlAstVisitor visitor, dynamic context) {
    return visitor.visitAttr(this, context);
  }
}

class HtmlElementAst implements HtmlAst {
  String name;
  List<HtmlAttrAst> attrs;
  List<HtmlAst> children;
  ParseSourceSpan sourceSpan;
  ParseSourceSpan startSourceSpan;
  ParseSourceSpan endSourceSpan;
  HtmlElementAst(this.name, this.attrs, this.children, this.sourceSpan,
      this.startSourceSpan, this.endSourceSpan) {}
  dynamic visit(HtmlAstVisitor visitor, dynamic context) {
    return visitor.visitElement(this, context);
  }
}

class HtmlCommentAst implements HtmlAst {
  String value;
  ParseSourceSpan sourceSpan;
  HtmlCommentAst(this.value, this.sourceSpan) {}
  dynamic visit(HtmlAstVisitor visitor, dynamic context) {
    return visitor.visitComment(this, context);
  }
}

abstract class HtmlAstVisitor {
  dynamic visitElement(HtmlElementAst ast, dynamic context);
  dynamic visitAttr(HtmlAttrAst ast, dynamic context);
  dynamic visitText(HtmlTextAst ast, dynamic context);
  dynamic visitComment(HtmlCommentAst ast, dynamic context);
  dynamic visitExpansion(HtmlExpansionAst ast, dynamic context);
  dynamic visitExpansionCase(HtmlExpansionCaseAst ast, dynamic context);
}

List<dynamic> htmlVisitAll(HtmlAstVisitor visitor, List<HtmlAst> asts,
    [dynamic context = null]) {
  var result = [];
  asts.forEach((ast) {
    var astResult = ast.visit(visitor, context);
    if (astResult != null) {
      result.add(astResult);
    }
  });
  return result;
}
