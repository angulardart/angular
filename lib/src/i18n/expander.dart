import "package:angular2/src/compiler/html_ast.dart"
    show
        HtmlAst,
        HtmlAstVisitor,
        HtmlElementAst,
        HtmlAttrAst,
        HtmlTextAst,
        HtmlCommentAst,
        HtmlExpansionAst,
        HtmlExpansionCaseAst,
        htmlVisitAll;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

/**
 * Expands special forms into elements.
 *
 * For example,
 *
 * ```
 * { messages.length, plural,
 *   =0 {zero}
 *   =1 {one}
 *   =other {more than one}
 * }
 * ```
 *
 * will be expanded into
 *
 * ```
 * <ul [ngPlural]="messages.length">
 *   <template [ngPluralCase]="0"><li i18n="plural_0">zero</li></template>
 *   <template [ngPluralCase]="1"><li i18n="plural_1">one</li></template>
 *   <template [ngPluralCase]="other"><li i18n="plural_other">more than one</li></template>
 * </ul>
 * ```
 */
ExpansionResult expandNodes(List<HtmlAst> nodes) {
  var e = new _Expander();
  var n = htmlVisitAll(e, nodes) as List<HtmlAst>;
  return new ExpansionResult(n, e.expanded);
}

class ExpansionResult {
  List<HtmlAst> nodes;
  bool expanded;
  ExpansionResult(this.nodes, this.expanded) {}
}

class _Expander implements HtmlAstVisitor {
  bool expanded = false;
  _Expander() {}
  dynamic visitElement(HtmlElementAst ast, dynamic context) {
    return new HtmlElementAst(
        ast.name,
        ast.attrs,
        htmlVisitAll(this, ast.children) as List<HtmlAttrAst>,
        ast.sourceSpan,
        ast.startSourceSpan,
        ast.endSourceSpan);
  }

  dynamic visitAttr(HtmlAttrAst ast, dynamic context) {
    return ast;
  }

  dynamic visitText(HtmlTextAst ast, dynamic context) {
    return ast;
  }

  dynamic visitComment(HtmlCommentAst ast, dynamic context) {
    return ast;
  }

  dynamic visitExpansion(HtmlExpansionAst ast, dynamic context) {
    this.expanded = true;
    return ast.type == "plural"
        ? _expandPluralForm(ast)
        : _expandDefaultForm(ast);
  }

  dynamic visitExpansionCase(HtmlExpansionCaseAst ast, dynamic context) {
    throw new BaseException("Should not be reached");
  }
}

HtmlElementAst _expandPluralForm(HtmlExpansionAst ast) {
  var children = ast.cases.map((c) {
    var expansionResult = expandNodes(c.expression);
    List<HtmlAttrAst> i18nAttrs = expansionResult.expanded
        ? []
        : [
            new HtmlAttrAst(
                "i18n", '''${ ast . type}_${ c . value}''', c.valueSourceSpan)
          ];
    return new HtmlElementAst(
        '''template''',
        [new HtmlAttrAst("ngPluralCase", c.value, c.valueSourceSpan)],
        [
          new HtmlElementAst('''li''', i18nAttrs, expansionResult.nodes,
              c.sourceSpan, c.sourceSpan, c.sourceSpan)
        ],
        c.sourceSpan,
        c.sourceSpan,
        c.sourceSpan);
  }).toList();
  var switchAttr =
      new HtmlAttrAst("[ngPlural]", ast.switchValue, ast.switchValueSourceSpan);
  return new HtmlElementAst("ul", [switchAttr], children, ast.sourceSpan,
      ast.sourceSpan, ast.sourceSpan);
}

HtmlElementAst _expandDefaultForm(HtmlExpansionAst ast) {
  var children = ast.cases.map((c) {
    var expansionResult = expandNodes(c.expression);
    List<HtmlAttrAst> i18nAttrs = expansionResult.expanded
        ? []
        : [
            new HtmlAttrAst(
                "i18n", '''${ ast . type}_${ c . value}''', c.valueSourceSpan)
          ];
    return new HtmlElementAst(
        '''template''',
        [new HtmlAttrAst("ngSwitchWhen", c.value, c.valueSourceSpan)],
        [
          new HtmlElementAst('''li''', i18nAttrs, expansionResult.nodes,
              c.sourceSpan, c.sourceSpan, c.sourceSpan)
        ],
        c.sourceSpan,
        c.sourceSpan,
        c.sourceSpan);
  }).toList();
  var switchAttr =
      new HtmlAttrAst("[ngSwitch]", ast.switchValue, ast.switchValueSourceSpan);
  return new HtmlElementAst("ul", [switchAttr], children, ast.sourceSpan,
      ast.sourceSpan, ast.sourceSpan);
}
