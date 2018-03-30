import 'package:angular_ast/angular_ast.dart';
import 'package:test/test.dart';

void main() {
  group('whitespace-only nodes', () {
    test('non-adjacent to interpolations should be removed', () {
      expect(
        _parseAndMinifiy(
          ''
              '<div>\n'
              '  <span>Hello World</span>\n'
              '</div>\n',
        ),
        '<div><span>Hello World</span></div>',
      );
    });

    test('adjacent to interpolations should be retained', () {
      expect(
        _parseAndMinifiy(
          ''
              '<div>\n'
              '  <span>Hello {{name}}!</span>\n'
              '</div>\n',
        ),
        '<div><span>Hello {{name}}!</span></div>',
      );
    });
  });

  // TODO: Add tests/support for &ngsp; and friends.

  test('should remove inside interpolation on the LHS', () {
    expect(
      _parseAndMinifiy('\n    \n    {{value1}}'),
      '{{value1}}',
    );
  });

  test('should remove inside interpolation on the LHS and RHS', () {
    expect(
      _parseAndMinifiy('\n    \n    {{value1}}  {{value2}}  \n      '),
      '{{value1}} {{value2}}',
    );
  });

  test('should not remove between text, interpolation', () {
    expect(
      _parseAndMinifiy('<span> prefix {{value1}} postfix </span>\n      '),
      '<span>prefix {{value1}} postfix</span>',
    );
  });

  test('should not remove between text, interpolation across lines', () {
    expect(
      _parseAndMinifiy('<span>\n prefix {{value1}} postfix \n</span>\n      '),
      '<span>prefix {{value1}} postfix</span>',
    );
  });

  test('should remove all whitespace in <template> tags', () {
    expect(
      _parseAndMinifiy(r'''
        <another></another>
        <template>
          <another></another>
        </template>
      '''),
      '<another></another><template><another></another></template>',
    );
  });

  test('should remove only whitespace before/after interpolations', () {
    expect(
      _parseAndMinifiy(r'''
        <div>
          {{foo}}
        </div>
      '''),
      '<div>{{foo}}</div>',
    );
  });
}

String _parseAndMinifiy(String template) {
  final nodes = parse(template, sourceUrl: 'whitespace_test.dart');
  final buffer = new StringBuffer();
  for (final node in _minimizing.visitAllRoot(nodes)) {
    buffer.write(_humanize(node));
  }
  return buffer.toString();
}

final _minimizing = const MinimizeWhitespaceVisitor();
final _humanizing = const HumanizingTemplateAstVisitor();
String _humanize(TemplateAst astNode) => astNode.accept(_humanizing);
