@TestOn('browser')
import 'dart:html';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import '814_query_html_element_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should support @ViewChild with Element', () async {
    final fixture = await NgTestBed<UsesElement>().create();
    expect(fixture.assertOnlyInstance.element.text, '1');
  });

  test('should support @ViewChild with HtmlElement', () async {
    final fixture = await NgTestBed<UsesHtmlElement>().create();
    expect(fixture.assertOnlyInstance.element.text, '2');
  });

  test('should support @ViewChildren with Element', () async {
    final fixture = await NgTestBed<UsesListOfElement>().create();
    expect(fixture.assertOnlyInstance.elements.map((e) => e.text), ['1', '2']);
  });

  test('should support @ViewChildren with HtmlElement', () async {
    final fixture = await NgTestBed<UsesListOfHtmlElement>().create();
    expect(fixture.assertOnlyInstance.elements.map((e) => e.text), ['1', '2']);
  });
}

@Component(
  selector: 'uses-element',
  template: '<div #div>1</div>',
)
class UsesElement {
  @ViewChild('div')
  Element element;
}

@Component(
  selector: 'uses-element',
  template: '<div #div>2</div>',
)
class UsesHtmlElement {
  @ViewChild('div')
  HtmlElement element;
}

@Component(
  selector: 'uses-list-of-element',
  template: '<div #div>1</div><div #div>2</div>',
)
class UsesListOfElement {
  @ViewChildren('div')
  List<Element> elements;
}

@Component(
  selector: 'uses-list-of-element',
  template: '<div #div>1</div><div #div>2</div>',
)
class UsesListOfHtmlElement {
  @ViewChildren('div')
  List<HtmlElement> elements;
}
