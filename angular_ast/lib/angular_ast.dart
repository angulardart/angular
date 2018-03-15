// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import 'src/ast.dart';
import 'src/exception_handler/exception_handler.dart';
import 'src/parser.dart';

export 'src/ast.dart'
    show
        AnnotationAst,
        AttributeAst,
        BananaAst,
        CloseElementAst,
        CommentAst,
        ElementAst,
        EmbeddedContentAst,
        EmbeddedTemplateAst,
        EventAst,
        ExpressionAst,
        InterpolationAst,
        LetBindingAst,
        ParsedAttributeAst,
        ParsedBananaAst,
        ParsedCloseElementAst,
        ParsedDecoratorAst,
        ParsedEmbeddedContentAst,
        ParsedEventAst,
        ParsedInterpolationAst,
        ParsedElementAst,
        ParsedLetBindingAst,
        ParsedPropertyAst,
        ParsedReferenceAst,
        ParsedStarAst,
        PropertyAst,
        ReferenceAst,
        StandaloneTemplateAst,
        StarAst,
        SyntheticTemplateAst,
        TagOffsetInfo,
        TemplateAst,
        TextAst;
export 'src/exception_handler/exception_handler.dart'
    show ExceptionHandler, RecoveringExceptionHandler, ThrowingExceptionHandler;
export 'src/exception_handler/exception_handler.dart';
export 'src/expression/ng_dart_ast.dart';
export 'src/expression/parser.dart';
export 'src/expression/visitor.dart';
export 'src/lexer.dart' show NgLexer;
export 'src/parser.dart' show NgParser;
export 'src/recovery_protocol/recovery_protocol.dart';
export 'src/token/tokens.dart' show NgToken, NgTokenType, NgAttributeValueToken;
export 'src/visitor.dart'
    show
        ExpressionParserVisitor,
        HumanizingTemplateAstVisitor,
        IdentityTemplateAstVisitor,
        MinimizeWhitespaceVisitor,
        TemplateAstVisitor,
        DesugarVisitor,
        RecursiveTemplateAstVisitor;

/// Returns [template] parsed as an abstract syntax tree.
///
/// Optional bool flag [desugar] desugars syntactic sugaring of * template
/// notations and banana syntax used in two-way binding.
/// Optional bool flag [toolFriendlyAst] provides a reference to the original
/// non-desugared nodes after desugaring occurs.
/// Optional exceptionHandler. Pass in either [RecoveringExceptionHandler] or
/// [ThrowingExceptionHandler] (default).
List<TemplateAst> parse(
  String template, {
  @required String sourceUrl,
  bool toolFriendlyAst: false, // Only needed if desugar = true
  bool desugar: true,
  bool parseExpressions: true,
  ExceptionHandler exceptionHandler: const ThrowingExceptionHandler(),
}) {
  var parser = toolFriendlyAst
      ? const NgParser(toolFriendlyAstOrigin: true)
      : const NgParser();

  return parser.parse(
    template,
    sourceUrl: sourceUrl,
    exceptionHandler: exceptionHandler,
    desugar: desugar,
    parseExpressions: parseExpressions,
  );
}
