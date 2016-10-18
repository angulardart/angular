import 'package:angular2_template_parser/src/lexer.dart';
import 'package:test/test.dart';

void main() {
  NgTemplateLexer lexer;

  test('should lex a simple text node', () async {
    lexer = new NgTemplateLexer('Hello World');
    expect(
      await lexer.tokenize().toList(),
      [
        new NgToken(NgTokenType.textNode, 'Hello World'),
      ],
    );
  });

  test('should lex a simple text node and elements', () async {
    lexer = new NgTemplateLexer('<span>Hello World</span>');
    expect(
      await lexer.tokenize().toList(),
      [
        new NgToken(NgTokenType.startOpenElement, '<'),
        new NgToken(NgTokenType.elementName, 'span'),
        new NgToken(NgTokenType.endOpenElement, '>'),
        new NgToken(NgTokenType.textNode, 'Hello World'),
        new NgToken(NgTokenType.startCloseElement, '</'),
        new NgToken(NgTokenType.elementName, 'span'),
        new NgToken(NgTokenType.endCloseElement, '>'),
      ],
    );
  });

  test('should lex a set of text and element nodes', () async {
    lexer = new NgTemplateLexer('<div>\n'
        '  <span>Hello<em>World</em>!</span>\n'
        '</div>');
    expect(
      await lexer.tokenize().toList(),
      [
        new NgToken(NgTokenType.startOpenElement, '<'),
        new NgToken(NgTokenType.elementName, 'div'),
        new NgToken(NgTokenType.endOpenElement, '>'),
        new NgToken(NgTokenType.textNode, '\n  '),
        new NgToken(NgTokenType.startOpenElement, '<'),
        new NgToken(NgTokenType.elementName, 'span'),
        new NgToken(NgTokenType.endOpenElement, '>'),
        new NgToken(NgTokenType.textNode, 'Hello'),
        new NgToken(NgTokenType.startOpenElement, '<'),
        new NgToken(NgTokenType.elementName, 'em'),
        new NgToken(NgTokenType.endOpenElement, '>'),
        new NgToken(NgTokenType.textNode, 'World'),
        new NgToken(NgTokenType.startCloseElement, '</'),
        new NgToken(NgTokenType.elementName, 'em'),
        new NgToken(NgTokenType.endCloseElement, '>'),
        new NgToken(NgTokenType.textNode, '!'),
        new NgToken(NgTokenType.startCloseElement, '</'),
        new NgToken(NgTokenType.elementName, 'span'),
        new NgToken(NgTokenType.endCloseElement, '>'),
        new NgToken(NgTokenType.textNode, '\n'),
        new NgToken(NgTokenType.startCloseElement, '</'),
        new NgToken(NgTokenType.elementName, 'div'),
        new NgToken(NgTokenType.endCloseElement, '>'),
      ],
    );
  });

  test('should lex attributes with and without a value', () async {
    lexer = new NgTemplateLexer(
      '<div class="fancy" title="Hello"><button disabled></button></div>',
    );
    expect(await lexer.tokenize().toList(), [
      new NgToken(NgTokenType.startOpenElement, '<'),
      new NgToken(NgTokenType.elementName, 'div'),
      new NgToken(NgTokenType.beforeElementDecorator, ' '),
      new NgToken(NgTokenType.attributeName, 'class'),
      new NgToken(NgTokenType.beforeDecoratorValue, '="'),
      new NgToken(NgTokenType.attributeValue, 'fancy'),
      new NgToken(NgTokenType.endAttribute, '"'),
      new NgToken(NgTokenType.beforeElementDecorator, ' '),
      new NgToken(NgTokenType.attributeName, 'title'),
      new NgToken(NgTokenType.beforeDecoratorValue, '="'),
      new NgToken(NgTokenType.attributeValue, 'Hello'),
      new NgToken(NgTokenType.endAttribute, '"'),
      new NgToken(NgTokenType.endOpenElement, '>'),
      new NgToken(NgTokenType.startOpenElement, '<'),
      new NgToken(NgTokenType.elementName, 'button'),
      new NgToken(NgTokenType.beforeElementDecorator, ' '),
      new NgToken(NgTokenType.attributeName, 'disabled'),
      new NgToken(NgTokenType.endAttribute, ''),
      new NgToken(NgTokenType.endOpenElement, '>'),
      new NgToken(NgTokenType.startCloseElement, '</'),
      new NgToken(NgTokenType.elementName, 'button'),
      new NgToken(NgTokenType.endCloseElement, '>'),
      new NgToken(NgTokenType.startCloseElement, '</'),
      new NgToken(NgTokenType.elementName, 'div'),
      new NgToken(NgTokenType.endCloseElement, '>'),
    ]);
  });
}
