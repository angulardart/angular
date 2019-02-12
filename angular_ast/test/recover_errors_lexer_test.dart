// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:angular_ast/angular_ast.dart';
import 'package:angular_ast/src/scanner.dart';
import 'package:angular_ast/src/token/tokens.dart';
import 'package:angular_ast/src/parser/reader.dart';
import 'package:test/test.dart';

const ThrowingExceptionHandler throwingException = ThrowingExceptionHandler();
RecoveringExceptionHandler recoveringException = RecoveringExceptionHandler();
RecoveryProtocol recoveryProtocol = NgAnalyzerRecoveryProtocol();

Iterable<NgToken> tokenize(String html) {
  recoveringException.exceptions.clear();
  return const NgLexer().tokenize(html, recoveringException);
}

Iterator<NgToken> tokenizeThrow(String html) {
  return const NgLexer().tokenize(html, throwingException).iterator;
}

void unwrapAll(Iterator<NgToken> it) {
  while (it.moveNext() != null) {}
}

String untokenize(Iterable<NgToken> tokens) => tokens
    .fold(StringBuffer(), (buffer, token) => buffer..write(token.lexeme))
    .toString();

void testRecoverySolution(
  String baseHtml,
  NgScannerState startState,
  List<NgSimpleTokenType> encounteredTokens,
  NgTokenType expectedSyntheticType,
  NgScannerState expectedNextState, {
  String syntheticLexeme = '',
}) {
  var recoveryOffset = baseHtml.length;

  for (NgSimpleTokenType type in encounteredTokens) {
    var reader = NgTokenReversibleReader(null, []);
    var token = NgSimpleToken(type, recoveryOffset);

    String errorString;
    if (type == NgSimpleTokenType.doubleQuote) {
      errorString = '""';
    } else if (type == NgSimpleTokenType.singleQuote) {
      errorString = "''";
    } else if (type == NgSimpleTokenType.identifier) {
      errorString = 'some-identifier';
    } else {
      errorString = NgSimpleToken.lexemeMap[type];
    }
    var errorHtml = baseHtml + errorString;

    test('should resolve: unexpected $type in $startState', () async {
      var it = tokenizeThrow(errorHtml);
      expect(() {
        while (it.moveNext() != null) {}
      }, throwsA(TypeMatcher<AngularParserException>()));

      var solution = recoveryProtocol.recover(startState, token, reader);

      NgToken expectedSynthetic;
      if (expectedSyntheticType == null) {
        expectedSynthetic = null;
      } else if (expectedSyntheticType == NgTokenType.doubleQuote ||
          expectedSyntheticType == NgTokenType.singleQuote) {
        var left = NgToken.generateErrorSynthetic(
            recoveryOffset, expectedSyntheticType);
        var value = NgToken.generateErrorSynthetic(
            recoveryOffset, NgTokenType.elementDecoratorValue);
        var right = NgToken.generateErrorSynthetic(
            recoveryOffset, expectedSyntheticType);
        expectedSynthetic = NgAttributeValueToken.generate(left, value, right);
      } else {
        expectedSynthetic = NgToken.generateErrorSynthetic(
          recoveryOffset,
          expectedSyntheticType,
          lexeme: syntheticLexeme,
        );
      }
      expect(solution.tokenToReturn, expectedSynthetic);
      expect(solution.nextState, expectedNextState);
    });
  }
}

void checkException(NgParserWarningCode errorCode, int offset, int length) {
  expect(recoveringException.exceptions.length, 1);
  var e = recoveringException.exceptions[0];
  expect(e.errorCode, errorCode);
  expect(e.offset, offset);
  expect(e.length, length);
}

void main() {
  beforeInterpolation();
  afterComment();
  afterElementDecorator();
  afterElementDecoratorValue();
  afterInterpolation();
  comment();
  elementDecorator();
  elementDecoratorValue();
  elementIdentifierOpen();
  elementIdentifierClose();
  afterElementIdentifierClose();
  afterElementIdentifierOpen();
  elementEndClose();
  interpolation();
  simpleElementDecorator();
  specialBananaDecorator();
  specialEventDecorator();
  specialPropertyDecorator();
  suffixBanana();
  suffixEvent();
  suffixProperty();
}

void beforeInterpolation() {
  test('should resolve: dangling mustacheEnd at start', () {
    var html = '}} some text';
    var results = tokenize(html);
    expect(results, [
      NgToken.interpolationStart(0), // Synthetic
      NgToken.interpolationValue(0, ''), // Synthetic
      NgToken.interpolationEnd(0),
      NgToken.text(2, ' some text'),
    ]);
    checkException(NgParserWarningCode.UNOPENED_MUSTACHE, 0, 2);
    expect(untokenize(results), '{{}} some text');
  });

  test('should resolve: dangling mustacheEnd at end of text', () {
    var html = 'mustache text}}';
    var results = tokenize(html);
    expect(results, [
      NgToken.interpolationStart(0), // Synthetic
      NgToken.interpolationValue(0, 'mustache text'),
      NgToken.interpolationEnd(13),
    ]);
    checkException(NgParserWarningCode.UNOPENED_MUSTACHE, 13, 2);
    expect(untokenize(results), '{{mustache text}}');
  });
}

void afterComment() {
  test('should resolve: unexpected EOF in afterComment', () {
    var html = '<!-- some comment ';
    var results = tokenize(html);
    expect(
      results,
      [
        NgToken.commentStart(0),
        NgToken.commentValue(4, ' some comment '),
        NgToken.commentEnd(18),
      ],
    );
    checkException(NgParserWarningCode.UNTERMINATED_COMMENT, 0, 18);
    expect(untokenize(results), '<!-- some comment -->');
  });
}

void afterInterpolation() {
  var baseHtml = '{{ 1 + 2 ';
  var startState = NgScannerState.scanAfterInterpolation;

  // All other tokens are automatically integrated as an 'expression'text value
  // and therefore unreachable.
  var resolveTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.mustacheBegin,
    NgSimpleTokenType.whitespace,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens,
    NgTokenType.interpolationEnd,
    NgScannerState.scanStart,
  );
  test('Testing resolved strings of $startState', () {
    expect(untokenize(tokenize('{{5 + 1')), '{{5 + 1}}');
    checkException(NgParserWarningCode.UNTERMINATED_MUSTACHE, 0, 2);
    expect(untokenize(tokenize('{{5 + 1{{ 2 + 4 }}')), '{{5 + 1}}{{ 2 + 4 }}');
    checkException(NgParserWarningCode.UNTERMINATED_MUSTACHE, 0, 2);
    expect(untokenize(tokenize('{{5 + 1 \n<div>')), '{{5 + 1 }}\n<div>');
    checkException(NgParserWarningCode.UNTERMINATED_MUSTACHE, 0, 2);
  });
}

void comment() {
  test('should resolve: unexpected EOF in scanComment', () {
    var html = '<!-- some comment ';
    var results = tokenize(html);
    expect(
      results,
      [
        NgToken.commentStart(0),
        NgToken.commentValue(4, ' some comment '),
        NgToken.commentEnd(18)
      ],
    );
    checkException(NgParserWarningCode.UNTERMINATED_COMMENT, 0, 18);
    expect(untokenize(results), '<!-- some comment -->');
  });
}

void elementIdentifierClose() {
  var baseHtml = '</';
  var startState = NgScannerState.scanElementIdentifierClose;

  var resolveTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.closeTagStart,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.tagEnd,
    NgSimpleTokenType.commentBegin,
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.whitespace,
  ];
  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.openBracket,
    NgSimpleTokenType.openParen,
    NgSimpleTokenType.openBanana,
    NgSimpleTokenType.closeBracket,
    NgSimpleTokenType.closeParen,
    NgSimpleTokenType.closeBanana,
    NgSimpleTokenType.dash,
    NgSimpleTokenType.equalSign,
    NgSimpleTokenType.doubleQuote,
    NgSimpleTokenType.singleQuote,
    NgSimpleTokenType.hash,
    NgSimpleTokenType.star,
    NgSimpleTokenType.period,
    NgSimpleTokenType.unexpectedChar,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens,
    NgTokenType.elementIdentifier,
    NgScannerState.scanAfterElementIdentifierClose,
  );

  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(untokenize(tokenize('</</div>')), '</></div>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 4);
    expect(untokenize(tokenize('</<div>')), '</><div>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 3);
    expect(untokenize(tokenize('</>')), '</>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 3);
    expect(untokenize(tokenize('</<!--comment-->')), '</><!--comment-->');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 6);
    expect(untokenize(tokenize('</')), '</>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 2);
    expect(untokenize(tokenize('</ >')), '</ >');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 3);

    // Drop types
    expect(untokenize(tokenize('</!div>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 2, 1);
    expect(untokenize(tokenize('</[div>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 2, 1);
    expect(untokenize(tokenize('</(div>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 2, 1);
    expect(untokenize(tokenize('</[(div>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 2, 2);
    expect(untokenize(tokenize('</]div>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 2, 1);
    expect(untokenize(tokenize('</)div>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 2, 1);
    expect(untokenize(tokenize('</)]div>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 2, 2);
    expect(untokenize(tokenize('</-div>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 2, 1);
    expect(untokenize(tokenize('</=div>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 2, 1);
    expect(untokenize(tokenize('</"blah"div>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 2, 6);
    expect(untokenize(tokenize("</'blah'div>")), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 2, 6);
    expect(untokenize(tokenize('</#div>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 2, 1);
    expect(untokenize(tokenize('</*div>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 2, 1);
    expect(untokenize(tokenize('</.div>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 2, 1);
    expect(untokenize(tokenize('</@div>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 2, 1);
  });
}

void elementIdentifierOpen() {
  var baseHtml = '<';
  var startState = NgScannerState.scanElementIdentifierOpen;

  var resolveTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.openParen,
    NgSimpleTokenType.openBanana,
    NgSimpleTokenType.openBracket,
    NgSimpleTokenType.closeParen,
    NgSimpleTokenType.closeBanana,
    NgSimpleTokenType.closeBracket,
    NgSimpleTokenType.hash,
    NgSimpleTokenType.star,
    NgSimpleTokenType.commentBegin,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.closeTagStart,
    NgSimpleTokenType.tagEnd,
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.equalSign,
    NgSimpleTokenType.doubleQuote,
    NgSimpleTokenType.singleQuote,
    NgSimpleTokenType.whitespace,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens,
    NgTokenType.elementIdentifier,
    NgScannerState.scanAfterElementIdentifierOpen,
  );

  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.dash,
    NgSimpleTokenType.period,
    NgSimpleTokenType.unexpectedChar,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(untokenize(tokenize('<(evnt)>')), '< (evnt)>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 2);
    expect(untokenize(tokenize('<[(bnna)]>')), '< [(bnna)]>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 3);
    expect(untokenize(tokenize('<[prop]>')), '< [prop]>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 2);
    expect(untokenize(tokenize('<)>')), '< ()>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 2);
    expect(untokenize(tokenize('<)]>')), '< [()]>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 3);
    expect(untokenize(tokenize('<]>')), '< []>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 2);
    expect(untokenize(tokenize('<#ref>')), '< #ref>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 2);
    expect(untokenize(tokenize('<*temp>')), '< *temp>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 2);
    expect(untokenize(tokenize('<@temp>')), '< @temp>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 2);
    expect(untokenize(tokenize('<<!--comment-->')), '<><!--comment-->');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 5);
    expect(untokenize(tokenize('<<span>')), '<><span>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 2);
    expect(untokenize(tokenize('<</div>')), '<></div>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 3);
    expect(untokenize(tokenize('<>')), '<>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 2);
    expect(untokenize(tokenize('<')), '<>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 1);
    expect(untokenize(tokenize('<="blah">')), '< ="blah">');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 2);
    expect(untokenize(tokenize('<"blah">')), '< ="blah">');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 7);
    expect(untokenize(tokenize("<'blah'>")), "< ='blah'>");
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 7);
    expect(untokenize(tokenize('< attr>')), '< attr>');
    checkException(NgParserWarningCode.ELEMENT_IDENTIFIER, 0, 2);

    // Drop types
    expect(untokenize(tokenize('<!div>')), '<div>');
    expect(untokenize(tokenize('<-div>')), '<div>');
    expect(untokenize(tokenize('<.div>')), '<div>');
    expect(untokenize(tokenize('<?div>')), '<div>');
  });
}

void afterElementIdentifierClose() {
  var baseHtml = '</div';
  var startState = NgScannerState.scanAfterElementIdentifierClose;

  var resolveTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.commentBegin,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.closeTagStart,
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.voidCloseTag,
  ];

  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.openBracket,
    NgSimpleTokenType.openParen,
    NgSimpleTokenType.openBanana,
    NgSimpleTokenType.closeBracket,
    NgSimpleTokenType.closeParen,
    NgSimpleTokenType.closeBanana,
    NgSimpleTokenType.doubleQuote,
    NgSimpleTokenType.singleQuote,
    NgSimpleTokenType.equalSign,
    NgSimpleTokenType.forwardSlash,
    NgSimpleTokenType.hash,
    NgSimpleTokenType.star,
    NgSimpleTokenType.period,
    NgSimpleTokenType.unexpectedChar,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens,
    NgTokenType.closeElementEnd,
    NgScannerState.scanStart,
  );

  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(untokenize(tokenize('</div<!--comment-->')), '</div><!--comment-->');
    checkException(NgParserWarningCode.EXPECTED_AFTER_ELEMENT_IDENTIFIER, 2, 3);
    expect(untokenize(tokenize('</div<span>')), '</div><span>');
    checkException(NgParserWarningCode.EXPECTED_AFTER_ELEMENT_IDENTIFIER, 2, 3);
    expect(untokenize(tokenize('</div</span>')), '</div></span>');
    checkException(NgParserWarningCode.EXPECTED_AFTER_ELEMENT_IDENTIFIER, 2, 3);
    expect(untokenize(tokenize('</div')), '</div>');
    checkException(NgParserWarningCode.EXPECTED_AFTER_ELEMENT_IDENTIFIER, 2, 3);
    expect(untokenize(tokenize('</div/>')), '</div>');
    checkException(NgParserWarningCode.VOID_CLOSE_IN_CLOSE_TAG, 5, 2);

    // Drop types
    expect(untokenize(tokenize('</div!>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
    expect(untokenize(tokenize('</div[>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
    expect(untokenize(tokenize('</div(>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
    expect(untokenize(tokenize('</div[(>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 2);
    expect(untokenize(tokenize('</div]>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
    expect(untokenize(tokenize('</div)>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
    expect(untokenize(tokenize('</div)]>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 2);
    expect(untokenize(tokenize('</div"blah">')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 6);
    expect(untokenize(tokenize("</div'blah'>")), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 6);
    expect(untokenize(tokenize('</div=>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
    expect(untokenize(tokenize('</div/ >')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
    expect(untokenize(tokenize('</div#>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
    expect(untokenize(tokenize('</div*>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
    expect(untokenize(tokenize('</div.>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
    expect(untokenize(tokenize('</div@>')), '</div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
  });
}

void afterElementIdentifierOpen() {
  var baseHtml = '<div';
  var startState = NgScannerState.scanAfterElementIdentifierOpen;

  var resolveTokens1 = <NgSimpleTokenType>[
    NgSimpleTokenType.openBracket,
    NgSimpleTokenType.openParen,
    NgSimpleTokenType.openBanana,
    NgSimpleTokenType.closeBracket,
    NgSimpleTokenType.closeParen,
    NgSimpleTokenType.closeBanana,
    NgSimpleTokenType.hash,
    NgSimpleTokenType.star,
    NgSimpleTokenType.equalSign,
    NgSimpleTokenType.doubleQuote,
    NgSimpleTokenType.singleQuote,
  ];

  var resolveTokens2 = <NgSimpleTokenType>[
    NgSimpleTokenType.commentBegin,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.closeTagStart,
    NgSimpleTokenType.EOF,
  ];

  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.forwardSlash,
    NgSimpleTokenType.period,
    NgSimpleTokenType.unexpectedChar,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens1,
    NgTokenType.beforeElementDecorator,
    NgScannerState.scanElementDecorator,
    syntheticLexeme: ' ',
  );

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens2,
    NgTokenType.openElementEnd,
    NgScannerState.scanStart,
  );

  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(untokenize(tokenize('<div[prop]>')), '<div [prop]>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 1, 3);
    expect(untokenize(tokenize('<div(evnt)>')), '<div (evnt)>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 1, 3);
    expect(untokenize(tokenize('<div[(bnna)]>')), '<div [(bnna)]>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 1, 3);
    expect(untokenize(tokenize('<div#ref>')), '<div #ref>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 1, 3);
    expect(untokenize(tokenize('<div*temp>')), '<div *temp>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 1, 3);
    expect(untokenize(tokenize('<div@temp>')), '<div @temp>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 1, 3);
    expect(untokenize(tokenize('<div="blah">')), '<div ="blah">');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 1, 3);
    expect(untokenize(tokenize("<div='blah'>")), "<div ='blah'>");
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 1, 3);
    expect(untokenize(tokenize('<div]>')), '<div []>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 1, 3);
    expect(untokenize(tokenize('<div)>')), '<div ()>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 1, 3);
    expect(untokenize(tokenize('<div)]>')), '<div [()]>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 1, 3);
    expect(untokenize(tokenize('<div"blah">')), '<div ="blah">');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 1, 3);
    expect(untokenize(tokenize("<div'blah'>")), "<div ='blah'>");
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 1, 3);

    // Resolve2 types
    expect(untokenize(tokenize('<div<!--comment-->')), '<div><!--comment-->');
    checkException(NgParserWarningCode.EXPECTED_AFTER_ELEMENT_IDENTIFIER, 1, 3);
    expect(untokenize(tokenize('<div<span>')), '<div><span>');
    checkException(NgParserWarningCode.EXPECTED_AFTER_ELEMENT_IDENTIFIER, 1, 3);
    expect(untokenize(tokenize('<div</div>')), '<div></div>');
    checkException(NgParserWarningCode.EXPECTED_AFTER_ELEMENT_IDENTIFIER, 1, 3);
    expect(untokenize(tokenize('<div')), '<div>');
    checkException(NgParserWarningCode.EXPECTED_AFTER_ELEMENT_IDENTIFIER, 1, 3);

    // Drop types
    expect(untokenize(tokenize('<div!>')), '<div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 4, 1);
    expect(untokenize(tokenize('<div/ >')), '<div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 4, 1);
    expect(untokenize(tokenize('<div.>')), '<div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 4, 1);
    expect(untokenize(tokenize('<div?>')), '<div>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 4, 1);
  });
}

void afterElementDecorator() {
  var baseHtml = '<div attr';
  var startState = NgScannerState.scanAfterElementDecorator;

  var resolveTokens1 = <NgSimpleTokenType>[
    NgSimpleTokenType.openBracket,
    NgSimpleTokenType.openParen,
    NgSimpleTokenType.openBanana,
    NgSimpleTokenType.closeBracket,
    NgSimpleTokenType.closeParen,
    NgSimpleTokenType.closeBanana,
    NgSimpleTokenType.hash,
    NgSimpleTokenType.star,
    NgSimpleTokenType.identifier,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens1,
    NgTokenType.beforeElementDecorator,
    NgScannerState.scanElementDecorator,
    syntheticLexeme: ' ',
  );

  var resolveTokens2 = <NgSimpleTokenType>[
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.commentBegin,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.closeTagStart,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens2,
    NgTokenType.openElementEnd,
    NgScannerState.scanStart,
  );

  var resolveTokens3 = <NgSimpleTokenType>[
    NgSimpleTokenType.doubleQuote,
    NgSimpleTokenType.singleQuote,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens3,
    NgTokenType.beforeElementDecoratorValue,
    NgScannerState.scanElementDecoratorValue,
  );

  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.forwardSlash,
    NgSimpleTokenType.unexpectedChar,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(untokenize(tokenize('<div blah[prop]>')), '<div blah [prop]>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 9, 1);
    expect(untokenize(tokenize('<div blah(evnt)>')), '<div blah (evnt)>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 9, 1);
    expect(untokenize(tokenize('<div blah[(bnna)]>')), '<div blah [(bnna)]>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 9, 2);
    expect(untokenize(tokenize('<div blah]>')), '<div blah []>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 9, 1);
    expect(untokenize(tokenize('<div blah)>')), '<div blah ()>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 9, 1);
    expect(untokenize(tokenize('<div blah)]>')), '<div blah [()]>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 9, 2);
    expect(untokenize(tokenize('<div blah#ref>')), '<div blah #ref>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 9, 1);
    expect(untokenize(tokenize('<div blah*temp>')), '<div blah *temp>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 9, 1);
    expect(untokenize(tokenize('<div blah@temp>')), '<div blah @temp>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 9, 1);
    expect(untokenize(tokenize('<div [blah]blah2>')), '<div [blah] blah2>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 11, 5);

    // Resolve2 types
    expect(untokenize(tokenize('<div blah')), '<div blah>');
    checkException(NgParserWarningCode.EXPECTED_TAG_CLOSE, 5, 4);
    expect(untokenize(tokenize('<div blah<!--comment-->')),
        '<div blah><!--comment-->');
    checkException(NgParserWarningCode.EXPECTED_TAG_CLOSE, 5, 4);
    expect(untokenize(tokenize('<div blah<span>')), '<div blah><span>');
    checkException(NgParserWarningCode.EXPECTED_TAG_CLOSE, 5, 4);
    expect(untokenize(tokenize('<div blah</div>')), '<div blah></div>');
    checkException(NgParserWarningCode.EXPECTED_TAG_CLOSE, 5, 4);

    // Resolve3 types
    expect(untokenize(tokenize('<div blah"value">')), '<div blah="value">');
    checkException(NgParserWarningCode.EXPECTED_EQUAL_SIGN, 5, 11);
    expect(untokenize(tokenize("<div blah'value'>")), "<div blah='value'>");
    checkException(NgParserWarningCode.EXPECTED_EQUAL_SIGN, 5, 11);

    // Drop types
    expect(untokenize(tokenize('<div blah!>')), '<div blah>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 9, 1);
    expect(untokenize(tokenize('<div blah/ >')), '<div blah >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 9, 1);
    expect(untokenize(tokenize('<div blah?>')), '<div blah>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 9, 1);
  });
}

void afterElementDecoratorValue() {
  var baseHtml = '<div someName="someValue"';
  var startState = NgScannerState.scanAfterElementDecoratorValue;

  var resolveTokens1 = <NgSimpleTokenType>[
    NgSimpleTokenType.openBracket,
    NgSimpleTokenType.openParen,
    NgSimpleTokenType.openBanana,
    NgSimpleTokenType.hash,
    NgSimpleTokenType.star,
    NgSimpleTokenType.closeBracket,
    NgSimpleTokenType.closeParen,
    NgSimpleTokenType.closeBanana,
    NgSimpleTokenType.identifier,
    NgSimpleTokenType.equalSign,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens1,
    NgTokenType.beforeElementDecorator,
    NgScannerState.scanElementDecorator,
    syntheticLexeme: ' ',
  );

  var resolveTokens2 = <NgSimpleTokenType>[
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.commentBegin,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.closeTagStart,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens2,
    NgTokenType.openElementEnd,
    NgScannerState.scanStart,
  );

  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.dash,
    NgSimpleTokenType.forwardSlash,
    NgSimpleTokenType.period,
    NgSimpleTokenType.unexpectedChar,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(untokenize(tokenize('<div someName="someValue"[prop]>')),
        '<div someName="someValue" [prop]>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 14, 11);
    expect(untokenize(tokenize('<div someName="someValue"(evnt)>')),
        '<div someName="someValue" (evnt)>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 14, 11);
    expect(untokenize(tokenize('<div someName="someValue"[(bnna)]>')),
        '<div someName="someValue" [(bnna)]>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 14, 11);
    expect(untokenize(tokenize('<div someName="someValue"#ref>')),
        '<div someName="someValue" #ref>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 14, 11);
    expect(untokenize(tokenize('<div someName="someValue"*temp>')),
        '<div someName="someValue" *temp>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 14, 11);
    expect(untokenize(tokenize('<div someName="someValue"@temp>')),
        '<div someName="someValue" @temp>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 14, 11);
    expect(untokenize(tokenize('<div someName="someValue"]>')),
        '<div someName="someValue" []>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 14, 11);
    expect(untokenize(tokenize('<div someName="someValue")>')),
        '<div someName="someValue" ()>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 14, 11);
    expect(untokenize(tokenize('<div someName="someValue")]>')),
        '<div someName="someValue" [()]>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 14, 11);
    expect(untokenize(tokenize('<div someName="someValue"blah>')),
        '<div someName="someValue" blah>');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 14, 11);
    expect(untokenize(tokenize('<div someName="someValue"="anotherValue">')),
        '<div someName="someValue" ="anotherValue">');
    checkException(
        NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR, 14, 11);

    // Resolve2 types
    expect(untokenize(tokenize('<div someName="someValue"')),
        '<div someName="someValue">');
    checkException(NgParserWarningCode.EXPECTED_TAG_CLOSE, 14, 11);
    expect(untokenize(tokenize('<div someName="someValue"<!--comment-->')),
        '<div someName="someValue"><!--comment-->');
    checkException(NgParserWarningCode.EXPECTED_TAG_CLOSE, 14, 11);
    expect(untokenize(tokenize('<div someName="someValue"<span>')),
        '<div someName="someValue"><span>');
    checkException(NgParserWarningCode.EXPECTED_TAG_CLOSE, 14, 11);
    expect(untokenize(tokenize('<div someName="someValue"</div>')),
        '<div someName="someValue"></div>');
    checkException(NgParserWarningCode.EXPECTED_TAG_CLOSE, 14, 11);

    // Resolve3 types
    expect(untokenize(tokenize('<div someName="someValue"!>')),
        '<div someName="someValue">');
    expect(untokenize(tokenize('<div someName="someValue"->')),
        '<div someName="someValue">');
    expect(untokenize(tokenize('<div someName="someValue"/ >')),
        '<div someName="someValue" >');
    expect(untokenize(tokenize('<div someName="someValue".>')),
        '<div someName="someValue">');
    expect(untokenize(tokenize('<div someName="someValue"?>')),
        '<div someName="someValue">');
  });
}

void elementDecorator() {
  var baseHtml = '<div ';
  var startState = NgScannerState.scanElementDecorator;

  var resolveTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.equalSign,
    NgSimpleTokenType.commentBegin,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.closeTagStart,
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.doubleQuote,
    NgSimpleTokenType.singleQuote,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens,
    NgTokenType.elementDecorator,
    NgScannerState.scanAfterElementDecorator,
    syntheticLexeme: '',
  );

  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.forwardSlash,
    NgSimpleTokenType.unexpectedChar,
    NgSimpleTokenType.dash,
    NgSimpleTokenType.period,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  var beginPropertyTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.closeBracket,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    beginPropertyTokens,
    NgTokenType.propertyPrefix,
    NgScannerState.scanSpecialPropertyDecorator,
  );

  var beginEventTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.closeParen,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    beginEventTokens,
    NgTokenType.eventPrefix,
    NgScannerState.scanSpecialEventDecorator,
  );

  var beginBananaTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.closeBanana,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    beginBananaTokens,
    NgTokenType.bananaPrefix,
    NgScannerState.scanSpecialBananaDecorator,
  );

  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(untokenize(tokenize('<div ="blah">')), '<div ="blah">');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 4, 1);
    expect(untokenize(tokenize('<div <!--comment-->')), '<div ><!--comment-->');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 4, 1);
    expect(untokenize(tokenize('<div <span>')), '<div ><span>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 4, 1);
    expect(untokenize(tokenize('<div </div>')), '<div ></div>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 4, 1);
    expect(untokenize(tokenize('<div ')), '<div >');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 4, 1);
    expect(untokenize(tokenize('<div "blah">')), '<div ="blah">');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 4, 1);
    expect(untokenize(tokenize("<div 'blah'>")), "<div ='blah'>");
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 4, 1);

    // Resolve2 types
    expect(untokenize(tokenize('<div ]>')), '<div []>');
    checkException(
        NgParserWarningCode.ELEMENT_DECORATOR_SUFFIX_BEFORE_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div )>')), '<div ()>');
    checkException(
        NgParserWarningCode.ELEMENT_DECORATOR_SUFFIX_BEFORE_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div )]>')), '<div [()]>');
    checkException(
        NgParserWarningCode.ELEMENT_DECORATOR_SUFFIX_BEFORE_PREFIX, 5, 2);

    // Drop tokens
    expect(untokenize(tokenize('<div !attr>')), '<div attr>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
    expect(untokenize(tokenize('<div /attr>')), '<div attr>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
    expect(untokenize(tokenize('<div ?attr>')), '<div attr>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
    expect(untokenize(tokenize('<div -attr>')), '<div attr>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
    expect(untokenize(tokenize('<div .attr>')), '<div attr>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 5, 1);
  });
}

void elementDecoratorValue() {
  var baseHtml = '<div attr=';
  var startState = NgScannerState.scanElementDecoratorValue;

  var resolveTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.openBracket,
    NgSimpleTokenType.openParen,
    NgSimpleTokenType.openBanana,
    NgSimpleTokenType.closeBracket,
    NgSimpleTokenType.closeParen,
    NgSimpleTokenType.closeBanana,
    NgSimpleTokenType.commentBegin,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.closeTagStart,
    NgSimpleTokenType.tagEnd,
    NgSimpleTokenType.voidCloseTag,
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.equalSign,
    NgSimpleTokenType.hash,
    NgSimpleTokenType.identifier,
    NgSimpleTokenType.star,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens,
    NgTokenType.doubleQuote,
    NgScannerState.scanAfterElementDecoratorValue,
  );

  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.dash,
    NgSimpleTokenType.forwardSlash,
    NgSimpleTokenType.period,
    NgSimpleTokenType.unexpectedChar,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(untokenize(tokenize('<div attr=[prop]>')), '<div attr="" [prop]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);
    expect(untokenize(tokenize('<div attr=(evnt)>')), '<div attr="" (evnt)>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);
    expect(
        untokenize(tokenize('<div attr=[(bnna)]>')), '<div attr="" [(bnna)]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);
    expect(untokenize(tokenize('<div attr=]>')), '<div attr="" []>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);
    expect(untokenize(tokenize('<div attr=)>')), '<div attr="" ()>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);
    expect(untokenize(tokenize('<div attr=)]>')), '<div attr="" [()]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);
    expect(untokenize(tokenize('<div attr=<!--comment-->')),
        '<div attr=""><!--comment-->');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);
    expect(untokenize(tokenize('<div attr=<span>')), '<div attr=""><span>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);
    expect(untokenize(tokenize('<div attr=</div>')), '<div attr=""></div>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);
    expect(untokenize(tokenize('<div attr=>')), '<div attr="">');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);
    expect(untokenize(tokenize('<div attr=/>')), '<div attr=""/>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);
    expect(untokenize(tokenize('<div attr=')), '<div attr="">');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);
    expect(untokenize(tokenize('<div attr=="blah">')), '<div attr="" ="blah">');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);
    expect(untokenize(tokenize('<div attr=#ref>')), '<div attr="" #ref>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);
    expect(untokenize(tokenize('<div attr=attr2>')), '<div attr="attr2">');
    checkException(
        NgParserWarningCode.ELEMENT_DECORATOR_VALUE_MISSING_QUOTES, 10, 5);
    expect(untokenize(tokenize('<div attr=*temp>')), '<div attr="" *temp>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);
    expect(untokenize(tokenize('<div attr=@temp>')), '<div attr="" @temp>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_VALUE, 9, 1);

    // Drop types
    expect(untokenize(tokenize('<div attr=!"blah">')), '<div attr="blah">');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 10, 1);
    expect(untokenize(tokenize('<div attr=-"blah">')), '<div attr="blah">');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 10, 1);
    expect(untokenize(tokenize('<div attr=/"blah">')), '<div attr="blah">');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 10, 1);
    expect(untokenize(tokenize('<div attr=."blah">')), '<div attr="blah">');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 10, 1);
    expect(untokenize(tokenize('<div attr=?"blah">')), '<div attr="blah">');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 10, 1);
  });
}

void elementEndClose() {
  var baseHtml = '</div';
  var startState = NgScannerState.scanElementEndClose;

  var resolveTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.commentBegin,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.closeTagStart,
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.voidCloseTag,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens,
    NgTokenType.closeElementEnd,
    NgScannerState.scanStart,
  );

  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.openBracket,
    NgSimpleTokenType.openParen,
    NgSimpleTokenType.openBanana,
    NgSimpleTokenType.closeBracket,
    NgSimpleTokenType.closeParen,
    NgSimpleTokenType.closeBanana,
    NgSimpleTokenType.hash,
    NgSimpleTokenType.star,
    NgSimpleTokenType.dash,
    NgSimpleTokenType.equalSign,
    NgSimpleTokenType.identifier,
    NgSimpleTokenType.period,
    NgSimpleTokenType.doubleQuote,
    NgSimpleTokenType.singleQuote,
    NgSimpleTokenType.unexpectedChar,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(
        untokenize(tokenize('</div <!--comment-->')), '</div ><!--comment-->');
    checkException(NgParserWarningCode.EXPECTED_TAG_CLOSE, 0, 10);
    expect(untokenize(tokenize('</div <div>')), '</div ><div>');
    checkException(NgParserWarningCode.EXPECTED_TAG_CLOSE, 0, 7);
    expect(untokenize(tokenize('</div </div>')), '</div ></div>');
    checkException(NgParserWarningCode.EXPECTED_TAG_CLOSE, 0, 8);
    expect(untokenize(tokenize('</div />')), '</div >');
    checkException(NgParserWarningCode.VOID_CLOSE_IN_CLOSE_TAG, 6, 2);

    // Drop types
    expect(untokenize(tokenize('</div !>')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('</div [>')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('</div ]>')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('</div (>')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('</div )>')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('</div [(>')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 2);
    expect(untokenize(tokenize('</div )]>')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 2);
    expect(untokenize(tokenize('</div ->')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('</div =>')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('</div .>')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('</div #>')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('</div *>')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('</div @>')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('</div blah>')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 4);
    expect(untokenize(tokenize('</div "blah">')), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 6);
    expect(untokenize(tokenize("</div 'blah'>")), '</div >');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 6);
  });
}

void interpolation() {
  var baseHtml = '{{';
  var startState = NgScannerState.scanInterpolation;

  var resolveTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.mustacheBegin,
    NgSimpleTokenType.mustacheEnd,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens,
    NgTokenType.interpolationValue,
    NgScannerState.scanAfterInterpolation,
  );

  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(untokenize(tokenize('{{')), '{{}}');
    checkException(NgParserWarningCode.UNTERMINATED_MUSTACHE, 0, 2);
    expect(untokenize(tokenize('{{{{mustache}}')), '{{}}{{mustache}}');
    checkException(NgParserWarningCode.UNTERMINATED_MUSTACHE, 0, 2);
    expect(untokenize(tokenize('{{}}')), '{{}}');
    checkException(NgParserWarningCode.EMPTY_INTERPOLATION, 0, 4);
    // All other tokens will be engrained as part of mustache expression.
  });
}

void simpleElementDecorator() {
  var baseHtml = '<div #';
  var startState = NgScannerState.scanSimpleElementDecorator;

  var resolveTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.openBracket,
    NgSimpleTokenType.openParen,
    NgSimpleTokenType.openBanana,
    NgSimpleTokenType.closeBracket,
    NgSimpleTokenType.closeParen,
    NgSimpleTokenType.closeBanana,
    NgSimpleTokenType.hash,
    NgSimpleTokenType.star,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.closeTagStart,
    NgSimpleTokenType.tagEnd,
    NgSimpleTokenType.voidCloseTag,
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.equalSign,
    NgSimpleTokenType.doubleQuote,
    NgSimpleTokenType.singleQuote,
    NgSimpleTokenType.whitespace,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens,
    NgTokenType.elementDecorator,
    NgScannerState.scanAfterElementDecorator,
  );

  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.dash,
    NgSimpleTokenType.forwardSlash,
    NgSimpleTokenType.period,
    NgSimpleTokenType.unexpectedChar,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(untokenize(tokenize('<div #[prop]>')), '<div # [prop]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);
    expect(untokenize(tokenize('<div #(evnt)>')), '<div # (evnt)>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);
    expect(untokenize(tokenize('<div #[(bnna)]>')), '<div # [(bnna)]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);
    expect(untokenize(tokenize('<div #]>')), '<div # []>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);
    expect(untokenize(tokenize('<div #)>')), '<div # ()>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);
    expect(untokenize(tokenize('<div #)]>')), '<div # [()]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);
    expect(untokenize(tokenize('<div ##ref>')), '<div # #ref>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);
    expect(untokenize(tokenize('<div #*temp>')), '<div # *temp>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);
    expect(untokenize(tokenize('<div #@temp>')), '<div # @temp>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);
    expect(untokenize(tokenize('<div #<span>')), '<div #><span>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);
    expect(untokenize(tokenize('<div #</div>')), '<div #></div>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);
    expect(untokenize(tokenize('<div #')), '<div #>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);
    expect(untokenize(tokenize('<div #="blah">')), '<div #="blah">');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);
    expect(untokenize(tokenize('<div #"blah">')), '<div #="blah">');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);
    expect(untokenize(tokenize("<div #'blah'>")), "<div #='blah'>");
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);
    expect(untokenize(tokenize('<div # attr>')), '<div # attr>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR, 5, 1);

    // Drop types
    expect(untokenize(tokenize('<div #!ref>')), '<div #ref>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('<div #-ref>')), '<div #ref>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('<div #/ref>')), '<div #ref>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('<div #.ref>')), '<div #ref>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('<div #?ref>')), '<div #ref>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
  });
}

void specialBananaDecorator() {
  var baseHtml = '<div [(';
  var startState = NgScannerState.scanSpecialBananaDecorator;

  var resolveTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.openBracket,
    NgSimpleTokenType.openParen,
    NgSimpleTokenType.openBanana,
    NgSimpleTokenType.closeBracket,
    NgSimpleTokenType.closeParen,
    NgSimpleTokenType.closeBanana,
    NgSimpleTokenType.hash,
    NgSimpleTokenType.star,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.closeTagStart,
    NgSimpleTokenType.commentBegin,
    NgSimpleTokenType.tagEnd,
    NgSimpleTokenType.voidCloseTag,
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.equalSign,
    NgSimpleTokenType.doubleQuote,
    NgSimpleTokenType.singleQuote,
    NgSimpleTokenType.whitespace,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens,
    NgTokenType.elementDecorator,
    NgScannerState.scanSuffixBanana,
  );

  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.dash,
    NgSimpleTokenType.forwardSlash,
    NgSimpleTokenType.unexpectedChar,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(untokenize(tokenize('<div [([myProp]>')), '<div [()] [myProp]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [((myEvnt)>')), '<div [()] (myEvnt)>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [([(myBnna)]>')), '<div [()] [(myBnna)]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [(]>')), '<div [()] []>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [()>')), '<div [()] ()>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [()]>')), '<div [()]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [(#myRefr>')), '<div [()] #myRefr>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [(*myTemp>')), '<div [()] *myTemp>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [(@myTemp>')), '<div [()] @myTemp>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [(<span>')), '<div [()]><span>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [(</div>')), '<div [()]></div>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [(<!--comment-->')),
        '<div [()]><!--comment-->');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [(>')), '<div [()]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [(/>')), '<div [()]/>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [(')), '<div [()]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [(="blah">')), '<div [()]="blah">');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [("blah">')), '<div [()]="blah">');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize("<div [('blah'>")), "<div [()]='blah'>");
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);
    expect(untokenize(tokenize('<div [( blah>')), '<div [()] blah>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 2);

    // Drop types
    expect(untokenize(tokenize('<div [(!bnna)]>')), '<div [(bnna)]>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 7, 1);
    expect(untokenize(tokenize('<div [(-bnna)]>')), '<div [(bnna)]>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 7, 1);
    expect(untokenize(tokenize('<div [(/bnna)]>')), '<div [(bnna)]>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 7, 1);
    expect(untokenize(tokenize('<div [(?bnna)]>')), '<div [(bnna)]>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 7, 1);
  });
}

void specialEventDecorator() {
  var baseHtml = '<div (';
  var startState = NgScannerState.scanSpecialEventDecorator;

  var resolveTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.openBracket,
    NgSimpleTokenType.openParen,
    NgSimpleTokenType.openBanana,
    NgSimpleTokenType.closeBracket,
    NgSimpleTokenType.closeParen,
    NgSimpleTokenType.closeBanana,
    NgSimpleTokenType.hash,
    NgSimpleTokenType.star,
    NgSimpleTokenType.commentBegin,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.closeTagStart,
    NgSimpleTokenType.tagEnd,
    NgSimpleTokenType.voidCloseTag,
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.equalSign,
    NgSimpleTokenType.doubleQuote,
    NgSimpleTokenType.singleQuote,
    NgSimpleTokenType.whitespace,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens,
    NgTokenType.elementDecorator,
    NgScannerState.scanSuffixEvent,
  );

  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.dash,
    NgSimpleTokenType.forwardSlash,
    NgSimpleTokenType.unexpectedChar,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(untokenize(tokenize('<div ([myProp]>')), '<div () [myProp]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div ((myEvnt)>')), '<div () (myEvnt)>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div ([(myBnna)]>')), '<div () [(myBnna)]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div (]>')), '<div () []>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div ()>')), '<div ()>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div ()]>')), '<div () [()]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div (*myTemp>')), '<div () *myTemp>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div (@myTemp>')), '<div () @myTemp>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div (#myRefr>')), '<div () #myRefr>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(
        untokenize(tokenize('<div (<!--comment-->')), '<div ()><!--comment-->');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div (<span>')), '<div ()><span>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div (</div>')), '<div ()></div>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div (>')), '<div ()>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div (/>')), '<div ()/>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div (')), '<div ()>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div (="blah">')), '<div ()="blah">');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div ("blah">')), '<div ()="blah">');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize("<div ('blah'>")), "<div ()='blah'>");
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div ( attr>')), '<div () attr>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);

    // Drop types
    expect(untokenize(tokenize('<div (!evnt)>')), '<div (evnt)>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('<div (-evnt)>')), '<div (evnt)>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('<div (?evnt)>')), '<div (evnt)>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('<div (/evnt)>')), '<div (evnt)>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
  });
}

void specialPropertyDecorator() {
  var baseHtml = '<div [';
  var startState = NgScannerState.scanSpecialPropertyDecorator;

  var resolveTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.openBracket,
    NgSimpleTokenType.openBanana,
    NgSimpleTokenType.closeBracket,
    NgSimpleTokenType.closeParen,
    NgSimpleTokenType.closeBanana,
    NgSimpleTokenType.hash,
    NgSimpleTokenType.star,
    NgSimpleTokenType.commentBegin,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.closeTagStart,
    NgSimpleTokenType.tagEnd,
    NgSimpleTokenType.voidCloseTag,
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.equalSign,
    NgSimpleTokenType.doubleQuote,
    NgSimpleTokenType.singleQuote,
    NgSimpleTokenType.whitespace,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens,
    NgTokenType.elementDecorator,
    NgScannerState.scanSuffixProperty,
  );

  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.dash,
    NgSimpleTokenType.forwardSlash,
    NgSimpleTokenType.unexpectedChar,
  ];

  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(untokenize(tokenize('<div [[myProp]>')), '<div [] [myProp]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div [[(myBnna)]>')), '<div [] [(myBnna)]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div []>')), '<div []>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div [)>')), '<div [] ()>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div [)]>')), '<div [] [()]>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div [*myTemp>')), '<div [] *myTemp>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div [@myTemp>')), '<div [] @myTemp>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div [#myRefr>')), '<div [] #myRefr>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div [')), '<div []>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div [<span>')), '<div []><span>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(
        untokenize(tokenize('<div [<!--comment-->')), '<div []><!--comment-->');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div [</div>')), '<div []></div>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div [>')), '<div []>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div [/>')), '<div []/>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div ["blah">')), '<div []="blah">');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize("<div ['blah'>")), "<div []='blah'>");
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div [="blah">')), '<div []="blah">');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);
    expect(untokenize(tokenize('<div [ attr>')), '<div [] attr>');
    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 1);

    // Drop types
    expect(untokenize(tokenize('<div [!prop]>')), '<div [prop]>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('<div [-prop]>')), '<div [prop]>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('<div [/prop]>')), '<div [prop]>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
    expect(untokenize(tokenize('<div [?prop]>')), '<div [prop]>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 6, 1);
  });
}

void suffixBanana() {
  var baseHtml = '<div [(bnna';
  var startState = NgScannerState.scanSuffixBanana;

  var resolveTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.openBracket,
    NgSimpleTokenType.openParen,
    NgSimpleTokenType.openBanana,
    NgSimpleTokenType.closeBracket,
    NgSimpleTokenType.closeParen,
    NgSimpleTokenType.hash,
    NgSimpleTokenType.star,
    NgSimpleTokenType.commentBegin,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.closeTagStart,
    NgSimpleTokenType.tagEnd,
    NgSimpleTokenType.voidCloseTag,
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.equalSign,
    NgSimpleTokenType.doubleQuote,
    NgSimpleTokenType.singleQuote,
    NgSimpleTokenType.whitespace,
  ];

  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.forwardSlash,
    NgSimpleTokenType.unexpectedChar,
  ];
  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens,
    NgTokenType.bananaSuffix,
    NgScannerState.scanAfterElementDecorator,
  );
  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  // Resolvables
  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(untokenize(tokenize('<div [(bnna[prop]>')), '<div [(bnna)] [prop]>');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(untokenize(tokenize('<div [(bnna(evnt)>')), '<div [(bnna)] (evnt)>');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(untokenize(tokenize('<div [(bnna[(bnna2)]>')),
        '<div [(bnna)] [(bnna2)]>');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(untokenize(tokenize('<div [(bnna]>')), '<div [(bnna)] []>');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(untokenize(tokenize('<div [(bnna)>')), '<div [(bnna)] ()>');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(untokenize(tokenize('<div [(bnna#refr>')), '<div [(bnna)] #refr>');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(untokenize(tokenize('<div [(bnna*templ>')), '<div [(bnna)] *templ>');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(untokenize(tokenize('<div [(bnna@templ>')), '<div [(bnna)] @templ>');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(untokenize(tokenize('<div [(bnna<!--comment-->')),
        '<div [(bnna)]><!--comment-->');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(untokenize(tokenize('<div [(bnna<span>')), '<div [(bnna)]><span>');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(untokenize(tokenize('<div [(bnna</div>')), '<div [(bnna)]></div>');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(untokenize(tokenize('<div [(bnna>')), '<div [(bnna)]>');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(untokenize(tokenize('<div [(bnna/>')), '<div [(bnna)]/>');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(untokenize(tokenize('<div [(bnna')), '<div [(bnna)]>');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(
        untokenize(tokenize('<div [(bnna="quote">')), '<div [(bnna)]="quote">');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(
        untokenize(tokenize('<div [(bnna"quote">')), '<div [(bnna)]="quote">');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(
        untokenize(tokenize("<div [(bnna'quote'>")), "<div [(bnna)]='quote'>");
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);
    expect(untokenize(tokenize('<div [(bnna attr>')), '<div [(bnna)] attr>');
    checkException(NgParserWarningCode.SUFFIX_BANANA, 5, 6);

    // Drop types
    expect(untokenize(tokenize('<div [(bnna!)]>')), '<div [(bnna)]>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 11, 1);
    expect(untokenize(tokenize('<div [(bnna/)]>')), '<div [(bnna)]>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 11, 1);
    expect(untokenize(tokenize('<div [(bnna?)]>')), '<div [(bnna)]>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 11, 1);
  });
}

void suffixEvent() {
  var baseHtml = '<div (evnt';
  var startState = NgScannerState.scanSuffixEvent;

  var resolveTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.openBracket,
    NgSimpleTokenType.openParen,
    NgSimpleTokenType.openBanana,
    NgSimpleTokenType.closeBracket,
    NgSimpleTokenType.closeBanana,
    NgSimpleTokenType.hash,
    NgSimpleTokenType.star,
    NgSimpleTokenType.commentBegin,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.closeTagStart,
    NgSimpleTokenType.tagEnd,
    NgSimpleTokenType.voidCloseTag,
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.equalSign,
    NgSimpleTokenType.doubleQuote,
    NgSimpleTokenType.singleQuote,
    NgSimpleTokenType.whitespace,
  ];
  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.forwardSlash,
    NgSimpleTokenType.unexpectedChar,
  ];
  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens,
    NgTokenType.eventSuffix,
    NgScannerState.scanAfterElementDecorator,
  );
  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  // Resolvables
  test('Testing resolved strings of $startState', () {
    // Resolve1 types
    expect(untokenize(tokenize('<div (evnt[prop]>')), '<div (evnt) [prop]>');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize('<div (evnt(evnt2)>')), '<div (evnt) (evnt2)>');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(
        untokenize(tokenize('<div (evnt[(bnna)]>')), '<div (evnt) [(bnna)]>');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize('<div (evnt]>')), '<div (evnt) []>');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize('<div (evnt)]>')), '<div (evnt) [()]>');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize('<div (evnt#refr>')), '<div (evnt) #refr>');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize('<div (evnt*templ>')), '<div (evnt) *templ>');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize('<div (evnt@templ>')), '<div (evnt) @templ>');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize('<div (evnt<!--comment-->')),
        '<div (evnt)><!--comment-->');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize('<div (evnt<span>')), '<div (evnt)><span>');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize('<div (evnt</div>')), '<div (evnt)></div>');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize('<div (evnt>')), '<div (evnt)>');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize('<div (evnt/>')), '<div (evnt)/>');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize('<div (evnt')), '<div (evnt)>');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize('<div (evnt="quote">')), '<div (evnt)="quote">');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize('<div (evnt"quote">')), '<div (evnt)="quote">');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize("<div (evnt'quote'>")), "<div (evnt)='quote'>");
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);
    expect(untokenize(tokenize('<div (evnt attr>')), '<div (evnt) attr>');
    checkException(NgParserWarningCode.SUFFIX_EVENT, 5, 5);

    // Drop types
    expect(untokenize(tokenize('<div (evnt!)>')), '<div (evnt)>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 10, 1);
    expect(untokenize(tokenize('<div (evnt/)>')), '<div (evnt)>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 10, 1);
    expect(untokenize(tokenize('<div (evnt?)>')), '<div (evnt)>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 10, 1);
  });
}

void suffixProperty() {
  var baseHtml = '<div [prop';
  var startState = NgScannerState.scanSuffixProperty;

  var resolveTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.openBracket,
    NgSimpleTokenType.openParen,
    NgSimpleTokenType.openBanana,
    NgSimpleTokenType.closeBracket,
    NgSimpleTokenType.closeBanana,
    NgSimpleTokenType.hash,
    NgSimpleTokenType.star,
    NgSimpleTokenType.commentBegin,
    NgSimpleTokenType.openTagStart,
    NgSimpleTokenType.closeTagStart,
    NgSimpleTokenType.tagEnd,
    NgSimpleTokenType.voidCloseTag,
    NgSimpleTokenType.EOF,
    NgSimpleTokenType.equalSign,
    NgSimpleTokenType.doubleQuote,
    NgSimpleTokenType.whitespace,
  ];
  var dropTokens = <NgSimpleTokenType>[
    NgSimpleTokenType.bang,
    NgSimpleTokenType.forwardSlash,
    NgSimpleTokenType.unexpectedChar,
  ];
  testRecoverySolution(
    baseHtml,
    startState,
    resolveTokens,
    NgTokenType.propertySuffix,
    NgScannerState.scanAfterElementDecorator,
  );
  testRecoverySolution(
    baseHtml,
    startState,
    dropTokens,
    null,
    null,
  );

  // Resolvables
  test('Testing resolved strings of $startState', () {
    expect(untokenize(tokenize('<div [prop[prop2]>')), '<div [prop] [prop2]>');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize('<div [prop(evnt)>')), '<div [prop] (evnt)>');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(
        untokenize(tokenize('<div [prop[(bnna)]>')), '<div [prop] [(bnna)]>');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize('<div [prop)>')), '<div [prop] ()>');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize('<div [prop)]>')), '<div [prop] [()]>');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize('<div [prop#refr>')), '<div [prop] #refr>');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize('<div [prop*templ>')), '<div [prop] *templ>');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize('<div [prop@templ>')), '<div [prop] @templ>');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize('<div [prop<!--comment-->')),
        '<div [prop]><!--comment-->');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize('<div [prop<span>')), '<div [prop]><span>');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize('<div [prop</div>')), '<div [prop]></div>');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize('<div [prop>')), '<div [prop]>');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize('<div [prop/>')), '<div [prop]/>');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize('<div [prop')), '<div [prop]>');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize('<div [prop="quote">')), '<div [prop]="quote">');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize('<div [prop"quote">')), '<div [prop]="quote">');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize("<div [prop'quote'>")), "<div [prop]='quote'>");
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);
    expect(untokenize(tokenize('<div [prop attr>')), '<div [prop] attr>');
    checkException(NgParserWarningCode.SUFFIX_PROPERTY, 5, 5);

    // Drop types
    expect(untokenize(tokenize('<div [prop!]>')), '<div [prop]>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 10, 1);
    expect(untokenize(tokenize('<div [prop?]>')), '<div [prop]>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 10, 1);
    expect(untokenize(tokenize('<div [prop/]>')), '<div [prop]>');
    checkException(NgParserWarningCode.UNEXPECTED_TOKEN, 10, 1);
  });
}
