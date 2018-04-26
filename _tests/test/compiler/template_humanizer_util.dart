import 'package:angular/src/compiler/output/dart_emitter.dart';
import 'package:angular/src/compiler/template_ast.dart';

import 'expression_parser/unparser.dart' show Unparser;

var expressionUnparser = new Unparser();

class TemplateHumanizer implements TemplateAstVisitor<void, Null> {
  bool includeSourceSpan;
  List<dynamic> result = [];
  TemplateHumanizer(this.includeSourceSpan);

  void visitNgContainer(NgContainerAst ast, _) {
    var res = [NgContainerAst];
    result.add(_appendContext(ast, res));
    templateVisitAll(this, ast.children);
  }

  void visitNgContent(NgContentAst ast, _) {
    var res = [NgContentAst];
    result.add(_appendContext(ast, res));
  }

  void visitEmbeddedTemplate(EmbeddedTemplateAst ast, _) {
    var res = [EmbeddedTemplateAst];
    result.add(_appendContext(ast, res));
    templateVisitAll(this, ast.attrs);
    templateVisitAll(this, ast.outputs);
    templateVisitAll(this, ast.references);
    templateVisitAll(this, ast.variables);
    templateVisitAll(this, ast.directives);
    templateVisitAll(this, ast.children);
  }

  void visitElement(ElementAst ast, _) {
    var res = [ElementAst, ast.name];
    result.add(_appendContext(ast, res));
    templateVisitAll(this, ast.attrs);
    templateVisitAll(this, ast.inputs);
    templateVisitAll(this, ast.outputs);
    templateVisitAll(this, ast.references);
    templateVisitAll(this, ast.directives);
    templateVisitAll(this, ast.children);
  }

  void visitReference(ReferenceAst ast, _) {
    var res = [ReferenceAst, ast.name, ast.value];
    result.add(_appendContext(ast, res));
  }

  void visitVariable(VariableAst ast, _) {
    var res = [VariableAst, ast.name, ast.value];
    if (ast.type != null) {
      res.add(debugOutputAstAsDart(ast.type));
    }
    result.add(_appendContext(ast, res));
  }

  void visitEvent(BoundEventAst ast, _) {
    var res = [
      BoundEventAst,
      ast.name,
      null, // TODO: remove
      expressionUnparser.unparse(ast.handler)
    ];
    result.add(_appendContext(ast, res));
  }

  void visitElementProperty(BoundElementPropertyAst ast, _) {
    var res = [
      BoundElementPropertyAst,
      ast.type,
      ast.name,
      expressionUnparser.unparse(ast.value),
      ast.unit
    ];
    result.add(_appendContext(ast, res));
  }

  void visitAttr(AttrAst ast, _) {
    var res = [AttrAst, ast.name, ast.value];
    result.add(_appendContext(ast, res));
  }

  void visitBoundText(BoundTextAst ast, _) {
    var res = [BoundTextAst, expressionUnparser.unparse(ast.value)];
    result.add(_appendContext(ast, res));
  }

  void visitText(TextAst ast, _) {
    var res = [TextAst, ast.value];
    result.add(_appendContext(ast, res));
  }

  void visitDirective(DirectiveAst ast, _) {
    var res = [DirectiveAst, ast.directive];
    result.add(_appendContext(ast, res));
    templateVisitAll(this, ast.inputs);
    templateVisitAll(this, ast.hostProperties);
    templateVisitAll(this, ast.hostEvents);
  }

  void visitDirectiveProperty(BoundDirectivePropertyAst ast, _) {
    var res = [
      BoundDirectivePropertyAst,
      ast.directiveName,
      expressionUnparser.unparse(ast.value)
    ];
    result.add(_appendContext(ast, res));
  }

  void visitProvider(ProviderAst ast, _) {}

  List<dynamic> _appendContext(TemplateAst ast, List<dynamic> input) {
    if (!includeSourceSpan) return input;
    input.add(ast.sourceSpan.text);
    return input;
  }
}

String sourceInfo(TemplateAst ast) {
  return '${ast.sourceSpan.text}: ${ast.sourceSpan.start.offset}';
}

List<dynamic> humanizeContentProjection(List<TemplateAst> templateAsts) {
  var humanizer = new TemplateContentProjectionHumanizer();
  templateVisitAll(humanizer, templateAsts);
  return humanizer.result;
}

class TemplateContentProjectionHumanizer
    implements TemplateAstVisitor<void, Null> {
  List<dynamic> result = [];

  void visitNgContainer(NgContainerAst ast, _) {
    templateVisitAll(this, ast.children);
  }

  void visitNgContent(NgContentAst ast, _) {
    result.add(["ng-content", ast.ngContentIndex]);
  }

  void visitEmbeddedTemplate(EmbeddedTemplateAst ast, _) {
    result.add(["template", ast.ngContentIndex]);
    templateVisitAll(this, ast.children);
  }

  void visitElement(ElementAst ast, _) {
    result.add([ast.name, ast.ngContentIndex]);
    templateVisitAll(this, ast.children);
  }

  void visitReference(ReferenceAst ast, _) {}

  void visitVariable(VariableAst ast, _) {}

  void visitEvent(BoundEventAst ast, _) {}

  void visitElementProperty(BoundElementPropertyAst ast, _) {}

  void visitAttr(AttrAst ast, _) {}

  void visitBoundText(BoundTextAst ast, _) {
    result.add([
      '''#text(${ expressionUnparser . unparse ( ast . value )})''',
      ast.ngContentIndex
    ]);
  }

  void visitText(TextAst ast, _) {
    result.add(['#text(${ast.value})', ast.ngContentIndex]);
  }

  void visitDirective(DirectiveAst ast, _) {}

  void visitDirectiveProperty(BoundDirectivePropertyAst ast, _) {}

  void visitProvider(ProviderAst ast, _) {}
}

List<dynamic> humanizeTplAst(List<TemplateAst> templateAsts) {
  var humanizer = new TemplateHumanizer(false);
  templateVisitAll(humanizer, templateAsts);
  return humanizer.result;
}

List<dynamic> humanizeTplAstSourceSpans(List<TemplateAst> templateAsts) {
  var humanizer = new TemplateHumanizer(true);
  templateVisitAll(humanizer, templateAsts);
  return humanizer.result;
}
