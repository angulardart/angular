// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:angular_ast/angular_ast.dart';
import 'package:test/test.dart';

void main() {
  // Returns the html parsed as a series of tokens.
  var exceptionHandler = const ThrowingExceptionHandler();
  Iterable<NgToken> tokenize(String html) =>
      const NgLexer().tokenize(html, exceptionHandler);

  // Returns the html parsed as a series of tokens, then back to html.
  String untokenize(Iterable<NgToken> tokens) => tokens
      .fold(StringBuffer(), (buffer, token) => buffer..write(token.lexeme))
      .toString();

  test('should tokenize plain text', () {
    expect(
      tokenize('Hello World'),
      [
        NgToken.text(0, 'Hello World'),
      ],
    );
  });

  test('should tokenize mulitline text', () {
    expect(
      tokenize('Hello\nWorld'),
      [
        NgToken.text(0, 'Hello\nWorld'),
      ],
    );
  });

  test('should tokenize escaped text', () {
    expect(
      tokenize('&lt;div&gt;'),
      [
        NgToken.text(0, '<div>'),
      ],
    );
  });

  test('should tokenize an HTML element', () {
    expect(
      tokenize('<div></div>'),
      [
        NgToken.openElementStart(0),
        NgToken.elementIdentifier(1, 'div'),
        NgToken.openElementEnd(4),
        NgToken.closeElementStart(5),
        NgToken.elementIdentifier(7, 'div'),
        NgToken.closeElementEnd(10),
      ],
    );
  });

  test('should tokenize an HTML element that is explicitly void', () {
    expect(
      tokenize('<hr  />'),
      [
        NgToken.openElementStart(0),
        NgToken.elementIdentifier(1, 'hr'),
        NgToken.whitespace(3, '  '),
        NgToken.openElementEndVoid(5),
      ],
    );
  });

  test('should tokenize nested HTML elements', () {
    expect(
      tokenize('<div><span></span></div>'),
      [
        NgToken.openElementStart(0),
        NgToken.elementIdentifier(1, 'div'),
        NgToken.openElementEnd(4),
        NgToken.openElementStart(5),
        NgToken.elementIdentifier(6, 'span'),
        NgToken.openElementEnd(10),
        NgToken.closeElementStart(11),
        NgToken.elementIdentifier(13, 'span'),
        NgToken.closeElementEnd(17),
        NgToken.closeElementStart(18),
        NgToken.elementIdentifier(20, 'div'),
        NgToken.closeElementEnd(23),
      ],
    );
  });

  test('should tokenize HTML elements mixed with plain text', () {
    expect(
      tokenize('<div >Hello</div>'),
      [
        NgToken.openElementStart(0),
        NgToken.elementIdentifier(1, 'div'),
        NgToken.whitespace(4, ' '),
        NgToken.openElementEnd(5),
        NgToken.text(6, 'Hello'),
        NgToken.closeElementStart(11),
        NgToken.elementIdentifier(13, 'div'),
        NgToken.closeElementEnd(16),
      ],
    );
  });

  // This is both easier to write than a large Iterable<NgToken> assertion and
  // also verifies that the tokenizing is stable - that is, you can reproduce
  // the original parsed string from the tokens.
  test('should tokenize a HTML template and untokenize back', () {
    const html = r'''
      <div>
        <span>Hello World</span>
        <ul>
          <li>1</li>
          <li>2</li>
          <li>
            <strong>3</strong>
          </li>
        </ul>
      </div>
    ''';
    expect(untokenize(tokenize(html)), html);
  });

  test('should tokenize an element with a value-less decorator', () {
    expect(
      tokenize('<button disabled></button>'),
      [
        NgToken.openElementStart(0),
        NgToken.elementIdentifier(1, 'button'),
        NgToken.beforeElementDecorator(7, ' '),
        NgToken.elementDecorator(8, 'disabled'),
        NgToken.openElementEnd(16),
        NgToken.closeElementStart(17),
        NgToken.elementIdentifier(19, 'button'),
        NgToken.closeElementEnd(25),
      ],
    );
  });

  test('should tokenize an element with multiple value-less decorators', () {
    expect(
      tokenize('<button disabled hidden></button>'),
      [
        NgToken.openElementStart(0),
        NgToken.elementIdentifier(1, 'button'),
        NgToken.beforeElementDecorator(7, ' '),
        NgToken.elementDecorator(8, 'disabled'),
        NgToken.beforeElementDecorator(16, ' '),
        NgToken.elementDecorator(17, 'hidden'),
        NgToken.openElementEnd(23),
        NgToken.closeElementStart(24),
        NgToken.elementIdentifier(26, 'button'),
        NgToken.closeElementEnd(32),
      ],
    );
  });

  // This is both easier to write than a large Iterable<NgToken> assertion and
  // also verifies that the tokenizing is stable - that is, you can reproduce
  // the original parsed string from the tokens.
  test('should tokenize a HTML template with decorators and back', () {
    const html = r'''
      <div>
        <span hidden>Hello World</span>
        <ul>
          <li>1</li>
          <li>2</li>
          <li>
            <button disabled>3</button>
          </li>
        </ul>
      </div>
    ''';
    expect(untokenize(tokenize(html)), html);
  });

  test('should tokenize an element with a decorator with a value', () {
    expect(
      tokenize('<button title =  "Submit"  ></button>'),
      [
        NgToken.openElementStart(0),
        NgToken.elementIdentifier(1, 'button'),
        NgToken.beforeElementDecorator(7, ' '),
        NgToken.elementDecorator(8, 'title'),
        NgToken.whitespace(13, ' '),
        NgToken.beforeElementDecoratorValue(14),
        NgToken.whitespace(15, '  '),
        NgAttributeValueToken.generate(
            NgToken.doubleQuote(17),
            NgToken.elementDecoratorValue(18, 'Submit'),
            NgToken.doubleQuote(24)),
        NgToken.whitespace(25, '  '),
        NgToken.openElementEnd(27),
        NgToken.closeElementStart(28),
        NgToken.elementIdentifier(30, 'button'),
        NgToken.closeElementEnd(36),
      ],
    );
  });

  test('should tokenize an element with a namespaced attribute', () {
    expect(
      tokenize('<use xlink:href="foo"></use>'),
      [
        NgToken.openElementStart(0),
        NgToken.elementIdentifier(1, 'use'),
        NgToken.beforeElementDecorator(4, ' '),
        NgToken.elementDecorator(5, 'xlink:href'),
        NgToken.beforeElementDecoratorValue(15),
        NgAttributeValueToken.generate(NgToken.doubleQuote(16),
            NgToken.elementDecoratorValue(17, 'foo'), NgToken.doubleQuote(20)),
        NgToken.openElementEnd(21),
        NgToken.closeElementStart(22),
        NgToken.elementIdentifier(24, 'use'),
        NgToken.closeElementEnd(27),
      ],
    );
  });

  // This is both easier to write than a large Iterable<NgToken> assertion and
  // also verifies that the tokenizing is stable - that is, you can reproduce
  // the original parsed string from the tokens.
  test('should tokenize a HTML template with decorator values and back', () {
    const html = r'''
      <div>
        <span hidden>Hello World</span>
        <ul>
          <li>1</li>
          <li>
            <textarea disabled name  =  "box" readonly>Test</textarea>
          </li>
          <li>
            <button disabled>3</button>
          </li>
        </ul>
      </div>
    ''';
    expect(untokenize(tokenize(html)), html);
  });

  test('should tokenize a comment', () {
    expect(
      tokenize('<!--Hello World-->'),
      [
        NgToken.commentStart(0),
        NgToken.commentValue(4, 'Hello World'),
        NgToken.commentEnd(15),
      ],
    );
  });

  test('should tokenize copyright comments', () {
    expect(
      tokenize(''
          '<!--\n'
          '  Copyright (c) 2016, the Dart project authors.\n'
          '-->'),
      [
        NgToken.commentStart(0),
        NgToken.commentValue(
          4,
          '\n  Copyright (c) 2016, the Dart project authors.\n',
        ),
        NgToken.commentEnd(53),
      ],
    );
  });

  test('should tokenize interpolation', () {
    expect(
      tokenize('{{name}}'),
      [
        NgToken.interpolationStart(0),
        NgToken.interpolationValue(2, 'name'),
        NgToken.interpolationEnd(6),
      ],
    );
  });

  test('should tokenize function call interpolations', () {
    expect(
      tokenize('{{msgCharacterCounter(inputTextLength, maxCount)}}'),
      [
        NgToken.interpolationStart(0),
        NgToken.interpolationValue(
          2,
          'msgCharacterCounter(inputTextLength, maxCount)',
        ),
        NgToken.interpolationEnd(48),
      ],
    );
  });

  test('should tokenize an HTML element with property binding', () {
    expect(
      tokenize('<div [style.max-height.px]  =  "contentHeight"></div>'),
      [
        NgToken.openElementStart(0),
        NgToken.elementIdentifier(1, 'div'),
        NgToken.beforeElementDecorator(4, ' '),
        NgToken.propertyPrefix(5),
        NgToken.elementDecorator(6, 'style.max-height.px'),
        NgToken.propertySuffix(25),
        NgToken.whitespace(26, '  '),
        NgToken.beforeElementDecoratorValue(28),
        NgToken.whitespace(29, '  '),
        NgAttributeValueToken.generate(
            NgToken.doubleQuote(31),
            NgToken.elementDecoratorValue(32, 'contentHeight'),
            NgToken.doubleQuote(45)),
        NgToken.openElementEnd(46),
        NgToken.closeElementStart(47),
        NgToken.elementIdentifier(49, 'div'),
        NgToken.closeElementEnd(52)
      ],
    );
  });

  test('should tokenize an HTML element with a namespaced attr binding', () {
    expect(
      tokenize('<use [attr.xlink:href]="foo"></use>'),
      [
        NgToken.openElementStart(0),
        NgToken.elementIdentifier(1, 'use'),
        NgToken.beforeElementDecorator(4, ' '),
        NgToken.propertyPrefix(5),
        NgToken.elementDecorator(6, 'attr.xlink:href'),
        NgToken.propertySuffix(21),
        NgToken.beforeElementDecoratorValue(22),
        NgAttributeValueToken.generate(NgToken.doubleQuote(23),
            NgToken.elementDecoratorValue(24, 'foo'), NgToken.doubleQuote(27)),
        NgToken.openElementEnd(28),
        NgToken.closeElementStart(29),
        NgToken.elementIdentifier(31, 'use'),
        NgToken.closeElementEnd(34)
      ],
    );
  });

  test('should tokenize an HTML element with event binding', () {
    expect(
      tokenize('<div (someEvent.someInnerValue)  =  "x + 5"></div>'),
      [
        NgToken.openElementStart(0),
        NgToken.elementIdentifier(1, 'div'),
        NgToken.beforeElementDecorator(4, ' '),
        NgToken.eventPrefix(5),
        NgToken.elementDecorator(6, 'someEvent.someInnerValue'),
        NgToken.eventSuffix(30),
        NgToken.whitespace(31, '  '),
        NgToken.beforeElementDecoratorValue(33),
        NgToken.whitespace(34, '  '),
        NgAttributeValueToken.generate(
            NgToken.doubleQuote(36),
            NgToken.elementDecoratorValue(37, 'x + 5'),
            NgToken.doubleQuote(42)),
        NgToken.openElementEnd(43),
        NgToken.closeElementStart(44),
        NgToken.elementIdentifier(46, 'div'),
        NgToken.closeElementEnd(49)
      ],
    );
  });

  test('should tokenize an HTML element with banana binding', () {
    expect(tokenize('<div [(banana)]="doSomething"></div>'), [
      NgToken.openElementStart(0),
      NgToken.elementIdentifier(1, 'div'),
      NgToken.beforeElementDecorator(4, ' '),
      NgToken.bananaPrefix(5),
      NgToken.elementDecorator(7, 'banana'),
      NgToken.bananaSuffix(13),
      NgToken.beforeElementDecoratorValue(15),
      NgAttributeValueToken.generate(
          NgToken.doubleQuote(16),
          NgToken.elementDecoratorValue(17, 'doSomething'),
          NgToken.doubleQuote(28)),
      NgToken.openElementEnd(29),
      NgToken.closeElementStart(30),
      NgToken.elementIdentifier(32, 'div'),
      NgToken.closeElementEnd(35),
    ]);
  });

  test('should tokenize elementDecorator ending in period', () {
    expect(
      tokenize('<div blah.>'),
      [
        NgToken.openElementStart(0),
        NgToken.elementIdentifier(1, 'div'),
        NgToken.beforeElementDecorator(4, ' '),
        NgToken.elementDecorator(5, 'blah.'),
        NgToken.openElementEnd(10)
      ],
    );
  });
}
