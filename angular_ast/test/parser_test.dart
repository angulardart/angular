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
        TextAst('Hello World'),
      ],
    );
  });

  test('should parse a DOM element', () {
    expect(
      parse('<div></div  >'),
      [
        ElementAst('div', CloseElementAst('div')),
      ],
    );
  });

  test('should parse a comment', () {
    expect(
      parse('<!--Hello World-->'),
      [
        CommentAst('Hello World'),
      ],
    );
  });

  test('should parse multi-line comments', () {
    expect(parse('<!--Hello\nWorld-->'), [
      CommentAst('Hello\nWorld'),
    ]);

    expect(
      parse('<!--\nHello\nWorld\n-->'),
      [
        CommentAst('\nHello\nWorld\n'),
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
        ElementAst('div', CloseElementAst('div'), childNodes: [
          TextAst('\n  '),
          ElementAst('span', CloseElementAst('span'), childNodes: [
            TextAst('Hello World'),
          ]),
          TextAst('\n'),
        ]),
        TextAst('\n'),
      ],
    );
  });

  test('should parse an attribute without a value', () {
    expect(
      parse('<button disabled ></button>'),
      [
        ElementAst('button', CloseElementAst('button'), attributes: [
          AttributeAst('disabled'),
        ]),
      ],
    );
  });

  test('should parse an attribute with a value', () {
    expect(
      parse('<button title="Submit"></button>'),
      [
        ElementAst('button', CloseElementAst('button'), attributes: [
          AttributeAst('title', 'Submit', <InterpolationAst>[]),
        ]),
      ],
    );
  });

  test('should parse a property without a value', () {
    expect(
      parse('<button [value]></button>'),
      [
        ElementAst('button', CloseElementAst('button'), properties: [
          PropertyAst('value'),
        ]),
      ],
    );
  });

  test('should parse a reference', () {
    expect(
      parse('<button #btnRef></button>'),
      [
        ElementAst('button', CloseElementAst('button'), references: [
          ReferenceAst('btnRef'),
        ]),
      ],
    );
  });

  test('should parse a reference with an identifier', () {
    expect(
      parse('<mat-button #btnRef="mat-button"></mat-button>'),
      [
        ElementAst('mat-button', CloseElementAst('mat-button'), references: [
          ReferenceAst('btnRef', 'mat-button'),
        ]),
      ],
    );
  });

  test('should parse a container', () {
    expect(parse('<ng-container></ng-container>'), [ContainerAst()]);
  });

  test('should parse an embedded content directive', () {
    expect(
      parse('<ng-content></ng-content>'),
      [
        EmbeddedContentAst(),
      ],
    );
  });

  test('should parse an embedded content directive with a selector', () {
    expect(
      parse('<ng-content select="tab"></ng-content>'),
      [
        EmbeddedContentAst('tab'),
      ],
    );
  });

  test('should parse an embedded content directive with an ngProjectAs', () {
    expect(parse('<ng-content select="foo" ngProjectAs="bar"></ng-content>'),
        [EmbeddedContentAst('foo', 'bar')]);
  });

  test('should parse a <template> directive', () {
    expect(
      parse('<template></template>'),
      [
        EmbeddedTemplateAst(),
      ],
    );
  });

  test('should parse a <template> directive with attributes', () {
    expect(
      parse('<template ngFor let-item let-i="index"></template>'),
      [
        EmbeddedTemplateAst(attributes: [
          AttributeAst('ngFor'),
        ], letBindings: [
          LetBindingAst('item'),
          LetBindingAst('i', 'index'),
        ]),
      ],
    );
  });

  test('should parse a <template> directive with let-binding and hashref', () {
    expect(
      parse('<template let-foo="bar" let-baz #tempRef></template>'),
      [
        EmbeddedTemplateAst(references: [
          ReferenceAst('tempRef'),
        ], letBindings: [
          LetBindingAst('foo', 'bar'),
          LetBindingAst('baz'),
        ]),
      ],
    );
  });

  test('should parse a <template> directive with a reference', () {
    expect(
      parse('<template #named ></template>'),
      [
        EmbeddedTemplateAst(
          references: [
            ReferenceAst('named'),
          ],
        ),
      ],
    );
  });

  test('should parse a <template> directive with children', () {
    expect(
      parse('<template>Hello World</template>'),
      [
        EmbeddedTemplateAst(
          childNodes: [
            TextAst('Hello World'),
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

  test('should handle a microsyntax expression with leading whitespace', () {
    expect(
      parse('<div *ngFor="\n  let item of items">{{item}}</div>'),
      parse('<template ngFor let-item [ngForOf]="items">'
          '<div>{{item}}</div>'
          '</template>'),
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
        ElementAst('input', null),
        ElementAst('div', CloseElementAst('div')),
      ],
    );
  });

  test('should parse svg elements as void (explicit) or non void', () {
    expect(
      parse('<path /><path></path>'),
      [
        ElementAst('path', null),
        ElementAst('path', CloseElementAst('path')),
      ],
    );
  });

  test('should parse and desugar @deferred', () {
    expect(parse('<div @deferred></div>'), [
      EmbeddedTemplateAst(
          hasDeferredComponent: true,
          childNodes: [ElementAst('div', CloseElementAst('div'))])
    ]);
  });

  test('should parse multiple annotations and desugar @deferred', () {
    expect(parse('<div @foo="bar" @deferred></div>'), [
      EmbeddedTemplateAst(hasDeferredComponent: true, childNodes: [
        ElementAst('div', CloseElementAst('div'), annotations: [
          AnnotationAst('foo', 'bar'),
        ])
      ]),
    ]);
  });

  test('should parse an annotation with a value', () {
    expect(parse('<div @foo="bar"></div>'), [
      ElementAst('div', CloseElementAst('div'), annotations: [
        AnnotationAst('foo', 'bar'),
      ]),
    ]);
  });

  test('should parse an annotation on a container', () {
    expect(parse('<ng-container @annotation></ng-container>'), [
      ContainerAst(annotations: [
        AnnotationAst('annotation'),
      ])
    ]);
  });

  test('should parse an annotation on an embedded template', () {
    expect(parse('<template @annotation></template>'), [
      EmbeddedTemplateAst(annotations: [
        AnnotationAst('annotation'),
      ])
    ]);
  });

  test('should include annotation value in source span', () {
    final source = '@foo="bar"';
    final template = '<p $source></p>';
    final ast = parse(template).single as ElementAst;
    final annotation = ast.annotations.single;
    expect(annotation.sourceSpan.text, source);
  });

  test('should parse an annotation with a compound name', () {
    expect(parse('<div @foo.bar></div>'), [
      ElementAst('div', CloseElementAst('div'), annotations: [
        AnnotationAst('foo.bar'),
      ])
    ]);
  });
}
