// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';

import '../ast.dart';
import '../exception_handler/exception_handler.dart';
import '../visitor.dart';

class ExpressionParserVisitor implements TemplateAstVisitor<dynamic, Null> {
  final ExceptionHandler exceptionHandler;
  final String sourceUrl;

  ExpressionParserVisitor(this.sourceUrl, {ExceptionHandler exceptionHandler})
      : exceptionHandler = exceptionHandler ?? new ThrowingExceptionHandler();

  @override
  visitAnnotation(AnnotationAst astNode, [_]) => null;

  @override
  visitAttribute(AttributeAst astNode, [_]) {
    if (astNode.mustaches != null) {
      astNode.mustaches.forEach((mustache) {
        mustache.accept(this);
      });
    }
    return null;
  }

  @override
  visitBanana(BananaAst astNode, [_]) => null;

  @override
  visitCloseElement(CloseElementAst astNode, [_]) => null;

  @override
  visitComment(CommentAst astNode, [_]) => null;

  @override
  visitEmbeddedContent(EmbeddedContentAst astNode, [_]) => null;

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
    return null;
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
    return null;
  }

  @override
  visitEvent(EventAst astNode, [_]) {
    ExpressionAst expression;
    if (astNode is ParsedEventAst && astNode.valueToken != null) {
      var innerValue = astNode.valueToken.innerValue;
      expression = _parseExpression(innerValue.lexeme, innerValue.offset);
    } else {
      expression = _parseExpression(astNode.value, 0);
    }
    astNode.expression = expression;
    return null;
  }

  @override
  visitExpression(ExpressionAst astNode, [_]) => null;

  @override
  visitInterpolation(InterpolationAst astNode, [_]) {
    ExpressionAst expression;
    if (astNode is ParsedInterpolationAst && astNode.value != null) {
      expression = _parseExpression(
          astNode.valueToken.lexeme, astNode.valueToken.offset);
    } else {
      expression = _parseExpression(astNode.value, 0);
    }
    astNode.expression = expression;
    return null;
  }

  @override
  visitLetBinding(LetBindingAst astNode, [_]) => null;

  @override
  visitProperty(PropertyAst astNode, [_]) {
    ExpressionAst expression;
    if (astNode is ParsedPropertyAst && astNode.valueToken != null) {
      var valueToken = astNode.valueToken.innerValue;
      expression = _parseExpression(
        valueToken.lexeme,
        valueToken.offset,
      );
    } else {
      expression = _parseExpression(astNode.value, 0);
    }
    astNode.expression = expression;
    return null;
  }

  @override
  visitReference(ReferenceAst astNode, [_]) => null;

  @override
  visitStar(StarAst astNode, [_]) => null;

  @override
  visitText(TextAst astNode, [_]) => null;

  /// Parse expression
  ExpressionAst _parseExpression(String expression, int offset) {
    try {
      if (expression == null) {
        return null;
      }
      return new ExpressionAst.parse(
        expression,
        offset,
        sourceUrl: sourceUrl,
      );
    } on AnalysisError catch (e) {
      exceptionHandler.handle(new AngularParserException(
        e.errorCode,
        e.offset,
        e.length,
      ));
    } on AngularParserException catch (e) {
      exceptionHandler.handle(e);
    }
    return null;
  }
}
