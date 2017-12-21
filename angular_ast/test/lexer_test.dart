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
      .fold(new StringBuffer(), (buffer, token) => buffer..write(token.lexeme))
      .toString();

  test('should tokenize plain text', () {
    expect(
      tokenize('Hello World'),
      [
        new NgToken.text(0, 'Hello World'),
      ],
    );
  });

  test('should tokenize mulitline text', () {
    expect(
      tokenize('Hello\nWorld'),
      [
        new NgToken.text(0, 'Hello\nWorld'),
      ],
    );
  });

  test('should tokenize escaped text', () {
    expect(
      tokenize('&lt;div&gt;'),
      [
        new NgToken.text(0, '<div>'),
      ],
    );
  });

  test('should tokenize an HTML element', () {
    expect(
      tokenize('<div></div>'),
      [
        new NgToken.openElementStart(0),
        new NgToken.elementIdentifier(1, 'div'),
        new NgToken.openElementEnd(4),
        new NgToken.closeElementStart(5),
        new NgToken.elementIdentifier(7, 'div'),
        new NgToken.closeElementEnd(10),
      ],
    );
  });

  test('should tokenize an HTML element that is explicitly void', () {
    expect(
      tokenize('<hr  />'),
      [
        new NgToken.openElementStart(0),
        new NgToken.elementIdentifier(1, 'hr'),
        new NgToken.whitespace(3, '  '),
        new NgToken.openElementEndVoid(5),
      ],
    );
  });

  test('should tokenize nested HTML elements', () {
    expect(
      tokenize('<div><span></span></div>'),
      [
        new NgToken.openElementStart(0),
        new NgToken.elementIdentifier(1, 'div'),
        new NgToken.openElementEnd(4),
        new NgToken.openElementStart(5),
        new NgToken.elementIdentifier(6, 'span'),
        new NgToken.openElementEnd(10),
        new NgToken.closeElementStart(11),
        new NgToken.elementIdentifier(13, 'span'),
        new NgToken.closeElementEnd(17),
        new NgToken.closeElementStart(18),
        new NgToken.elementIdentifier(20, 'div'),
        new NgToken.closeElementEnd(23),
      ],
    );
  });

  test('should tokenize HTML elements mixed with plain text', () {
    expect(
      tokenize('<div >Hello</div>'),
      [
        new NgToken.openElementStart(0),
        new NgToken.elementIdentifier(1, 'div'),
        new NgToken.whitespace(4, ' '),
        new NgToken.openElementEnd(5),
        new NgToken.text(6, 'Hello'),
        new NgToken.closeElementStart(11),
        new NgToken.elementIdentifier(13, 'div'),
        new NgToken.closeElementEnd(16),
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
        new NgToken.openElementStart(0),
        new NgToken.elementIdentifier(1, 'button'),
        new NgToken.beforeElementDecorator(7, ' '),
        new NgToken.elementDecorator(8, 'disabled'),
        new NgToken.openElementEnd(16),
        new NgToken.closeElementStart(17),
        new NgToken.elementIdentifier(19, 'button'),
        new NgToken.closeElementEnd(25),
      ],
    );
  });

  test('should tokenize an element with multiple value-less decorators', () {
    expect(
      tokenize('<button disabled hidden></button>'),
      [
        new NgToken.openElementStart(0),
        new NgToken.elementIdentifier(1, 'button'),
        new NgToken.beforeElementDecorator(7, ' '),
        new NgToken.elementDecorator(8, 'disabled'),
        new NgToken.beforeElementDecorator(16, ' '),
        new NgToken.elementDecorator(17, 'hidden'),
        new NgToken.openElementEnd(23),
        new NgToken.closeElementStart(24),
        new NgToken.elementIdentifier(26, 'button'),
        new NgToken.closeElementEnd(32),
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
        new NgToken.openElementStart(0),
        new NgToken.elementIdentifier(1, 'button'),
        new NgToken.beforeElementDecorator(7, ' '),
        new NgToken.elementDecorator(8, 'title'),
        new NgToken.whitespace(13, ' '),
        new NgToken.beforeElementDecoratorValue(14),
        new NgToken.whitespace(15, '  '),
        new NgAttributeValueToken.generate(
            new NgToken.doubleQuote(17),
            new NgToken.elementDecoratorValue(18, 'Submit'),
            new NgToken.doubleQuote(24)),
        new NgToken.whitespace(25, '  '),
        new NgToken.openElementEnd(27),
        new NgToken.closeElementStart(28),
        new NgToken.elementIdentifier(30, 'button'),
        new NgToken.closeElementEnd(36),
      ],
    );
  });

  test('should tokenize an element with a namespaced attribute', () {
    expect(
      tokenize('<use xlink:href="foo"></use>'),
      [
        new NgToken.openElementStart(0),
        new NgToken.elementIdentifier(1, 'use'),
        new NgToken.beforeElementDecorator(4, ' '),
        new NgToken.elementDecorator(5, 'xlink:href'),
        new NgToken.beforeElementDecoratorValue(15),
        new NgAttributeValueToken.generate(
            new NgToken.doubleQuote(16),
            new NgToken.elementDecoratorValue(17, 'foo'),
            new NgToken.doubleQuote(20)),
        new NgToken.openElementEnd(21),
        new NgToken.closeElementStart(22),
        new NgToken.elementIdentifier(24, 'use'),
        new NgToken.closeElementEnd(27),
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
        new NgToken.commentStart(0),
        new NgToken.commentValue(4, 'Hello World'),
        new NgToken.commentEnd(15),
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
        new NgToken.commentStart(0),
        new NgToken.commentValue(
          4,
          '\n  Copyright (c) 2016, the Dart project authors.\n',
        ),
        new NgToken.commentEnd(53),
      ],
    );
  });

  test('should tokenize interpolation', () {
    expect(
      tokenize('{{name}}'),
      [
        new NgToken.interpolationStart(0),
        new NgToken.interpolationValue(2, 'name'),
        new NgToken.interpolationEnd(6),
      ],
    );
  });

  test('should tokenize function call interpolations', () {
    expect(
      tokenize('{{msgCharacterCounter(inputTextLength, maxCount)}}'),
      [
        new NgToken.interpolationStart(0),
        new NgToken.interpolationValue(
          2,
          'msgCharacterCounter(inputTextLength, maxCount)',
        ),
        new NgToken.interpolationEnd(48),
      ],
    );
  });

  test('should tokenize an HTML element with property binding', () {
    expect(
      tokenize('<div [style.max-height.px]  =  "contentHeight"></div>'),
      [
        new NgToken.openElementStart(0),
        new NgToken.elementIdentifier(1, 'div'),
        new NgToken.beforeElementDecorator(4, ' '),
        new NgToken.propertyPrefix(5),
        new NgToken.elementDecorator(6, 'style.max-height.px'),
        new NgToken.propertySuffix(25),
        new NgToken.whitespace(26, '  '),
        new NgToken.beforeElementDecoratorValue(28),
        new NgToken.whitespace(29, '  '),
        new NgAttributeValueToken.generate(
            new NgToken.doubleQuote(31),
            new NgToken.elementDecoratorValue(32, 'contentHeight'),
            new NgToken.doubleQuote(45)),
        new NgToken.openElementEnd(46),
        new NgToken.closeElementStart(47),
        new NgToken.elementIdentifier(49, 'div'),
        new NgToken.closeElementEnd(52)
      ],
    );
  });

  test('should tokenize an HTML element with a namespaced attr binding', () {
    expect(
      tokenize('<use [attr.xlink:href]="foo"></use>'),
      [
        new NgToken.openElementStart(0),
        new NgToken.elementIdentifier(1, 'use'),
        new NgToken.beforeElementDecorator(4, ' '),
        new NgToken.propertyPrefix(5),
        new NgToken.elementDecorator(6, 'attr.xlink:href'),
        new NgToken.propertySuffix(21),
        new NgToken.beforeElementDecoratorValue(22),
        new NgAttributeValueToken.generate(
            new NgToken.doubleQuote(23),
            new NgToken.elementDecoratorValue(24, 'foo'),
            new NgToken.doubleQuote(27)),
        new NgToken.openElementEnd(28),
        new NgToken.closeElementStart(29),
        new NgToken.elementIdentifier(31, 'use'),
        new NgToken.closeElementEnd(34)
      ],
    );
  });

  test('should tokenize an HTML element with event binding', () {
    expect(
      tokenize('<div (someEvent.someInnerValue)  =  "x + 5"></div>'),
      [
        new NgToken.openElementStart(0),
        new NgToken.elementIdentifier(1, 'div'),
        new NgToken.beforeElementDecorator(4, ' '),
        new NgToken.eventPrefix(5),
        new NgToken.elementDecorator(6, 'someEvent.someInnerValue'),
        new NgToken.eventSuffix(30),
        new NgToken.whitespace(31, '  '),
        new NgToken.beforeElementDecoratorValue(33),
        new NgToken.whitespace(34, '  '),
        new NgAttributeValueToken.generate(
            new NgToken.doubleQuote(36),
            new NgToken.elementDecoratorValue(37, 'x + 5'),
            new NgToken.doubleQuote(42)),
        new NgToken.openElementEnd(43),
        new NgToken.closeElementStart(44),
        new NgToken.elementIdentifier(46, 'div'),
        new NgToken.closeElementEnd(49)
      ],
    );
  });

  test('should tokenize an HTML element with banana binding', () {
    expect(tokenize('<div [(banana)]="doSomething"></div>'), [
      new NgToken.openElementStart(0),
      new NgToken.elementIdentifier(1, 'div'),
      new NgToken.beforeElementDecorator(4, ' '),
      new NgToken.bananaPrefix(5),
      new NgToken.elementDecorator(7, 'banana'),
      new NgToken.bananaSuffix(13),
      new NgToken.beforeElementDecoratorValue(15),
      new NgAttributeValueToken.generate(
          new NgToken.doubleQuote(16),
          new NgToken.elementDecoratorValue(17, 'doSomething'),
          new NgToken.doubleQuote(28)),
      new NgToken.openElementEnd(29),
      new NgToken.closeElementStart(30),
      new NgToken.elementIdentifier(32, 'div'),
      new NgToken.closeElementEnd(35),
    ]);
  });

  test('should tokenize elementDecorator ending in period', () {
    expect(
      tokenize('<div blah.>'),
      [
        new NgToken.openElementStart(0),
        new NgToken.elementIdentifier(1, 'div'),
        new NgToken.beforeElementDecorator(4, ' '),
        new NgToken.elementDecorator(5, 'blah.'),
        new NgToken.openElementEnd(10)
      ],
    );
  });
}
