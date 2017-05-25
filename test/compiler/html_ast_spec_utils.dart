library angular2.test.compiler.html_ast_spec_utils;

import "package:angular2/src/compiler/html_ast.dart"
    show
        HtmlAst,
        HtmlAstVisitor,
        HtmlElementAst,
        HtmlAttrAst,
        HtmlTextAst,
        HtmlCommentAst,
        htmlVisitAll;
import "package:angular2/src/compiler/html_parser.dart"
    show HtmlParseTreeResult;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import 'package:source_span/source_span.dart';

List<dynamic> humanizeDom(HtmlParseTreeResult parseResult) {
  if (parseResult.errors.length > 0) {
    var errorString = parseResult.errors.join("\n");
    throw new BaseException('Unexpected parse errors:\n$errorString');
  }
  var humanizer = new _Humanizer(false);
  htmlVisitAll(humanizer, parseResult.rootNodes);
  return humanizer.result;
}

List<dynamic> humanizeDomSourceSpans(HtmlParseTreeResult parseResult) {
  if (parseResult.errors.length > 0) {
    var errorString = parseResult.errors.join("\n");
    throw new BaseException('Unexpected parse errors:\n$errorString');
  }
  var humanizer = new _Humanizer(true);
  htmlVisitAll(humanizer, parseResult.rootNodes);
  return humanizer.result;
}

String humanizeLineColumn(SourceLocation location) {
  // Retains the old TS-era `ParseSourceLocation` semantics for now.
  return '${location.line }:${location.column}';
}

class _Humanizer implements HtmlAstVisitor {
  bool includeSourceSpan;
  List<dynamic> result = [];
  num elDepth = 0;
  _Humanizer(this.includeSourceSpan);

  @override
  bool visit(HtmlAst ast, dynamic context) => false;

  @override
  dynamic visitElement(HtmlElementAst ast, dynamic context) {
    var res =
        this._appendContext(ast, [HtmlElementAst, ast.name, this.elDepth++]);
    this.result.add(res);
    htmlVisitAll(this, ast.attrs);
    htmlVisitAll(this, ast.children);
    this.elDepth--;
    return null;
  }

  @override
  dynamic visitAttr(HtmlAttrAst ast, dynamic context) {
    var res = this._appendContext(ast, [HtmlAttrAst, ast.name, ast.value]);
    this.result.add(res);
    return null;
  }

  @override
  dynamic visitText(HtmlTextAst ast, dynamic context) {
    var res = this._appendContext(ast, [HtmlTextAst, ast.value, this.elDepth]);
    this.result.add(res);
    return null;
  }

  @override
  dynamic visitComment(HtmlCommentAst ast, dynamic context) {
    var res =
        this._appendContext(ast, [HtmlCommentAst, ast.value, this.elDepth]);
    this.result.add(res);
    return null;
  }

  List<dynamic> _appendContext(HtmlAst ast, List<dynamic> input) {
    if (!this.includeSourceSpan) return input;
    input.add(ast.sourceSpan.text);
    return input;
  }
}
