// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

import 'ast.dart';
import 'exception_handler/exception_handler.dart';
import 'lexer.dart';
import 'parser/recursive.dart';
import 'visitor.dart';

class NgParser {
  // Elements that explicitly don't have a closing tag.
  //
  // https://www.w3.org/TR/html/syntax.html#void-elements
  static const _voidElements = const <String>[
    'area',
    'base',
    'br',
    'col',
    'command',
    'embed',
    'hr',
    'img',
    'input',
    'keygen',
    'link',
    'meta',
    'param',
    'source',
    'track',
    'wbr',
    'path',
  ];

  final bool _toolFriendlyAstOrigin;

  @literal
  const factory NgParser({
    bool toolFriendlyAstOrigin,
  }) = NgParser._;

  // Prevent inheritance.
  const NgParser._({
    bool toolFriendlyAstOrigin: false,
  })
      : _toolFriendlyAstOrigin = toolFriendlyAstOrigin;

  /// Return a series of tokens by incrementally scanning [template].
  ///
  /// Automatically desugars.
  List<StandaloneTemplateAst> parse(
    String template, {
    @required String sourceUrl,
    bool desugar: true,
    bool parseExpressions: true,
    ExceptionHandler exceptionHandler: const ThrowingExceptionHandler(),
  }) {
    var tokens = const NgLexer().tokenize(template, exceptionHandler);
    var parser = new RecursiveAstParser(
      new SourceFile(
        template,
        url: sourceUrl,
      ),
      tokens,
      _voidElements,
      exceptionHandler,
    );
    var asts = parser.parse();
    if (desugar) {
      var desugarVisitor = new DesugarVisitor(
        toolFriendlyAstOrigin: _toolFriendlyAstOrigin,
        exceptionHandler: exceptionHandler,
      );
      asts = asts.map((t) => t.accept(desugarVisitor)).toList();
    }

    if (parseExpressions) {
      var expressionParserVisitor = new ExpressionParserVisitor(
        sourceUrl,
        exceptionHandler: exceptionHandler,
      );
      for (var ast in asts) {
        ast.accept(expressionParserVisitor);
      }
    }
    return asts;
  }
}
