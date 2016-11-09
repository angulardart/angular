import 'package:angular2_template_parser/src/ast.dart';
import 'package:angular2_template_parser/src/parser.dart';
import 'package:test/test.dart';

void main() {
  List<NgAstNode> parse(String text) =>
      const NgTemplateParser().parse(text, onError: (_) => null).toList();

  // Example migration program - add test to all NgAstNames, remove comments.
  NgAstNode migrate(NgAstNode node) {
    if (node is NgElement) {
      return new NgElement.unknown('${node.name}-test',
          childNodes: node.childNodes
              .map((x) => x.map(migrate))
              .where((x) => x != null)
              .toList());
    }
    if (node is NgComment) {
      return null;
    }
    return node;
  }

  test('can perform simple migrations on AST trees', () {
    final source = '<div [foo]="baz"><app *ngIf="isLoaded">'
        '<!-- App Loaded Below--></app></div>';
    final oldAst = parse(source);
    final newAst = oldAst.map((x) => x.map(migrate));
    expect(newAst, [
      new NgElement.unknown('div-test', childNodes: [
        new NgProperty('foo', 'baz'),
        new NgElement.unknown('template-test', childNodes: [
          new NgProperty('ngIf', 'isLoaded'),
          new NgElement.unknown('app-test', childNodes: [])
        ])
      ])
    ]);
  });
}
