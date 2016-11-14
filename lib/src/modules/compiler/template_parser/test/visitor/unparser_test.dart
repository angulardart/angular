import 'package:angular2_template_parser/template_parser.dart';
import 'package:test/test.dart';
import 'package:angular2_template_parser/src/visitor.dart';

void main() {
  NgAstNode parse(String text) =>
      const NgTemplateParser().parse(text, onError: (_) => null).first;

  test('produces a desugared template', () {
    var ast = parse('<panel><div *ngIf="isTrue">Foo Bar</div><button '
      'class="fancy" disabled>Hello</button></panel>');
    var printer = new Unparser();
    ast.visit(printer);
    expect(printer.toString(), equals(
      '<panel>\n'
      '  <template [ngIf]="isTrue">\n'
      '    <div>\n'
      '      Foo Bar\n'
      '    </div>\n'
      '  </template>\n'
      '  <button class="fancy" disabled>\n'
      '    Hello\n'
      '  </button>\n'
      '</panel>\n'
    ));
  });

  test('can be used on renamed templates', () {
    var ast = parse('<div class="baz"><ng-app [prop]="foo">Test</ng-app></div>');
    NgAstNode renamer(NgAstNode node) {
      if (node is NgElement) {
        return new NgElement.unknown('${node.name}-test',
          childNodes: node.childNodes
            .map((x) => x.map(renamer)).toList());
      }
      return node;
    }
    var newAst = ast.map(renamer);
    var printer = new Unparser();
    newAst.visit(printer);
    expect(printer.toString(), equals(
      '<div-test class="baz">\n'
      '  <ng-app-test [prop]="foo">\n'
      '    Test\n'
      '  </ng-app-test>\n'
      '</div-test>\n'
    ));
  });
}
