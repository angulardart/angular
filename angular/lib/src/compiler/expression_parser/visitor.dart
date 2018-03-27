import 'package:angular_ast/angular_ast.dart';

import '../compile_metadata.dart';
import 'ast.dart' as legacy;
import 'lexer.dart' as legacy;
import 'parser.dart' as legacy;

/// Parses expressions with the existing view compiler's expression parser.
///
/// TODO: Consider extending the RecursiveAstVisitor, instead.
class LegacyExpressionVisitor implements TemplateAstVisitor<Null, Null> {
  /// Legacy (existing) parser.
  final legacy.Parser _parser;

  final List<CompileIdentifierMetadata> _exports;

  LegacyExpressionVisitor({
    List<CompileIdentifierMetadata> exports: const [],
    legacy.Parser parser,
  })  : _exports = exports,
        _parser = parser ?? new legacy.Parser(new legacy.Lexer());

  // Nodes that do not have any expressions.
  // ---------------------------------------------------------------------------

  @override
  visitAnnotation(_, [__]) => null;

  @override
  visitBanana(_, [__]) => null;

  @override
  visitCloseElement(_, [__]) => null;

  @override
  visitComment(_, [__]) => null;

  @override
  visitEmbeddedContent(_, [__]) => null;

  @override
  visitExpression(_, [__]) => null;

  @override
  visitLetBinding(_, [__]) => null;

  @override
  visitReference(_, [__]) => null;

  @override
  visitStar(_, [__]) => null;

  @override
  visitText(_, [__]) => null;

  // Nodes that might have expressions, and need further traversal.
  // ---------------------------------------------------------------------------

  @override
  visitAttribute(AttributeAst astNode, [_]) {
    if (astNode.mustaches != null) {
      astNode.mustaches.forEach((mustache) {
        mustache.accept(this);
      });
    }
  }

  @override
  visitEmbeddedTemplate(EmbeddedTemplateAst astNode, [_]) {
    astNode.events.forEach((event) {
      event.accept(this);
    });
    astNode.properties.forEach((property) {
      property.accept(this);
    });
    astNode.childNodes.forEach((child) {
      child.accept(this);
    });
  }

  @override
  visitElement(ElementAst astNode, [_]) {
    astNode.attributes.forEach((attribute) {
      attribute.accept(this);
    });
    astNode.events.forEach((event) {
      event.accept(this);
    });
    astNode.properties.forEach((property) {
      property.accept(this);
    });
    astNode.childNodes.forEach((child) {
      child.accept(this);
    });
  }

  // Nodes that are expressions, and need parsing.
  // ---------------------------------------------------------------------------

  @override
  visitEvent(EventAst astNode, [_]) {
    ExpressionAst expression;
    if (astNode is ParsedEventAst && astNode.valueToken != null) {
      var innerValue = astNode.valueToken.innerValue;
      expression = _parseLegacyEvent(innerValue.lexeme, innerValue.offset);
    } else {
      expression = _parseLegacyEvent(astNode.value, 0);
    }
    astNode.expression = expression;
    return null;
  }

  ExpressionAst<legacy.AST> _parseLegacyEvent(
    String expression,
    int offset,
  ) {
    if (expression == null) {
      return null;
    }
    final parsed = _parser.parseAction(expression, offset, _exports);
    return new ExpressionAst(parsed);
  }

  @override
  visitInterpolation(InterpolationAst astNode, [_]) {
    ExpressionAst expression;
    if (astNode is ParsedInterpolationAst && astNode.value != null) {
      expression = _parseLegacyInterpolation(
        astNode.valueToken.lexeme,
        astNode.valueToken.offset,
      );
    } else {
      expression = _parseLegacyInterpolation(
        astNode.value,
        0,
      );
    }
    astNode.expression = expression;
    return null;
  }

  ExpressionAst<legacy.AST> _parseLegacyInterpolation(
    String expression,
    int offset,
  ) {
    if (expression == null) {
      return null;
    }
    final parsed = _parser.parseInterpolation(expression, offset, _exports);
    return new ExpressionAst(parsed);
  }

  @override
  visitProperty(PropertyAst astNode, [_]) {
    ExpressionAst expression;
    if (astNode is ParsedPropertyAst && astNode.valueToken != null) {
      var valueToken = astNode.valueToken.innerValue;
      expression = _parseLegacyBinding(
        valueToken.lexeme,
        valueToken.offset,
      );
    } else {
      expression = _parseLegacyBinding(astNode.value, 0);
    }
    astNode.expression = expression;
    return null;
  }

  ExpressionAst<legacy.AST> _parseLegacyBinding(
    String expression,
    int offset,
  ) {
    if (expression == null) {
      return null;
    }
    final parsed = _parser.parseBinding(expression, offset, _exports);
    return new ExpressionAst(parsed);
  }
}
