import 'package:angular/src/compiler/output/dart_emitter.dart';
import 'package:angular/src/compiler/template_ast.dart';

import 'expression_parser/unparser.dart' show Unparser;

var expressionUnparser = Unparser();

class TemplateHumanizer implements TemplateAstVisitor<void, Null> {
  bool includeSourceSpan;
  List<dynamic> result = [];
  TemplateHumanizer(this.includeSourceSpan);

  @override
  void visitNgContainer(NgContainerAst ast, _) {
    var res = <dynamic>[NgContainerAst];
    result.add(_appendContext(ast, res));
    templateVisitAll(this, ast.children);
  }

  @override
  void visitNgContent(NgContentAst ast, _) {
    var res = <dynamic>[NgContentAst];
    result.add(_appendContext(ast, res));
  }

  @override
  void visitEmbeddedTemplate(EmbeddedTemplateAst ast, _) {
    var res = <dynamic>[EmbeddedTemplateAst];
    result.add(_appendContext(ast, res));
    templateVisitAll(this, ast.attrs);
    templateVisitAll(this, ast.references);
    templateVisitAll(this, ast.variables);
    templateVisitAll(this, ast.directives);
    templateVisitAll(this, ast.children);
  }

  @override
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

  @override
  void visitReference(ReferenceAst ast, _) {
    var res = [ReferenceAst, ast.name, ast.value];
    result.add(_appendContext(ast, res));
  }

  @override
  void visitVariable(VariableAst ast, _) {
    var res = [VariableAst, ast.name, ast.value];
    if (ast.type != null) {
      res.add(debugOutputAstAsDart(ast.type));
    }
    result.add(_appendContext(ast, res));
  }

  @override
  void visitEvent(BoundEventAst ast, _) {
    var res = [
      BoundEventAst,
      ast.name,
      null, // TODO: remove
      expressionUnparser.unparse(ast.handler.expression)
    ];
    result.add(_appendContext(ast, res));
  }

  @override
  void visitElementProperty(BoundElementPropertyAst ast, _) {
    var res = [BoundElementPropertyAst, ast.type, ast.name]
      ..addAll(_humanizeBoundValue(ast.value))
      ..add(ast.unit);
    result.add(_appendContext(ast, res));
  }

  @override
  void visitAttr(AttrAst ast, _) {
    var res = [AttrAst, ast.name];
    var attributeValue = ast.value;
    // Theses `AttributeValue` types may eventually extend `TemplateAst` so that
    // this logic could be handled in a visit method; however, for now there are
    // so few cases where this would be beneficially that the cost of having to
    // implement these methods everywhere else outweighs the benefit here.
    if (attributeValue is I18nAttributeValue) {
      res
        ..add(attributeValue.value.text)
        ..add(attributeValue.value.metadata.description);
      if (attributeValue.value.metadata.meaning != null) {
        res.add(attributeValue.value.metadata.meaning);
      }
    } else if (attributeValue is LiteralAttributeValue) {
      res.add(attributeValue.value);
    }
    result.add(_appendContext(ast, res));
  }

  @override
  void visitBoundText(BoundTextAst ast, _) {
    var res = [BoundTextAst, expressionUnparser.unparse(ast.value)];
    result.add(_appendContext(ast, res));
  }

  @override
  void visitText(TextAst ast, _) {
    var res = [TextAst, ast.value];
    result.add(_appendContext(ast, res));
  }

  @override
  void visitDirective(DirectiveAst ast, _) {
    var res = [DirectiveAst, ast.directive];
    result.add(_appendContext(ast, res));
    templateVisitAll(this, ast.inputs);
    templateVisitAll(this, ast.outputs);
  }

  @override
  void visitDirectiveProperty(BoundDirectivePropertyAst ast, _) {
    final res = [BoundDirectivePropertyAst, ast.memberName]
      ..addAll(_humanizeBoundValue(ast.value));
    result.add(_appendContext(ast, res));
  }

  @override
  void visitDirectiveEvent(BoundDirectiveEventAst ast, _) {
    final res = [
      BoundDirectiveEventAst,
      ast.memberName,
      expressionUnparser.unparse(ast.handler.expression),
    ];
    result.add(_appendContext(ast, res));
  }

  @override
  void visitProvider(ProviderAst ast, _) {}

  @override
  void visitI18nText(I18nTextAst ast, _) {
    var res = [I18nTextAst, ast.value.text, ast.value.metadata.description];
    if (ast.value.metadata.meaning != null) {
      res.add(ast.value.metadata.meaning);
    }
    if (ast.value.containsHtml) {
      res.add(ast.value.args);
    }
    result.add(_appendContext(ast, res));
  }

  List<dynamic> _appendContext(TemplateAst ast, List<dynamic> input) {
    if (!includeSourceSpan) return input;
    input.add(ast.sourceSpan.text);
    return input;
  }

  // Theses `BoundValue` types may eventually extend `TemplateAst` so that
  // this logic could be handled in a visit method; however, for now there are
  // so few cases where this would be beneficially that the cost of having to
  // implement these methods everywhere else outweighs the benefit here.
  List<dynamic> _humanizeBoundValue(BoundValue value) {
    final res = <dynamic>[];
    if (value is BoundExpression) {
      res.add(expressionUnparser.unparse(value.expression));
    } else if (value is BoundI18nMessage) {
      res..add(value.message.text)..add(value.message.metadata.description);
      if (value.message.metadata.meaning != null) {
        res.add(value.message.metadata.meaning);
      }
    }
    return res;
  }
}

String sourceInfo(TemplateAst ast) {
  return '${ast.sourceSpan.text}: ${ast.sourceSpan.start.offset}';
}

List<dynamic> humanizeContentProjection(List<TemplateAst> templateAsts) {
  var humanizer = TemplateContentProjectionHumanizer();
  templateVisitAll(humanizer, templateAsts);
  return humanizer.result;
}

class TemplateContentProjectionHumanizer
    implements TemplateAstVisitor<void, Null> {
  List<dynamic> result = [];

  @override
  void visitNgContainer(NgContainerAst ast, _) {
    templateVisitAll(this, ast.children);
  }

  @override
  void visitNgContent(NgContentAst ast, _) {
    result.add(["ng-content", ast.ngContentIndex]);
  }

  @override
  void visitEmbeddedTemplate(EmbeddedTemplateAst ast, _) {
    result.add(["template", ast.ngContentIndex]);
    templateVisitAll(this, ast.children);
  }

  @override
  void visitElement(ElementAst ast, _) {
    result.add([ast.name, ast.ngContentIndex]);
    templateVisitAll(this, ast.children);
  }

  @override
  void visitReference(ReferenceAst ast, _) {}

  @override
  void visitVariable(VariableAst ast, _) {}

  @override
  void visitEvent(BoundEventAst ast, _) {}

  @override
  void visitElementProperty(BoundElementPropertyAst ast, _) {}

  @override
  void visitAttr(AttrAst ast, _) {}

  @override
  void visitBoundText(BoundTextAst ast, _) {
    result.add([
      '''#text(${expressionUnparser.unparse(ast.value)})''',
      ast.ngContentIndex
    ]);
  }

  @override
  void visitText(TextAst ast, _) {
    result.add(['#text(${ast.value})', ast.ngContentIndex]);
  }

  @override
  void visitDirective(DirectiveAst ast, _) {}

  @override
  void visitDirectiveProperty(BoundDirectivePropertyAst ast, _) {}

  @override
  void visitDirectiveEvent(BoundDirectiveEventAst ast, _) {}

  @override
  void visitProvider(ProviderAst ast, _) {}

  @override
  void visitI18nText(I18nTextAst ast, _) {}
}

List<dynamic> humanizeTplAst(List<TemplateAst> templateAsts) {
  var humanizer = TemplateHumanizer(false);
  templateVisitAll(humanizer, templateAsts);
  return humanizer.result;
}

List<dynamic> humanizeTplAstSourceSpans(List<TemplateAst> templateAsts) {
  var humanizer = TemplateHumanizer(true);
  templateVisitAll(humanizer, templateAsts);
  return humanizer.result;
}
