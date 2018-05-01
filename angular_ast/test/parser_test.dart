// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:angular_ast/angular_ast.dart';
import 'package:test/test.dart';

void main() {
  List<StandaloneTemplateAst> parse(String template) {
    return const NgParser().parse(
      template,
      sourceUrl: '/test/parser_test.dart#inline',
    );
  }

  test('should parse empty string', () {
    expect(parse(''), []);
  });

  test('should parse a text node', () {
    expect(
      parse('Hello World'),
      [
        new TextAst('Hello World'),
      ],
    );
  });

  test('should parse a DOM element', () {
    expect(
      parse('<div></div  >'),
      [
        new ElementAst('div', new CloseElementAst('div')),
      ],
    );
  });

  test('should parse a comment', () {
    expect(
      parse('<!--Hello World-->'),
      [
        new CommentAst('Hello World'),
      ],
    );
  });

  test('should parse multi-line comments', () {
    expect(parse('<!--Hello\nWorld-->'), [
      new CommentAst('Hello\nWorld'),
    ]);

    expect(
      parse('<!--\nHello\nWorld\n-->'),
      [
        new CommentAst('\nHello\nWorld\n'),
      ],
    );
  });

  test('shoud parse a nested DOM structure', () {
    expect(
      parse(''
          '<div>\n'
          '  <span>Hello World</span>\n'
          '</div>\n'),
      [
        new ElementAst('div', new CloseElementAst('div'), childNodes: [
          new TextAst('\n  '),
          new ElementAst('span', new CloseElementAst('span'), childNodes: [
            new TextAst('Hello World'),
          ]),
          new TextAst('\n'),
        ]),
        new TextAst('\n'),
      ],
    );
  });

  test('should parse an attribute without a value', () {
    expect(
      parse('<button disabled ></button>'),
      [
        new ElementAst('button', new CloseElementAst('button'), attributes: [
          new AttributeAst('disabled'),
        ]),
      ],
    );
  });

  test('should parse an attribute with a value', () {
    expect(
      parse('<button title="Submit"></button>'),
      [
        new ElementAst('button', new CloseElementAst('button'), attributes: [
          new AttributeAst('title', 'Submit', <InterpolationAst>[]),
        ]),
      ],
    );
  });

  test('should parse a property without a value', () {
    expect(
      parse('<button [value]></button>'),
      [
        new ElementAst('button', new CloseElementAst('button'), properties: [
          new PropertyAst('value'),
        ]),
      ],
    );
  });

  test('should parse a reference', () {
    expect(
      parse('<button #btnRef></button>'),
      [
        new ElementAst('button', new CloseElementAst('button'), references: [
          new ReferenceAst('btnRef'),
        ]),
      ],
    );
  });

  test('should parse a reference with an identifier', () {
    expect(
      parse('<mat-button #btnRef="mat-button"></mat-button>'),
      [
        new ElementAst('mat-button', new CloseElementAst('mat-button'),
            references: [
              new ReferenceAst('btnRef', 'mat-button'),
            ]),
      ],
    );
  });

  test('should parse a container', () {
    expect(parse('<ng-container></ng-container>'), [new ContainerAst()]);
  });

  test('should parse an embedded content directive', () {
    expect(
      parse('<ng-content></ng-content>'),
      [
        new EmbeddedContentAst(),
      ],
    );
  });

  test('should parse an embedded content directive with a selector', () {
    expect(
      parse('<ng-content select="tab"></ng-content>'),
      [
        new EmbeddedContentAst('tab'),
      ],
    );
  });

  test('should parse an embedded content directive with an ngProjectAs', () {
    expect(parse('<ng-content select="foo" ngProjectAs="bar"></ng-content>'),
        [new EmbeddedContentAst('foo', 'bar')]);
  });

  test('should parse a <template> directive', () {
    expect(
      parse('<template></template>'),
      [
        new EmbeddedTemplateAst(),
      ],
    );
  });

  test('should parse a <template> directive with attributes', () {
    expect(
      parse('<template ngFor let-item let-i="index"></template>'),
      [
        new EmbeddedTemplateAst(attributes: [
          new AttributeAst('ngFor'),
        ], letBindings: [
          new LetBindingAst('item'),
          new LetBindingAst('i', 'index'),
        ]),
      ],
    );
  });

  test('should parse a <template> directive with let-binding and hashref', () {
    expect(
      parse('<template let-foo="bar" let-baz #tempRef></template>'),
      [
        new EmbeddedTemplateAst(references: [
          new ReferenceAst('tempRef'),
        ], letBindings: [
          new LetBindingAst('foo', 'bar'),
          new LetBindingAst('baz'),
        ]),
      ],
    );
  });

  test('should parse a <template> directive with a reference', () {
    expect(
      parse('<template #named ></template>'),
      [
        new EmbeddedTemplateAst(
          references: [
            new ReferenceAst('named'),
          ],
        ),
      ],
    );
  });

  test('should parse a <template> directive with children', () {
    expect(
      parse('<template>Hello World</template>'),
      [
        new EmbeddedTemplateAst(
          childNodes: [
            new TextAst('Hello World'),
          ],
        ),
      ],
    );
  });

  test('should parse a structural directive with the * sugar syntax', () {
    expect(
      parse('<div *ngIf="someValue">Hello World</div>'),
      parse('<template [ngIf]="someValue"><div>Hello World</div></template>'),
    );
  });

  test('should parse a structural directive in child position', () {
    expect(
      parse('<div><div *ngIf="someValue">Hello World</div></div>'),
      parse(
          '<div><template [ngIf]="someValue"><div>Hello World</div></template></div>'),
    );
  });

  test('should parse a structural directive on a container', () {
    expect(
        parse('<ng-container *ngIf="someValue">Hello world</ng-container>'),
        parse('<template [ngIf]="someValue">'
            '<ng-container>Hello world</ng-container>'
            '</template>'));
  });

  test('should parse a void element (implicit)', () {
    expect(
      parse('<input><div></div>'),
      [
        new ElementAst('input', null),
        new ElementAst('div', new CloseElementAst('div')),
      ],
    );
  });

  test('should parse svg elements as void (explicit) or non void', () {
    expect(
      parse('<path /><path></path>'),
      [
        new ElementAst('path', null),
        new ElementAst('path', new CloseElementAst('path')),
      ],
    );
  });

  test('should parse and desugar @deferred', () {
    expect(parse('<div @deferred></div>'), [
      new EmbeddedTemplateAst(
          hasDeferredComponent: true,
          childNodes: [new ElementAst('div', new CloseElementAst('div'))])
    ]);
  });

  test('should parse multiple annotations and desugar @deferred', () {
    expect(parse('<div @foo="bar" @deferred></div>'), [
      new EmbeddedTemplateAst(hasDeferredComponent: true, childNodes: [
        new ElementAst('div', new CloseElementAst('div'), annotations: [
          new AnnotationAst('foo', 'bar'),
        ])
      ]),
    ]);
  });

  test('should parse an annotation with a value', () {
    expect(parse('<div @foo="bar"></div>'), [
      new ElementAst('div', new CloseElementAst('div'), annotations: [
        new AnnotationAst('foo', 'bar'),
      ]),
    ]);
  });

  test('should parse an annotation on a container', () {
    expect(parse('<ng-container @annotation></ng-container>'), [
      new ContainerAst(annotations: [
        new AnnotationAst('annotation'),
      ])
    ]);
  });
}
