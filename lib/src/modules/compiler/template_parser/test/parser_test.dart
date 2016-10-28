import 'package:angular2_template_parser/src/ast.dart';
import 'package:angular2_template_parser/src/parser.dart';
import 'package:test/test.dart';

void main() {
  List<NgAstNode> parse(String text) =>
      new NgTemplateParser().parse(text).toList();

  group('$NgTemplateParser', () {
    test('should parse text nodes', () {
      var nodes = parse(r'Hello World');
      expect(
        nodes,
        [
          new NgText('Hello World'),
        ],
      );
    });

    test('should parse element nodes', () {
      var nodes = parse('<div><span>Hello World</span></div>');
      expect(
        nodes,
        [
          new NgElement.unknown('div', childNodes: [
            new NgElement.unknown('span', childNodes: [
              new NgText('Hello World'),
            ]),
          ]),
        ],
      );
    });

    test('should parse a complex set of element nodes', () {
      var nodes = parse('<div>\n'
          '  <div>\n'
          '    <span>Hello World</span>\n'
          '  </div>\n'
          '</div>\n');
      expect(
        nodes,
        [
          new NgElement.unknown('div', childNodes: [
            new NgText('\n  '),
            new NgElement.unknown('div', childNodes: [
              new NgText('\n    '),
              new NgElement.unknown('span', childNodes: [
                new NgText('Hello World'),
              ]),
              new NgText('\n  '),
            ]),
            new NgText('\n'),
          ]),
          new NgText('\n'),
        ],
      );
    });

    test('should parse a comment', () {
      expect(
        parse('<!--Hello World-->'),
        [
          new NgComment('Hello World'),
        ],
      );
    });

    test('should parse a comment in a nested DOM tree', () {
      expect(
        parse('<div>\n'
            '  <span>Hello<!--World--></span>\n'
            '</div>'),
        [
          new NgElement.unknown('div', childNodes: [
            new NgText('\n  '),
            new NgElement.unknown('span', childNodes: [
              new NgText('Hello'),
              new NgComment('World'),
            ]),
            new NgText('\n'),
          ])
        ],
      );
    });

    test('should parse an attribute', () {
      expect(
        parse('<button class="fancy" disabled>Hello</button>'),
        [
          new NgElement.unknown('button', childNodes: [
            new NgAttribute('class', 'fancy'),
            new NgAttribute('disabled'),
            new NgText('Hello'),
          ]),
        ],
      );
    });

    test('should parse a property', () {
      expect(
        parse('<button [title]="hint">Hello</button>'),
        [
          new NgElement.unknown('button', childNodes: [
            new NgProperty('title', 'hint'),
            new NgText('Hello'),
          ]),
        ],
      );
    });

    test('should parse an event', () {
      expect(
        parse('<button (click)="onClick()">Hello</button>'),
        [
          new NgElement.unknown('button', childNodes: [
            new NgEvent('click', 'onClick()'),
            new NgText('Hello'),
          ]),
        ],
      );
    });
  });
}
