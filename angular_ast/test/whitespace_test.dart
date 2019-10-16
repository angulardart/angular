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

  test('should retain manual &ngsp; inserts', () {
    expect(
      _parseAndMinifiy(r'<div>&ngsp;</div>'),
      '<div> </div>',
    );
  });

  test('should retain manual &#32; inserts', () {
    expect(
      _parseAndMinifiy(r'<div>&#32;</div>'),
      '<div> </div>',
    );
  }, skip: 'Not yet supported');

  test('should retain single whitespaces around tags', () {
    expect(
      _parseAndMinifiy('Foo <strong>Bar</strong> Baz'),
      'Foo <strong>Bar</strong> Baz',
    );
  });

  // https://github.com/dart-lang/angular/issues/804#issuecomment-363217553
  test('should retain whitespace for inline text formatting', () {
    expect(
      _parseAndMinifiy(r'''
        <div class="foo">
          html space
        </div>
        <br><br>
        <div class="foo">no space</div>
      '''),
      '<div class="foo">html space</div><br/><br/><div class="foo">no space</div>',
    );
  });

  test('should retain whitespace [regression test for Material]', () {
    expect(
      _parseAndMinifiy(r'''
      <section>
        <h2>Align with Text</h2>
        <div>
          Aligned with
          <material-input></material-input>
          text
        </div>
      </section>
      '''),
      ''
      '<section>'
      '<h2>Align with Text</h2>'
      '<div>Aligned with<material-input></material-input>text</div>'
      '</section>',
    );
  });

  test('should treat <ng-container> as a potential source of inline text', () {
    expect(_parseAndMinifiy(r'''
        Hello <ng-container>world!</ng-container>
      '''), 'Hello <ng-container>world!</ng-container>');
  });

  test('should treat <ng-content> as a potential source of inline text', () {
    expect(
      _parseAndMinifiy(r'''
        Hello <ng-content></ng-content>!
      '''),
      'Hello <ng-content select="*"></ng-content>!',
    );
  });

  test('should treat <template> as a potential source of inline text', () {
    expect(
      _parseAndMinifiy(r'''
        Hello <template></template>!
      '''),
      'Hello <template></template>!',
    );
  });

  test('should leave a space between potentially inline elements', () {
    expect(
      _parseAndMinifiy(r'<span>Hello</span> <span>World</span>!'),
      '<span>Hello</span> <span>World</span>!',
    );
  });

  test('should not leave a space between potentially block elements', () {
    expect(
      _parseAndMinifiy(r'<div>Hello</div> <div>World</div>!'),
      '<div>Hello</div><div>World</div>!',
    );
  });

  test('should collapse whitespace in a nested structure', () {
    expect(
      _parseAndMinifiy(r'''
        <div>
          <label>Last saved on</label>
          <div>
            {{someInterpolation}}
            <span> by {{anotherInterpolation}}</span>
          </div>
        </div>
      '''),
      '<div><label>Last saved on</label><div>{{someInterpolation}} <span>by {{anotherInterpolation}}</span></div></div>',
    );
  });

  test('should collapse whitespace in a nested structure with *ngIfs', () {
    expect(
      _parseAndMinifiy(r'''
        <div *ngIf="someCondition">
          <label>Last saved on</label>
          <div *ngIf="anotherCondition">
            {{someInterpolation}}
            <span *ngIf="yetAnotherCondition"> by {{anotherInterpolation}}</span>
          </div>
        </div>
      '''),
      ''
      '<template [ngIf]="someCondition">'
      '<div><label>Last saved on</label>'
      '<template [ngIf]="anotherCondition"><div>{{someInterpolation}} '
      '<template [ngIf]="yetAnotherCondition">'
      '<span>by {{anotherInterpolation}}</span>'
      '</template></div></template></div></template>',
    );
  });

  test('should collapse whitespace with <ng-container> wrapping a div', () {
    expect(
      _parseAndMinifiy(r'''
        <label>Foo</label>
        <ng-container *ngIf="someCondition">
          <div>{{someInterpolation}}</div>
        </ng-container>
      '''),
      ''
      '<label>Foo</label><template [ngIf]="someCondition"><ng-container>'
      '<div>{{someInterpolation}}</div>'
      '</ng-container></template>',
    );
  });

  test('should preserve whitespace with a leading <span>', () {
    expect(
      _parseAndMinifiy(r'''
        <div>
          Pre-Block
          <template [ngIf]="someCondition">
            <div>Block</div>
            <span>Inline</span>
          </template>
          Post-Inline
        </div>
      '''),
      ''
      // NOTE: There is no space here, because the next element is a <div>
      '<div>Pre-Block'
      '<template [ngIf]="someCondition"><div>Block</div>'
      '<span>Inline</span></template>'
      // NOTE: There *is* a space here, previous element is a <span>
      ' Post-Inline'
      '</div>',
    );
  });

  test('should assume that empty templates are sources of inline text', () {
    expect(
      _parseAndMinifiy(r'''
        <template [ngIf]="someCondition">
          <div>
            Hello,
            <template>
            </template>
          </div>
        </template>
      '''),
      ''
      '<template [ngIf]="someCondition">'
      '<div>Hello, <template></template></div>'
      '</template>',
    );
  });

  test('preserve &nbsp; (do not collapse, replace with plain space)', () {
    expect(
      _parseAndMinifiy(r'''
        <div>
          &nbsp;
        </div>
      '''),
      // The browser will render as a space, but it isn't a ' ' character.
      '<div>${'\u00A0'}</div>',
    );
  });

  test('should skip nodes/trees annotated with @preserveWhitespace', () {
    expect(
      _parseAndMinifiy(
        r'<div @preserveWhitespace>   <span>  </span></div>',
      ),
      '<div @preserveWhitespace>   <span>  </span></div>',
    );
    expect(
      _parseAndMinifiy(
        r'<ng-container @preserveWhitespace>   </ng-container>',
      ),
      '<ng-container @preserveWhitespace>   </ng-container>',
    );
    expect(
      _parseAndMinifiy(
        r'<template @preserveWhitespace><div>  </div></template>',
      ),
      '<template @preserveWhitespace><div>  </div></template>',
    );
  });

  test('should retain whitespace inside preformatted text', () {
    expect(
      _parseAndMinifiy('''
        <pre>
          Hello
          world
        </pre>
      '''),
      '''<pre>
          Hello
          world
        </pre>''',
    );
  });
}

String _parseAndMinifiy(String template) {
  final nodes = parse(template, sourceUrl: 'whitespace_test.dart');
  final buffer = StringBuffer();
  for (final node in _minimizing.visitAllRoot(nodes)) {
    buffer.write(_humanize(node));
  }
  return buffer.toString();
}

final _minimizing = const MinimizeWhitespaceVisitor();
final _humanizing = const HumanizingTemplateAstVisitor();
String _humanize(TemplateAst astNode) => astNode.accept(_humanizing);
