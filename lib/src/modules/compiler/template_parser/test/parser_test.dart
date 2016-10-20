import 'package:angular2_template_parser/src/ast.dart';
import 'package:angular2_template_parser/src/parser.dart';
import 'package:test/test.dart';

void main() {
  group('$NgTemplateParser', () {
    test('should parse text nodes', () {
      var nodes = new NgTemplateParser().parse(r'Hello World').toList();
      expect(
        nodes,
        [
          new NgText('Hello World'),
        ],
      );
    });

    test('should parse element nodes', () {
      var nodes = new NgTemplateParser()
          .parse(
            '<div><span>Hello World</span></div>',
          )
          .toList();
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
      var nodes = new NgTemplateParser()
          .parse('<div>\n'
              '  <div>\n'
              '    <span>Hello World</span>\n'
              '  </div>\n'
              '</div>\n')
          .toList();
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
  });
}
