// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:angular_ast/angular_ast.dart';
import 'package:angular_ast/src/token/tokens.dart';

final int generationCount = 10000;
final int iterationCount = 100;

final String dir = p.join('test', 'random_generator_test');
String incorrectFilename = 'incorrect.html';
String lexerFixedFilename = 'lexer_fixed.html';
String fullyFixedFilename = 'ast_fixed.html';

String untokenize(Iterable<NgToken> tokens) => tokens
    .fold(StringBuffer(), (buffer, token) => buffer..write(token.lexeme))
    .toString();

enum State {
  comment,
  element,
  interpolation,
  text,
}

String genericExpression = ' + 1 + 2';

List<NgSimpleTokenType> elementMap = <NgSimpleTokenType>[
  NgSimpleTokenType.backSlash,
  NgSimpleTokenType.bang,
  NgSimpleTokenType.closeBanana,
  NgSimpleTokenType.closeBracket,
  NgSimpleTokenType.closeParen,
  NgSimpleTokenType.commentBegin, //Shift state
  NgSimpleTokenType.dash,
  NgSimpleTokenType.doubleQuote, // special
  NgSimpleTokenType.openTagStart,
  NgSimpleTokenType.tagEnd,
  NgSimpleTokenType.equalSign,
  NgSimpleTokenType.forwardSlash,
  NgSimpleTokenType.hash,
  NgSimpleTokenType.identifier,
  NgSimpleTokenType.openBanana,
  NgSimpleTokenType.openBracket,
  NgSimpleTokenType.openParen,
  NgSimpleTokenType.percent,
  NgSimpleTokenType.period,
  NgSimpleTokenType.singleQuote, //Special
  NgSimpleTokenType.star,
  NgSimpleTokenType.unexpectedChar,
  NgSimpleTokenType.voidCloseTag,
];

List<NgSimpleTokenType> textMap = <NgSimpleTokenType>[
  NgSimpleTokenType.commentBegin,
  NgSimpleTokenType.openTagStart,
  NgSimpleTokenType.closeTagStart,
  NgSimpleTokenType.mustacheBegin,
  NgSimpleTokenType.text,
];

NgSimpleTokenType generateRandomSimple(State state) {
  var rng = Random();
  switch (state) {
    case State.comment:
      if (rng.nextInt(100) <= 20) {
        return NgSimpleTokenType.text;
      }
      return NgSimpleTokenType.commentEnd;
    case State.element:
      var i = rng.nextInt(elementMap.length);
      return elementMap[i];
    case State.interpolation:
      if (rng.nextInt(100) <= 20) {
        return NgSimpleTokenType.text;
      }
      return NgSimpleTokenType.mustacheEnd;
    case State.text:
      var i = rng.nextInt(textMap.length);
      return textMap[i];
    default:
      return NgSimpleTokenType.unexpectedChar;
  }
}

String generateHtmlString() {
  var state = State.text;
  var sb = StringBuffer();
  var identifierCount = 0;
  for (int i = 0; i < generationCount; i++) {
    var type = generateRandomSimple(state);
    switch (state) {
      case State.comment:
        if (type == NgSimpleTokenType.commentEnd) {
          state = State.text;
          sb.write(NgSimpleToken.lexemeMap[type]);
        } else {
          sb.write(' some comment');
        }
        break;
      case State.element:
        if (type == NgSimpleTokenType.commentBegin) {
          state = State.comment;
          sb.write(NgSimpleToken.lexemeMap[type]);
        } else if (type == NgSimpleTokenType.doubleQuote) {
          sb.write('"someDoubleQuoteValue"');
        } else if (type == NgSimpleTokenType.singleQuote) {
          sb.write("'someSingleQuoteValue'");
        } else if (type == NgSimpleTokenType.identifier) {
          sb.write('ident${identifierCount.toString()}');
          identifierCount++;
        } else if (type == NgSimpleTokenType.whitespace) {
          sb.write(' ');
        } else if (type == NgSimpleTokenType.voidCloseTag ||
            type == NgSimpleTokenType.tagEnd) {
          state = State.text;
          sb.write(NgSimpleToken.lexemeMap[type]);
        } else {
          sb.write(NgSimpleToken.lexemeMap[type]);
        }
        break;
      case State.interpolation:
        if (type == NgSimpleTokenType.mustacheEnd) {
          state = State.text;
          sb.write(NgSimpleToken.lexemeMap[type]);
        } else {
          sb.write(genericExpression);
        }
        break;
      case State.text:
        if (type == NgSimpleTokenType.commentBegin) {
          state = State.comment;
          sb.write(NgSimpleToken.lexemeMap[type]);
        } else if (type == NgSimpleTokenType.openTagStart ||
            type == NgSimpleTokenType.closeTagStart) {
          state = State.element;
          sb.write(NgSimpleToken.lexemeMap[type]);
        } else if (type == NgSimpleTokenType.mustacheBegin) {
          state = State.interpolation;
          sb.write('${NgSimpleToken.lexemeMap[type]}0');
        } else {
          sb.write('lorem ipsum');
        }
        break;
      default:
        sb.write('');
    }
  }
  return sb.toString();
}

main() async {
  var exceptionHandler = RecoveringExceptionHandler();

  var totalIncorrectLength = 0;
  var totalLexerTime = 0;
  var totalParserTime = 0;

  for (int i = 0; i < iterationCount; i++) {
    print('Iteration $i of $iterationCount ...');
    var stopwatch = Stopwatch();

    var incorrectHtml = generateHtmlString();
    totalIncorrectLength += incorrectHtml.length;
    await File(p.join(dir, incorrectFilename)).writeAsString(incorrectHtml);

    stopwatch.reset();
    stopwatch.start();
    var lexerTokens = const NgLexer().tokenize(incorrectHtml, exceptionHandler);
    stopwatch.stop();
    totalLexerTime += stopwatch.elapsedMicroseconds;
    var lexerFixedString = untokenize(lexerTokens);
    await File(p.join(dir, lexerFixedFilename)).writeAsString(lexerFixedString);
    exceptionHandler.exceptions.clear();

    stopwatch.reset();
    stopwatch.start();
    var ast = const NgParser().parse(
      incorrectHtml,
      sourceUrl: '/test/parser_test.dart#inline',
      exceptionHandler: exceptionHandler,
      desugar: false,
      parseExpressions: false,
    );
    stopwatch.stop();
    totalParserTime += stopwatch.elapsedMilliseconds;
    var visitor = const HumanizingTemplateAstVisitor();
    var fixedString = ast.map((t) => t.accept(visitor)).join('');
    await File(p.join(dir, fullyFixedFilename)).writeAsString(fixedString);
    exceptionHandler.exceptions.clear();
  }

  print('Total lines scanned/parsed: $totalIncorrectLength');
  print('Total time for lexer: $totalLexerTime microseconds');
  print('Total time for parser: $totalParserTime ms');
}
