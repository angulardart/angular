// @dart=2.9

import 'package:angular_compiler/v1/src/compiler/output/dart_emitter.dart';
import 'package:angular_compiler/v1/src/compiler/template_ast.dart';

import 'expression_parser/unparser.dart' show Unparser;

final _expressionUnparser = Unparser();

List<dynamic> humanizeTplAst(List<TemplateAst> templateAsts) {
  var humanizer = _TemplateHumanizer(false);
  templateVisitAll(humanizer, templateAsts, null);
  return humanizer.result;
}

List<dynamic> humanizeTplAstSourceSpans(List<TemplateAst> templateAsts) {
  var humanizer = _TemplateHumanizer(true);
  templateVisitAll(humanizer, templateAsts, null);
  return humanizer.result;
}

class _TemplateHumanizer implements TemplateAstVisitor<void, void> {
  final bool includeSourceSpan;
  final List<dynamic> result = [];
  _TemplateHumanizer(this.includeSourceSpan);

  @override
  void visitNgContainer(NgContainerAst ast, _) {
    var res = <dynamic>[NgContainerAst];
    result.add(_appendContext(ast, res));
    templateVisitAll(this, ast.children, null);
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
    templateVisitAll(this, ast.attrs, null);
    templateVisitAll(this, ast.references, null);
    templateVisitAll(this, ast.variables, null);
    templateVisitAll(this, ast.directives, null);
    templateVisitAll(this, ast.children, null);
  }

  @override
  void visitElement(ElementAst ast, _) {
    var res = [ElementAst, ast.name];
    result.add(_appendContext(ast, res));
    templateVisitAll(this, ast.attrs, null);
    templateVisitAll(this, ast.inputs, null);
    templateVisitAll(this, ast.outputs, null);
    templateVisitAll(this, ast.references, null);
    templateVisitAll(this, ast.directives, null);
    templateVisitAll(this, ast.children, null);
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
      _expressionUnparser.unparse(ast.handler.expression)
    ];
    result.add(_appendContext(ast, res));
  }

  @override
  void visitElementProperty(BoundElementPropertyAst ast, _) {
    var res = [
      BoundElementPropertyAst,
      ast.type,
      ast.name,
      ..._humanizeBoundValue(ast.value),
      ast.unit
    ];
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
    var res = [BoundTextAst, _expressionUnparser.unparse(ast.value)];
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
    templateVisitAll(this, ast.inputs, null);
    templateVisitAll(this, ast.outputs, null);
  }

  @override
  void visitDirectiveProperty(BoundDirectivePropertyAst ast, _) {
    final res = [
      BoundDirectivePropertyAst,
      ast.memberName,
      ..._humanizeBoundValue(ast.value)
    ];
    result.add(_appendContext(ast, res));
  }

  @override
  void visitDirectiveEvent(BoundDirectiveEventAst ast, _) {
    final res = [
      BoundDirectiveEventAst,
      ast.memberName,
      _expressionUnparser.unparse(ast.handler.expression),
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
      res.add(_expressionUnparser.unparse(value.expression));
    } else if (value is BoundI18nMessage) {
      res
        ..add(value.message.text)
        ..add(value.message.metadata.description);
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
  var humanizer = _TemplateContentProjectionHumanizer();
  templateVisitAll(humanizer, templateAsts, null);
  return humanizer.result;
}

class _TemplateContentProjectionHumanizer
    implements TemplateAstVisitor<void, void> {
  List<dynamic> result = [];

  @override
  void visitNgContainer(NgContainerAst ast, _) {
    templateVisitAll(this, ast.children, null);
  }

  @override
  void visitNgContent(NgContentAst ast, _) {
    result.add(['ng-content', ast.ngContentIndex]);
  }

  @override
  void visitEmbeddedTemplate(EmbeddedTemplateAst ast, _) {
    result.add(['template', ast.ngContentIndex]);
    templateVisitAll(this, ast.children, null);
  }

  @override
  void visitElement(ElementAst ast, _) {
    result.add([ast.name, ast.ngContentIndex]);
    templateVisitAll(this, ast.children, null);
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
      '''#text(${_expressionUnparser.unparse(ast.value)})''',
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
