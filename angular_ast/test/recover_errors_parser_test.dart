// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test/test.dart';
import 'package:angular_ast/angular_ast.dart';

RecoveringExceptionHandler recoveringExceptionHandler =
    RecoveringExceptionHandler();

List<StandaloneTemplateAst> parse(
  String template, {
  desugar = false,
  bool parseExpression = false,
}) {
  recoveringExceptionHandler.exceptions.clear();
  return const NgParser().parse(
    template,
    sourceUrl: '/test/recover_error_parser_test.dart#inline',
    exceptionHandler: recoveringExceptionHandler,
    desugar: desugar,
    parseExpressions: parseExpression,
  );
}

String astsToString(List<StandaloneTemplateAst> asts) {
  var visitor = const HumanizingTemplateAstVisitor();
  return asts.map((t) => t.accept(visitor)).join('');
}

void checkException(ErrorCode errorCode, int offset, int length) {
  expect(recoveringExceptionHandler.exceptions.length, 1);
  var e = recoveringExceptionHandler.exceptions[0];
  expect(e.errorCode, errorCode);
  expect(e.offset, offset);
  expect(e.length, length);
}

void main() {
  test('Should close unclosed element tag', () {
    var asts = parse('<div>');
    expect(asts.length, 1);

    var element = asts[0] as ElementAst;
    expect(element, ElementAst('div', CloseElementAst('div')));
    expect(element.closeComplement, CloseElementAst('div'));
    expect(element.isSynthetic, false);
    expect(element.closeComplement.isSynthetic, true);
    expect(astsToString(asts), '<div></div>');

    checkException(NgParserWarningCode.CANNOT_FIND_MATCHING_CLOSE, 0, 5);
  });

  test('Should add open element tag to dangling close tag', () {
    var asts = parse('</div>');
    expect(asts.length, 1);

    var element = asts[0] as ElementAst;
    expect(element, ElementAst('div', CloseElementAst('div')));
    expect(element.closeComplement, CloseElementAst('div'));
    expect(element.isSynthetic, true);
    expect(element.closeComplement.isSynthetic, false);
    expect(astsToString(asts), '<div></div>');

    checkException(NgParserWarningCode.DANGLING_CLOSE_ELEMENT, 0, 6);
  });

  test('Should not close a void tag', () {
    var asts = parse('<hr/>');
    expect(asts.length, 1);

    var element = asts[0] as ElementAst;
    expect(element, ElementAst('hr', null));
    expect(element.closeComplement, null);
  });

  test('Should add close tag to dangling open within nested', () {
    var asts = parse('<div><div><div>text1</div>text2</div>');
    expect(asts.length, 1);

    var element = asts[0] as ElementAst;
    expect(element.childNodes.length, 1);
    expect(element.childNodes[0].childNodes.length, 2);
    expect(element.closeComplement.isSynthetic, true);
    expect(astsToString(asts), '<div><div><div>text1</div>text2</div></div>');

    checkException(NgParserWarningCode.CANNOT_FIND_MATCHING_CLOSE, 0, 5);
  });

  test('Should add synthetic open to dangling close within nested', () {
    var asts = parse('<div><div></div>text1</div>text2</div>');
    expect(asts.length, 3);

    var element = asts[2] as ElementAst;
    expect(element.isSynthetic, true);
    expect(element.closeComplement.isSynthetic, false);

    var exceptions = recoveringExceptionHandler.exceptions;
    expect(exceptions.length, 1);
    var e = exceptions[0];
    expect(e.errorCode, NgParserWarningCode.DANGLING_CLOSE_ELEMENT);
    expect(e.offset, 32);
    expect(e.length, 6);
  });

  test('Should resolve complicated nested danglings', () {
    var asts = parse('<a><b></c></a></b>');
    expect(asts.length, 2);

    var elementA = asts[0];
    expect(elementA.childNodes.length, 1);
    expect(elementA.isSynthetic, false);
    expect((elementA as ElementAst).closeComplement.isSynthetic, false);

    var elementInnerB = elementA.childNodes[0];
    expect(elementInnerB.childNodes.length, 1);
    expect(elementInnerB.isSynthetic, false);
    expect((elementInnerB as ElementAst).closeComplement.isSynthetic, true);

    var elementC = elementInnerB.childNodes[0];
    expect(elementC.childNodes.length, 0);
    expect(elementC.isSynthetic, true);
    expect((elementC as ElementAst).closeComplement.isSynthetic, false);

    var elementOuterB = asts[1];
    expect(elementOuterB.childNodes.length, 0);
    expect(elementOuterB.isSynthetic, true);
    expect((elementOuterB as ElementAst).closeComplement.isSynthetic, false);

    expect(astsToString(asts), '<a><b><c></c></b></a><b></b>');

    var exceptions = recoveringExceptionHandler.exceptions;
    expect(exceptions.length, 3);

    // Dangling '</c>'
    var e1 = exceptions[0];
    expect(e1.errorCode, NgParserWarningCode.DANGLING_CLOSE_ELEMENT);
    expect(e1.offset, 6);
    expect(e1.length, 4);

    // Unmatching '</a>'; error at <b>
    var e2 = exceptions[1];
    expect(e2.errorCode, NgParserWarningCode.CANNOT_FIND_MATCHING_CLOSE);
    expect(e2.offset, 3);
    expect(e2.length, 3);

    // Dangling '</b>'
    var e3 = exceptions[2];
    expect(e3.errorCode, NgParserWarningCode.DANGLING_CLOSE_ELEMENT);
    expect(e3.offset, 14);
    expect(e3.length, 4);
  });

  test('Should resolve dangling open ng-container', () {
    final asts = parse('<div><ng-container></div>');
    expect(asts, hasLength(1));

    final div = asts[0];
    expect(div.childNodes, hasLength(1));

    final ngContainer = div.childNodes[0];
    expect(ngContainer, const TypeMatcher<ContainerAst>());
    expect(ngContainer.isSynthetic, false);
    expect((ngContainer as ContainerAst).closeComplement.isSynthetic, true);
    expect(astsToString(asts), '<div><ng-container></ng-container></div>');

    checkException(NgParserWarningCode.CANNOT_FIND_MATCHING_CLOSE, 5, 14);
  });

  test('Should resolve dangling close ng-container', () {
    final asts = parse('<div></ng-container></div>');
    expect(asts, hasLength(1));

    final div = asts[0];
    expect(div.childNodes, hasLength(1));

    final ngContainer = div.childNodes[0];
    expect(ngContainer, const TypeMatcher<ContainerAst>());
    expect(ngContainer.isSynthetic, true);
    expect((ngContainer as ContainerAst).closeComplement.isSynthetic, false);
    expect(astsToString(asts), '<div><ng-container></ng-container></div>');

    checkException(NgParserWarningCode.DANGLING_CLOSE_ELEMENT, 5, 15);
  });

  test('Should handle ng-container used with void end', () {
    final asts = parse('<ng-container/></ng-container>');
    expect(asts, hasLength(1));

    final ngContainer = asts[0];
    expect(ngContainer, const TypeMatcher<ContainerAst>());
    expect(astsToString(asts), '<ng-container></ng-container>');

    checkException(NgParserWarningCode.NONVOID_ELEMENT_USING_VOID_END, 13, 2);
  });

  test('Should drop invalid decorators on ng-container', () {
    final asts = parse('<ng-container '
        '*star="expr" '
        'attr="value" '
        '[prop]="expr" '
        '(event)="expr" '
        'let-var="expr" '
        '#ref '
        '@annotation>'
        '</ng-container>');
    expect(asts, hasLength(1));

    final ngContainer = asts[0];
    expect(ngContainer, const TypeMatcher<ContainerAst>());
    expect(astsToString(asts),
        '<ng-container @annotation *star="expr"></ng-container>');

    final exceptions = recoveringExceptionHandler.exceptions;
    expect(exceptions, hasLength(5));

    final attrException = exceptions[0];
    expect(attrException.errorCode,
        NgParserWarningCode.INVALID_DECORATOR_IN_NGCONTAINER);
    expect(attrException.offset, 27);
    expect(attrException.length, 12);

    final propException = exceptions[1];
    expect(propException.errorCode,
        NgParserWarningCode.INVALID_DECORATOR_IN_NGCONTAINER);
    expect(propException.offset, 40);
    expect(propException.length, 13);

    final eventException = exceptions[2];
    expect(eventException.errorCode,
        NgParserWarningCode.INVALID_DECORATOR_IN_NGCONTAINER);
    expect(eventException.offset, 54);
    expect(eventException.length, 14);

    final letException = exceptions[3];
    expect(letException.errorCode,
        NgParserWarningCode.INVALID_DECORATOR_IN_NGCONTAINER);
    expect(letException.offset, 69);
    expect(letException.length, 14);

    final refException = exceptions[4];
    expect(refException.errorCode,
        NgParserWarningCode.INVALID_DECORATOR_IN_NGCONTAINER);
    expect(refException.offset, 84);
    expect(refException.length, 4);
  });

  test('Should resolve dangling open ng-content', () {
    var asts = parse('<div><ng-content></div>');
    expect(asts.length, 1);

    var div = asts[0];
    expect(div.childNodes.length, 1);

    var ngContent = div.childNodes[0];
    expect(ngContent, TypeMatcher<EmbeddedContentAst>());
    expect(ngContent.isSynthetic, false);
    expect((ngContent as EmbeddedContentAst).closeComplement.isSynthetic, true);

    expect(
        astsToString(asts), '<div><ng-content select="*"></ng-content></div>');

    checkException(NgParserWarningCode.NGCONTENT_MUST_CLOSE_IMMEDIATELY, 5, 12);
  });

  test('Should resolve dangling close ng-content', () {
    var asts = parse('<div></ng-content></div>');
    expect(asts.length, 1);

    var div = asts[0];
    expect(div.childNodes.length, 1);

    var ngContent = div.childNodes[0];
    expect(ngContent, TypeMatcher<EmbeddedContentAst>());
    expect(ngContent.isSynthetic, true);
    expect(
        (ngContent as EmbeddedContentAst).closeComplement.isSynthetic, false);
    expect(
        astsToString(asts), '<div><ng-content select="*"></ng-content></div>');

    checkException(NgParserWarningCode.DANGLING_CLOSE_ELEMENT, 5, 13);
  });

  test('Should resolve ng-content with children', () {
    var asts = parse('<ng-content><div></div></ng-content>');
    expect(asts.length, 3);

    var ngcontent1 = asts[0];
    var div = asts[1];
    var ngcontent2 = asts[2];

    expect(ngcontent1.childNodes.length, 0);
    expect(div.childNodes.length, 0);
    expect(ngcontent2.childNodes.length, 0);

    expect(ngcontent1, TypeMatcher<EmbeddedContentAst>());
    expect(div, TypeMatcher<ElementAst>());
    expect(ngcontent2, TypeMatcher<EmbeddedContentAst>());

    expect(ngcontent1.isSynthetic, false);
    expect(
        (ngcontent1 as EmbeddedContentAst).closeComplement.isSynthetic, true);

    expect(ngcontent2.isSynthetic, true);
    expect(
        (ngcontent2 as EmbeddedContentAst).closeComplement.isSynthetic, false);

    expect(astsToString(asts),
        '<ng-content select="*"></ng-content><div></div><ng-content select="*"></ng-content>');

    var exceptions = recoveringExceptionHandler.exceptions;
    expect(exceptions.length, 2);

    var e1 = exceptions[0];
    expect(e1.errorCode, NgParserWarningCode.NGCONTENT_MUST_CLOSE_IMMEDIATELY);
    expect(e1.offset, 0);
    expect(e1.length, 12);

    var e2 = exceptions[1];
    expect(e2.errorCode, NgParserWarningCode.DANGLING_CLOSE_ELEMENT);
    expect(e2.offset, 23);
    expect(e2.length, 13);
  });

  test('Should handle ng-content used with void end', () {
    var asts = parse('<ng-content/></ng-content>');
    expect(asts.length, 1);

    var ngContent = asts[0];
    expect(ngContent, TypeMatcher<EmbeddedContentAst>());
    expect(astsToString(asts), '<ng-content select="*"></ng-content>');

    checkException(NgParserWarningCode.NONVOID_ELEMENT_USING_VOID_END, 11, 2);
  });

  test('Should allow (and drop) whitespace inside ng-content', () {
    var asts = parse('<ng-content>\n </ng-content>');
    expect(asts, hasLength(1));

    var ngContent = asts[0];
    expect(ngContent, const TypeMatcher<EmbeddedContentAst>());
    expect(astsToString(asts), '<ng-content select="*"></ng-content>');
  });

  test('Should resolve dangling open template', () {
    var asts = parse('<div><template ngFor let-item [ngForOf]="items" '
        'let-i="index"></div>');
    expect(asts.length, 1);

    var div = asts[0];
    expect(div.childNodes.length, 1);

    var template = div.childNodes[0];
    expect(template, TypeMatcher<EmbeddedTemplateAst>());
    expect(template.isSynthetic, false);
    expect((template as EmbeddedTemplateAst).closeComplement.isSynthetic, true);

    expect(
        astsToString(asts),
        '<div><template ngFor [ngForOf]="items" let-item let-i="index">'
        '</template></div>');

    checkException(NgParserWarningCode.CANNOT_FIND_MATCHING_CLOSE, 5, 57);
  });

  test('Should resolve dangling close template', () {
    var asts = parse('<div></template></div>');
    expect(asts.length, 1);

    var div = asts[0];
    expect(div.childNodes.length, 1);

    var template = div.childNodes[0];
    expect(template, TypeMatcher<EmbeddedTemplateAst>());
    expect(template.isSynthetic, true);
    expect(
        (template as EmbeddedTemplateAst).closeComplement.isSynthetic, false);
    expect(astsToString(asts), '<div><template></template></div>');

    checkException(NgParserWarningCode.DANGLING_CLOSE_ELEMENT, 5, 11);
  });

  test('Should handle template used with void end', () {
    var asts = parse('<template ngFor let-item [ngForOf]="items" '
        'let-i="index"/></template>');
    expect(asts.length, 1);

    var ngContent = asts[0];
    expect(ngContent, TypeMatcher<EmbeddedTemplateAst>());
    expect(
        astsToString(asts),
        '<template ngFor [ngForOf]="items" let-item let-i="index">'
        '</template>');

    checkException(NgParserWarningCode.NONVOID_ELEMENT_USING_VOID_END, 56, 2);
  });

  test('Should drop invalid attrs in ng-content', () {
    var html =
        '<ng-content bad = "badValue" select="*" [badProp] = "badPropValue" #badRef></ng-content>';
    var asts = parse(html);
    expect(asts.length, 1);

    var ngcontent = asts[0] as EmbeddedContentAst;
    expect(ngcontent.selector, '*');

    var exceptions = recoveringExceptionHandler.exceptions;
    expect(exceptions.length, 3);

    var e1 = exceptions[0];
    expect(e1.errorCode, NgParserWarningCode.INVALID_DECORATOR_IN_NGCONTENT);
    expect(e1.offset, 11);
    expect(e1.length, 17);

    var e2 = exceptions[1];
    expect(e2.errorCode, NgParserWarningCode.INVALID_DECORATOR_IN_NGCONTENT);
    expect(e2.offset, 39);
    expect(e2.length, 27);

    var e3 = exceptions[2];
    expect(e3.errorCode, NgParserWarningCode.INVALID_DECORATOR_IN_NGCONTENT);
    expect(e3.offset, 66);
    expect(e3.length, 8);
  });

  test('Should drop duplicate select attrs in ng-content', () {
    var html = '<ng-content select = "*" select = "badSelect"></ng-content>';
    var asts = parse(html);
    expect(asts.length, 1);

    var ngcontent = asts[0] as EmbeddedContentAst;
    expect(ngcontent.selector, '*');

    checkException(NgParserWarningCode.DUPLICATE_SELECT_DECORATOR, 24, 21);
  });

  test(
    'Should parse property decorators with invalid dart value',
    () {
      var asts = parse('<div [myProp]="["></div>', parseExpression: true);
      expect(asts.length, 1);

      var element = asts[0] as ElementAst;
      expect(element.properties.length, 1);
      var property = element.properties[0];
      expect(property.expression, null);
      expect(property.value, '[');

      checkException(ScannerErrorCode.EXPECTED_TOKEN, 16, 1);
      // TODO: https://github.com/dart-lang/angular/issues/1001
    },
    tags: ['fails-on-travis'],
    skip: 'Not supported - https://github.com/dart-lang/angular/issues/1121',
  );

  test(
    'Should parse event decorators with invalid dart value',
    () {
      var asts = parse('<div (myEvnt)="["></div>', parseExpression: true);
      expect(asts.length, 1);

      var element = asts[0] as ElementAst;
      expect(element.events.length, 1);
      var event = element.events[0];
      expect(event.expression, null);
      expect(event.value, '[');

      checkException(ScannerErrorCode.EXPECTED_TOKEN, 16, 1);
      // TODO: https://github.com/dart-lang/angular/issues/1001
    },
    tags: ['fails-on-travis'],
    skip: 'Not supported - https://github.com/dart-lang/angular/issues/1121',
  );

  test('Should parse banana decorator with invalid dart value', () {
    var asts = parse(
      '<div [(myBnna)]="["></div>',
      desugar: true,
      parseExpression: true,
    );
    expect(asts.length, 1);

    var element = asts[0] as ElementAst;
    expect(element.bananas.length, 0);

    expect(element.events.length, 1);
    expect(element.properties.length, 1);
    expect(element.events[0].expression, null);
    expect(element.properties[0].expression, null);

    expect(recoveringExceptionHandler.exceptions.length, 2);
    var e1 = recoveringExceptionHandler.exceptions[0];
    expect(e1.errorCode, ScannerErrorCode.EXPECTED_TOKEN);
    var e2 = recoveringExceptionHandler.exceptions[1];
    expect(e2.errorCode, ScannerErrorCode.EXPECTED_TOKEN);
  }, skip: 'Not supported - https://github.com/dart-lang/angular/issues/1121');

  test('Should parse star(non micro) decorator with invalid dart value', () {
    var asts =
        parse('<div *ngFor="["></div>', desugar: true, parseExpression: true);
    expect(asts.length, 1);
    expect(asts[0], TypeMatcher<EmbeddedTemplateAst>());

    var template = asts[0] as EmbeddedTemplateAst;
    expect(template.properties.length, 1);
    expect(template.properties[0].expression, null);

    expect(recoveringExceptionHandler.exceptions.length, 1);
    var exception = recoveringExceptionHandler.exceptions[0];
    expect(exception.errorCode, ScannerErrorCode.EXPECTED_TOKEN);
  }, skip: 'Not supported - https://github.com/dart-lang/angular/issues/1121');

  test('Should parse star(micro) decorator with invalid dart value', () {
    var asts = parse(
      '<div *ngFor="let["></div>',
      desugar: true,
      parseExpression: true,
    );
    expect(asts.length, 1);
    // Desugaring fails, so remains as [ElementAst]
    // instead of [EmbeddedTemplateAst].
    expect(asts[0], TypeMatcher<ElementAst>());
    var element = asts[0] as ElementAst;
    expect(element.properties.length, 0);
    expect(element.references.length, 0);
    expect(element.stars.length, 1);

    checkException(NgParserWarningCode.INVALID_MICRO_EXPRESSION, 13, 4);
  },
      skip: "Regular expressions can't determine this isn't a value being "
          "bound to the 'ngFor' property.");

  test('Should resolve event name with too many fixes', () {
    var asts = parse('<div (event.postfix.illegal)="blah"></div>');
    expect(asts.length, 1);

    var element = asts[0] as ElementAst;
    expect(element.events.length, 1);
    var event = element.events[0];
    expect(event.name, 'event');
    expect(event.reductions[0], 'postfix');

    checkException(NgParserWarningCode.EVENT_NAME_TOO_MANY_FIXES, 6, 21);
  }, skip: 'Does not throw exception.');

  test('Should resolve property name with too many fixes', () {
    var asts = parse('<div [prop.postfix.unit.illegal]="blah"></div>');
    expect(asts.length, 1);

    var element = asts[0] as ElementAst;
    expect(element.properties.length, 1);
    var property = element.properties[0];
    expect(property.name, 'prop');
    expect(property.postfix, 'postfix');
    expect(property.unit, 'unit');

    checkException(NgParserWarningCode.PROPERTY_NAME_TOO_MANY_FIXES, 6, 25);
  });

  test('Should resolve on- event prefix without decorator', () {
    var asts = parse('<div on-="someValue"></div>');
    expect(asts.length, 1);

    var element = asts[0] as ElementAst;
    expect(element.events.length, 1);
    var event = element.events[0] as ParsedEventAst;
    expect(event.name, '');
    expect(event.prefixToken.lexeme, 'on-');
    expect(event.value, 'someValue');

    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 3);
  });

  test('Should resolve bind- event prefix without decorator', () {
    var asts = parse('<div bind-="someValue"></div>');
    expect(asts.length, 1);

    var element = asts[0] as ElementAst;
    expect(element.properties.length, 1);
    var property = element.properties[0] as ParsedPropertyAst;
    expect(property.name, '');
    expect(property.prefixToken.lexeme, 'bind-');
    expect(property.value, 'someValue');

    checkException(NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX, 5, 5);
  });

  test('Should resolve unterminated mustache in attr value', () {
    var asts = parse('<div someAttr="{{mustache1 {{ mustache2"></div>');
    expect(asts.length, 1);

    var element = asts[0] as ElementAst;
    expect(element.attributes.length, 1);
    var attr = element.attributes[0] as ParsedAttributeAst;
    expect(attr.value, '{{mustache1 {{ mustache2');

    expect(attr.mustaches.length, 2);
    var mustache1 = attr.mustaches[0] as ParsedInterpolationAst;
    var mustache2 = attr.mustaches[1] as ParsedInterpolationAst;

    expect(mustache1.beginToken.offset, 15);
    expect(mustache1.beginToken.lexeme, '{{');
    expect(mustache1.beginToken.errorSynthetic, false);
    expect(mustache1.valueToken.offset, 17);
    expect(mustache1.valueToken.lexeme, 'mustache1 ');
    expect(mustache1.endToken.offset, 27);
    expect(mustache1.endToken.lexeme, '}}');
    expect(mustache1.endToken.errorSynthetic, true);

    expect(mustache2.beginToken.offset, 27);
    expect(mustache2.beginToken.lexeme, '{{');
    expect(mustache2.beginToken.errorSynthetic, false);
    expect(mustache2.valueToken.offset, 29);
    expect(mustache2.valueToken.lexeme, ' mustache2');
    expect(mustache2.endToken.offset, 39);
    expect(mustache2.endToken.lexeme, '}}');
    expect(mustache2.endToken.errorSynthetic, true);

    var exceptions = recoveringExceptionHandler.exceptions;
    expect(exceptions.length, 2);
    var e1 = exceptions[0];
    var e2 = exceptions[1];

    expect(e1.errorCode, NgParserWarningCode.UNTERMINATED_MUSTACHE);
    expect(e1.offset, 15);
    expect(e1.length, 2);

    expect(e2.errorCode, NgParserWarningCode.UNTERMINATED_MUSTACHE);
    expect(e2.offset, 27);
    expect(e2.length, 2);
  });

  test('Should flag invalid usage of let-binding and drop', () {
    var asts = parse('<div let-someVar></div>');
    expect(asts.length, 1);

    var element = asts[0] as ElementAst;
    expect(element.attributes.length, 0);

    var exceptions = recoveringExceptionHandler.exceptions;
    expect(exceptions.length, 1);
    var e = exceptions[0];

    expect(e.errorCode, NgParserWarningCode.INVALID_LET_BINDING_IN_NONTEMPLATE);
    expect(e.offset, 5);
    expect(e.length, 11);
  });

  test('Should flag let- binding without variable name', () {
    var asts = parse('<template let-></template>');
    expect(asts.length, 1);

    var element = asts[0] as EmbeddedTemplateAst;
    expect(element.letBindings.length, 0);

    var exceptions = recoveringExceptionHandler.exceptions;
    expect(exceptions.length, 1);
    var e = exceptions[0];

    expect(e.errorCode, NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX);
    expect(e.offset, 10);
    expect(e.length, 4);
  });

  test('Should resolve unopened mustache in attr value', () {
    var asts = parse('<div someAttr="mustache1 }} mustache2 }}"></div>');
    expect(asts.length, 1);

    var element = asts[0] as ElementAst;
    expect(element.attributes.length, 1);
    var attr = element.attributes[0] as ParsedAttributeAst;
    expect(attr.value, 'mustache1 }} mustache2 }}');

    expect(attr.mustaches.length, 2);
    var mustache1 = attr.mustaches[0] as ParsedInterpolationAst;
    var mustache2 = attr.mustaches[1] as ParsedInterpolationAst;

    expect(mustache1.beginToken.offset, 15);
    expect(mustache1.beginToken.lexeme, '{{');
    expect(mustache1.beginToken.errorSynthetic, true);
    expect(mustache1.valueToken.offset, 15);
    expect(mustache1.valueToken.lexeme, 'mustache1 ');
    expect(mustache1.endToken.offset, 25);
    expect(mustache1.endToken.lexeme, '}}');
    expect(mustache1.endToken.errorSynthetic, false);

    expect(mustache2.beginToken.offset, 27);
    expect(mustache2.beginToken.lexeme, '{{');
    expect(mustache2.beginToken.errorSynthetic, true);
    expect(mustache2.valueToken.offset, 27);
    expect(mustache2.valueToken.lexeme, ' mustache2 ');
    expect(mustache2.endToken.offset, 38);
    expect(mustache2.endToken.lexeme, '}}');
    expect(mustache2.endToken.errorSynthetic, false);

    var exceptions = recoveringExceptionHandler.exceptions;
    expect(exceptions.length, 2);
    var e1 = exceptions[0];
    var e2 = exceptions[1];

    expect(e1.errorCode, NgParserWarningCode.UNOPENED_MUSTACHE);
    expect(e1.offset, 25);
    expect(e1.length, 2);

    expect(e2.errorCode, NgParserWarningCode.UNOPENED_MUSTACHE);
    expect(e2.offset, 38);
    expect(e2.length, 2);
  });

  test('Should handle unclosed quote on attribute value', () {
    final asts = parse('<p foo="bar></p>');
    expect(asts, hasLength(1));

    final p = asts.first as ElementAst;
    expect(p.attributes, hasLength(1));
    expect(p.isSynthetic, false);
    expect(p.closeComplement.isSynthetic, true);

    final foo = p.attributes.first;
    // The recovered text used to span an invalid range and cause a crash.
    expect(foo.sourceSpan.text, 'foo="bar></p>');

    final exceptions = recoveringExceptionHandler.exceptions;
    expect(exceptions, hasLength(3));

    final e1 = exceptions[0];
    expect(e1.errorCode, NgParserWarningCode.UNCLOSED_QUOTE);
    expect(e1.offset, 7);
    expect(e1.length, 9);

    final e2 = exceptions[1];
    expect(e2.errorCode, NgParserWarningCode.EXPECTED_TAG_CLOSE);
    expect(e2.offset, 7);
    expect(e2.length, 9);

    final e3 = exceptions[2];
    expect(e3.errorCode, NgParserWarningCode.CANNOT_FIND_MATCHING_CLOSE);
    expect(e3.offset, 0);
    expect(e3.length, 16);
  });
}
