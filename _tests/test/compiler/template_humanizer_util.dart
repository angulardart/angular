import 'package:angular/src/compiler/output/dart_emitter.dart';
import 'package:angular/src/compiler/template_ast.dart';

import 'expression_parser/unparser.dart' show Unparser;

var expressionUnparser = new Unparser();

class TemplateHumanizer implements TemplateAstVisitor {
  bool includeSourceSpan;
  List<dynamic> result = [];
  TemplateHumanizer(this.includeSourceSpan);
  dynamic visitNgContent(NgContentAst ast, dynamic context) {
    var res = [NgContentAst];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitEmbeddedTemplate(EmbeddedTemplateAst ast, dynamic context) {
    var res = [EmbeddedTemplateAst];
    this.result.add(this._appendContext(ast, res));
    templateVisitAll(this, ast.attrs);
    templateVisitAll(this, ast.outputs);
    templateVisitAll(this, ast.references);
    templateVisitAll(this, ast.variables);
    templateVisitAll(this, ast.directives);
    templateVisitAll(this, ast.children);
    return null;
  }

  dynamic visitElement(ElementAst ast, dynamic context) {
    var res = [ElementAst, ast.name];
    this.result.add(this._appendContext(ast, res));
    templateVisitAll(this, ast.attrs);
    templateVisitAll(this, ast.inputs);
    templateVisitAll(this, ast.outputs);
    templateVisitAll(this, ast.references);
    templateVisitAll(this, ast.directives);
    templateVisitAll(this, ast.children);
    return null;
  }

  dynamic visitReference(ReferenceAst ast, dynamic context) {
    var res = [ReferenceAst, ast.name, ast.value];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitVariable(VariableAst ast, dynamic context) {
    var res = [VariableAst, ast.name, ast.value];
    if (ast.type != null) {
      res.add(debugOutputAstAsDart(ast.type));
    }
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitEvent(BoundEventAst ast, dynamic context) {
    var res = [
      BoundEventAst,
      ast.name,
      null, // TODO: remove
      expressionUnparser.unparse(ast.handler)
    ];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitElementProperty(BoundElementPropertyAst ast, dynamic context) {
    var res = [
      BoundElementPropertyAst,
      ast.type,
      ast.name,
      expressionUnparser.unparse(ast.value),
      ast.unit
    ];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitAttr(AttrAst ast, dynamic context) {
    var res = [AttrAst, ast.name, ast.value];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitBoundText(BoundTextAst ast, dynamic context) {
    var res = [BoundTextAst, expressionUnparser.unparse(ast.value)];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitText(TextAst ast, dynamic context) {
    var res = [TextAst, ast.value];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitDirective(DirectiveAst ast, dynamic context) {
    var res = [DirectiveAst, ast.directive];
    this.result.add(this._appendContext(ast, res));
    templateVisitAll(this, ast.inputs);
    templateVisitAll(this, ast.hostProperties);
    templateVisitAll(this, ast.hostEvents);
    return null;
  }

  dynamic visitDirectiveProperty(
      BoundDirectivePropertyAst ast, dynamic context) {
    var res = [
      BoundDirectivePropertyAst,
      ast.directiveName,
      expressionUnparser.unparse(ast.value)
    ];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitProvider(ProviderAst ast, dynamic context) {
    return null;
  }

  List<dynamic> _appendContext(TemplateAst ast, List<dynamic> input) {
    if (!this.includeSourceSpan) return input;
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

class TemplateContentProjectionHumanizer implements TemplateAstVisitor {
  List<dynamic> result = [];
  dynamic visitNgContent(NgContentAst ast, dynamic context) {
    this.result.add(["ng-content", ast.ngContentIndex]);
    return null;
  }

  dynamic visitEmbeddedTemplate(EmbeddedTemplateAst ast, dynamic context) {
    this.result.add(["template", ast.ngContentIndex]);
    templateVisitAll(this, ast.children);
    return null;
  }

  dynamic visitElement(ElementAst ast, dynamic context) {
    this.result.add([ast.name, ast.ngContentIndex]);
    templateVisitAll(this, ast.children);
    return null;
  }

  dynamic visitReference(ReferenceAst ast, dynamic context) {
    return null;
  }

  dynamic visitVariable(VariableAst ast, dynamic context) {
    return null;
  }

  dynamic visitEvent(BoundEventAst ast, dynamic context) {
    return null;
  }

  dynamic visitElementProperty(BoundElementPropertyAst ast, dynamic context) {
    return null;
  }

  dynamic visitAttr(AttrAst ast, dynamic context) {
    return null;
  }

  dynamic visitBoundText(BoundTextAst ast, dynamic context) {
    this.result.add([
      '''#text(${ expressionUnparser . unparse ( ast . value )})''',
      ast.ngContentIndex
    ]);
    return null;
  }

  dynamic visitText(TextAst ast, dynamic context) {
    this.result.add(['#text(${ast.value})', ast.ngContentIndex]);
    return null;
  }

  dynamic visitDirective(DirectiveAst ast, dynamic context) {
    return null;
  }

  dynamic visitDirectiveProperty(
      BoundDirectivePropertyAst ast, dynamic context) {
    return null;
  }

  dynamic visitProvider(ProviderAst ast, dynamic context) {
    return null;
  }
}

class FooAstTransformer implements TemplateAstVisitor {
  dynamic visitNgContent(NgContentAst ast, dynamic context) {
    throw new UnimplementedError();
  }

  dynamic visitEmbeddedTemplate(EmbeddedTemplateAst ast, dynamic context) {
    throw new UnimplementedError();
  }

  dynamic visitElement(ElementAst ast, dynamic context) {
    if (ast.name != "div") return ast;
    return new ElementAst("foo", [], [], [], [], [], [], null, [],
        ast.ngContentIndex, ast.sourceSpan);
  }

  dynamic visitReference(ReferenceAst ast, dynamic context) {
    throw new UnimplementedError();
  }

  dynamic visitVariable(VariableAst ast, dynamic context) {
    throw new UnimplementedError();
  }

  dynamic visitEvent(BoundEventAst ast, dynamic context) {
    throw new UnimplementedError();
  }

  dynamic visitElementProperty(BoundElementPropertyAst ast, dynamic context) {
    throw new UnimplementedError();
  }

  dynamic visitAttr(AttrAst ast, dynamic context) {
    throw new UnimplementedError();
  }

  dynamic visitBoundText(BoundTextAst ast, dynamic context) {
    throw new UnimplementedError();
  }

  dynamic visitText(TextAst ast, dynamic context) {
    throw new UnimplementedError();
  }

  dynamic visitDirective(DirectiveAst ast, dynamic context) {
    throw new UnimplementedError();
  }

  dynamic visitDirectiveProperty(
      BoundDirectivePropertyAst ast, dynamic context) {
    throw new UnimplementedError();
  }

  dynamic visitProvider(ProviderAst ast, dynamic context) {
    throw new UnimplementedError();
  }
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
