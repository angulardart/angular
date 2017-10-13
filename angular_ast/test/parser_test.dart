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

  List<StandaloneTemplateAst> parsePreserve(String template) {
    return const NgParser().parse(
      template,
      sourceUrl: '/test/parser_test.dart#inline',
      desugar: false,
      parseExpressions: false,
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

  test('should parse an interpolation', () {
    expect(
      parse('{{ name }}'),
      [
        new InterpolationAst(
            ' name ',
            new ExpressionAst.parse(
              'name',
              3,
              sourceUrl: '/test/expression/parser_test.dart#inline',
            )),
      ],
    );
  });

  test('should parse all the standalone ASTs', () {
    expect(
      parse('Hello<div></div><!--Goodbye-->{{name}}'),
      [
        new TextAst('Hello'),
        new ElementAst('div', new CloseElementAst('div')),
        new CommentAst('Goodbye'),
        new InterpolationAst(
            'name',
            new ExpressionAst.parse(
              'name',
              32,
              sourceUrl: '/test/expression/parser_test.dart#inline',
            )),
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

  test('should parse and attribute with a value including interpolation', () {
    expect(
      parse('<div title="Hello {{myName}}"></div>'),
      [
        new ElementAst('div', new CloseElementAst('div'), attributes: [
          new AttributeAst('title', 'Hello {{myName}}', <InterpolationAst>[
            new InterpolationAst(
                'myName',
                new ExpressionAst.parse(
                  'myName',
                  20,
                  sourceUrl: '/test/expression/parser_test.dart#inline',
                )),
          ]),
        ]),
      ],
    );
  });

  test('should parse an event', () {
    expect(
      parse('<button (click) = "onClick()"  ></button>'),
      [
        new ElementAst('button', new CloseElementAst('button'), events: [
          new EventAst(
              'click',
              'onClick()',
              new ExpressionAst.parse(
                'onClick()',
                19,
                sourceUrl: '/test/expression/parser_test.dart#inline',
              ),
              []),
        ]),
      ],
    );
  });

  test("should parse an event starting with 'on-'", () {
    expect(
      parse('<button on-click = "onClick()" ></button>'),
      [
        new ElementAst('button', new CloseElementAst('button'), events: [
          new EventAst(
              'click',
              'onClick()',
              new ExpressionAst.parse(
                'onClick()',
                20,
                sourceUrl: '/test/expression/parser_test.dart#inline',
              )),
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

  test('should parse a property with a value', () {
    expect(
      parse('<button [value]="btnValue"></button>'),
      [
        new ElementAst('button', new CloseElementAst('button'), properties: [
          new PropertyAst(
              'value',
              'btnValue',
              new ExpressionAst.parse(
                'btnValue',
                17,
                sourceUrl: '/test/expression/parser_test.dart#inline',
              )),
        ]),
      ],
    );
  });

  test("should parse an event starting with 'bind-'", () {
    expect(parse('<button bind-value="btnValue"></button>'), [
      new ElementAst('button', new CloseElementAst('button'), properties: [
        new PropertyAst(
          'value',
          'btnValue',
          new ExpressionAst.parse(
            'btnValue',
            20,
            sourceUrl: '/test/expression/parser_test.dart#inline',
          ),
        ),
      ]),
    ]);
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

  test('should parse a <template> directive with events', () {
    expect(
      parse(
          '<template step name="Name & Description" (jumpHere)="lastStep(false)"></template>'),
      [
        new EmbeddedTemplateAst(attributes: [
          new AttributeAst('step'),
          new AttributeAst('name', 'Name & Description', <InterpolationAst>[]),
        ], events: [
          new EventAst(
            'jumpHere',
            'lastStep(false)',
            new ExpressionAst.parse(
              'lastStep(false)',
              53,
              sourceUrl: '/test/expression/parser_test.dart#inline',
            ),
          ),
        ]),
      ],
    );
  });

  test('should parse a <template> directive with a property', () {
    expect(
      parse('<template [ngIf]="someValue"></template>'),
      [
        new EmbeddedTemplateAst(
          properties: [
            new PropertyAst(
                'ngIf',
                'someValue',
                new ExpressionAst.parse(
                  'someValue',
                  18,
                  sourceUrl: '/test/expression/parser_test.dart#inline',
                )),
          ],
        ),
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

  test('should parse a void element (implicit)', () {
    expect(
      parse('<input><div></div>'),
      [
        new ElementAst('input', null),
        new ElementAst('div', new CloseElementAst('div')),
      ],
    );
  });

  test('should parse a banana syntax', () {
    expect(
      parse('<custom [(name)] ="myName"></custom>'),
      [
        new ElementAst(
          'custom',
          new CloseElementAst('custom'),
          events: [
            new EventAst(
                'nameChange',
                'myName = \$event',
                new ExpressionAst.parse(
                  'myName = \$event',
                  19,
                  sourceUrl: '/test/expression/parser_test.dart#inline',
                )),
          ],
          properties: [
            new PropertyAst(
                'name',
                'myName',
                new ExpressionAst.parse(
                  'myName',
                  19,
                  sourceUrl: '/test/expression/parser_test.dart#inline',
                )),
          ],
        )
      ],
    );
  });

  test('should parse an *ngFor multi-expression', () {
    expect(
      parse('<a *ngFor="let item of items; trackBy: byId; let i = index"></a>'),
      [
        new EmbeddedTemplateAst(
          attributes: [
            new AttributeAst('ngFor'),
          ],
          childNodes: [
            new ElementAst('a', new CloseElementAst('a')),
          ],
          properties: [
            new PropertyAst(
              'ngForOf',
              'items',
              new ExpressionAst.parse(
                'items',
                23,
                sourceUrl: '/test/expression/parser_test.dart#inline',
              ),
            ),
            new PropertyAst(
              'ngForTrackBy',
              'byId',
              new ExpressionAst.parse(
                'byId',
                39,
                sourceUrl: '/test/expression/parser_test.dart#inline',
              ),
            ),
          ],
          letBindings: [
            new LetBindingAst('item'),
            new LetBindingAst('i', 'index'),
          ],
        )
      ],
    );
  });

  test('should parse and preserve strict offset within elements', () {
    var templateString = '''
<tab-button *ngFor="let tabLabel of tabLabels; let idx = index"  (trigger)="switchTo(idx)" [id]="tabId(idx)" class="tab-button"  ></tab-button>''';
    var asts = parsePreserve(
      templateString,
    );
    var element = asts[0] as ParsedElementAst;
    expect(element.beginToken.offset, 0);

    expect(element.stars[0].beginToken.offset, 12);
    expect((element.stars[0] as ParsedStarAst).prefixOffset, 12);

    expect(element.events[0].beginToken.offset, 65);
    expect((element.events[0] as ParsedEventAst).prefixOffset, 65);

    expect(element.properties[0].beginToken.offset, 91);
    expect((element.properties[0] as ParsedPropertyAst).prefixOffset, 91);

    expect(element.attributes[0].beginToken.offset, 109);
    expect((element.attributes[0] as ParsedAttributeAst).nameOffset, 109);

    expect(element.endToken.offset, 129);
    expect(element.closeComplement.beginToken.offset, 130);
    expect(element.closeComplement.endToken.offset, 142);
  });

  test('should parse and preserve strict offsets within interpolations', () {
    var templateString = '''
<div>{{ 1 + 2 + 3 + 4 }}</div>''';
    var asts = parse(templateString);
    var element = asts[0] as ElementAst;
    var interpolation = element.childNodes[0] as InterpolationAst;

    expect(interpolation.beginToken.offset, 5);
    expect(interpolation.value.length, 15);
    expect(interpolation.endToken.offset, 22);
    expect(interpolation.expression, isNotNull);
  });

  test('should parse expressions in attr-value interpolations', () {
    var templateString = '''
<div someAttr="{{ 1 + 2 }} nonmustache {{ 3 + 4 }}"></div>''';
    var asts = parse(templateString);
    var element = asts[0] as ElementAst;

    expect(element.attributes.length, 1);
    var attr = element.attributes[0] as ParsedAttributeAst;
    expect(attr, new isInstanceOf<ParsedAttributeAst>());
    expect(attr.value, '{{ 1 + 2 }} nonmustache {{ 3 + 4 }}');

    expect(attr.mustaches.length, 2);
    var mustache1 = attr.mustaches[0] as ParsedInterpolationAst;
    var mustache2 = attr.mustaches[1] as ParsedInterpolationAst;
    expect(mustache1.beginToken.offset, templateString.indexOf('{{ 1 + 2 }}'));
    expect(mustache1.beginToken.lexeme, '{{');
    expect(mustache1.beginToken.errorSynthetic, false);
    expect(mustache1.valueToken.offset, templateString.indexOf(' 1 + 2 '));
    expect(mustache1.valueToken.lexeme, ' 1 + 2 ');
    expect(mustache1.endToken.offset, 24);
    expect(mustache1.endToken.lexeme, '}}');
    expect(mustache1.endToken.errorSynthetic, false);
    expect(mustache1.expression.expression.toString(), '1 + 2');

    expect(mustache2.beginToken.offset, templateString.indexOf('{{ 3 + 4 }}'));
    expect(mustache2.beginToken.lexeme, '{{');
    expect(mustache2.beginToken.errorSynthetic, false);
    expect(mustache2.valueToken.offset, templateString.indexOf(' 3 + 4 '));
    expect(mustache2.valueToken.lexeme, ' 3 + 4 ');
    expect(mustache2.endToken.offset, 48);
    expect(mustache2.endToken.lexeme, '}}');
    expect(mustache2.endToken.errorSynthetic, false);
    expect(mustache2.expression.expression.toString(), '3 + 4');
  });

  // Moved from expression/micro/parser_test.dart
  test(
      'should parse, desugar, and expression-parse *ngFor with full dart expression',
      () {
    var templateString = '''
<div *ngFor="let x of items.where(filter)"></div>''';
    expect(parse(templateString), [
      new EmbeddedTemplateAst(
        attributes: [
          new AttributeAst('ngFor'),
        ],
        childNodes: [
          new ElementAst('div', new CloseElementAst('div')),
        ],
        properties: [
          new PropertyAst(
            'ngForOf',
            'items.where(filter)',
            new ExpressionAst.parse(
              'items.where(filter)',
              13,
              sourceUrl: '/test/expression/micro/parser_test.dart#inline',
            ),
          ),
        ],
        letBindings: [
          new LetBindingAst('x'),
        ],
      )
    ]);
  });
}
