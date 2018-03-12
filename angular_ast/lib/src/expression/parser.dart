// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';

import '../exception_handler/exception_handler.dart';
import 'ng_dart_ast.dart';

final _resourceProvider = new MemoryResourceProvider();

class _ThrowingListener implements AnalysisErrorListener {
  const _ThrowingListener();

  @override
  void onError(AnalysisError error) {
    throw new AngularParserException(
      error.errorCode,
      error.offset,
      error.length,
    );
  }
}

/// Parses a template [expression].
Expression parseExpression(
  String expression, {
  @required String sourceUrl,
}) {
  final source = _resourceProvider
      .newFile(
        sourceUrl,
        expression,
      )
      .createSource();
  final reader = new CharSequenceReader(expression);
  final listener = const _ThrowingListener();
  final scanner = new Scanner(source, reader, listener);
  final parser = new _NgExpressionParser(
    source,
    listener,
  );
  return parser.parseExpression(scanner.tokenize());
}

/// Extends the Dart language to understand the current Angular 'pipe' syntax.
/// Angular syntax disallows bitwise-or operation. Any '|' seen will
/// be treated as a pipe.
///
/// Based on https://github.com/dart-lang/angular_analyzer_plugin/pull/160
class _NgExpressionParser extends Parser {
  _NgExpressionParser(
    Source source,
    AnalysisErrorListener errorListener,
  ) : super.withoutFasta(source, errorListener);

  @override
  Expression parseBitwiseOrExpression() {
    Expression expression;
    if (currentToken.keyword == Keyword.SUPER &&
        currentToken.next.type == TokenType.BAR) {
      expression = new SuperExpressionImpl(getAndAdvance());
    } else {
      expression = parseBitwiseXorExpression();
    }
    while (currentToken.type == TokenType.BAR) {
      final bar = getAndAdvance();
      final pipeName = parseSimpleIdentifier();
      final optArgs = parsePipeParameters();
      expression =
          new PipeInvocationExpression(bar, pipeName, expression, optArgs);
    }
    return expression;
  }

  AstNode parsePipeParameters() {
    Token argsStart;
    if (currentToken.lexeme != ':') {
      return null;
    } else {
      argsStart = currentToken;
    }
    var pipeArgs = <Expression>[];
    while (currentToken.lexeme == ':') {
      currentToken = currentToken.next;
      pipeArgs.add(this.parseBitwiseXorExpression());
    }
    return new PipeOptionalArgumentList(argsStart, pipeArgs);
  }
}
