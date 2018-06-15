@TestOn('browser')

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'binding_integration_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should consume text binding', () async {
    final testBed = NgTestBed<BoundTextComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, 'Initial text');
    await testFixture.update((component) => component.text = 'New text');
    expect(testFixture.text, 'New text');
  });

  test('should interpolate null as blank string', () async {
    final testBed = NgTestBed<BoundTextComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, 'Initial text');
    await testFixture.update((component) => component.text = null);
    expect(testFixture.text, '');
  });

  test('should consume property binding', () async {
    final testBed = NgTestBed<BoundPropertyComponent>();
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.querySelector('div');
    expect(div.id, 'Initial ID');
    await testFixture.update((component) => component.id = 'New ID');
    expect(div.id, 'New ID');
  });

  test('should consume ARIA attribute binding', () async {
    final testBed = NgTestBed<BoundAriaAttributeComponent>();
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.querySelector('div');
    expect(div.attributes, containsPair('aria-label', 'Initial label'));
    await testFixture.update((component) => component.label = 'New label');
    expect(div.attributes, containsPair('aria-label', 'New label'));
  });

  test('should remove attribute when bound expression is null', () async {
    final testBed = NgTestBed<BoundAttributeComponent>();
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.querySelector('div');
    expect(div.attributes, containsPair('foo', 'Initial value'));
    await testFixture.update((component) => component.value = null);
    expect(div.attributes, isNot(contains('foo')));
  });

  test('should remove style when bound expression is null', () async {
    final testBed = NgTestBed<BoundStyleComponent>();
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.querySelector('div');
    expect(div.style.height, '10px');
    await testFixture.update((component) => component.height = null);
    expect(div.style.height, '');
  });

  test('should consume property binding with mismatched value name', () async {
    final testBed = NgTestBed<BoundMismatchedPropertyComponent>();
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.querySelector('div');
    expect(div.tabIndex, 0);
    await testFixture.update((component) => component.index = 5);
    expect(div.tabIndex, 5);
  });

  test('should consume camel case property binding', () async {
    final testBed = NgTestBed<BoundCamelCasePropertyComponent>();
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.querySelector('div');
    expect(div.tabIndex, 1);
    await testFixture.update((component) => component.index = 0);
    expect(div.tabIndex, 0);
  });

  test('should consume innerHtml binding', () async {
    final testBed = NgTestBed<BoundInnerHtmlComponent>();
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.querySelector('div');
    expect(div.innerHtml, 'Initial <span>HTML</span>');
    await testFixture
        .update((component) => component.html = 'New <div>HTML</div>');
    expect(div.innerHtml, 'New <div>HTML</div>');
  });

  test('should consume className binding using class alias', () async {
    final testBed = NgTestBed<BoundClassNameAlias>();
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.querySelector('div');
    expect(div.classes, contains('foo'));
    expect(div.classes, contains('bar'));
    expect(div.classes, isNot(contains('initial')));
  });
}

@Component(
  selector: 'bound-text',
  template: '<div>{{text}}</div>',
)
class BoundTextComponent {
  String text = 'Initial text';
}

@Component(
  selector: 'bound-property',
  template: '<div [id]="id"></div>',
)
class BoundPropertyComponent {
  String id = 'Initial ID';
}

@Component(
  selector: 'bound-aria-attribute',
  template: '<div [attr.aria-label]="label"></div>',
)
class BoundAriaAttributeComponent {
  String label = 'Initial label';
}

@Component(
  selector: 'bound-attribute',
  template: '<div [attr.foo]="value"></div>',
)
class BoundAttributeComponent {
  String value = 'Initial value';
}

@Component(
  selector: 'bound-style',
  template: '<div [style.height.px]="height"></div>',
)
class BoundStyleComponent {
  int height = 10;
}

@Component(
  selector: 'bound-mismatched-property',
  template: '<div [tabindex]="index"></div>',
)
class BoundMismatchedPropertyComponent {
  int index = 0;
}

@Component(
  selector: 'bound-camel-case-property',
  template: '<div [tabIndex]="index"></div>',
)
class BoundCamelCasePropertyComponent {
  int index = 1;
}

@Component(
  selector: 'bound-inner-html',
  template: '<div [innerHtml]="html"></div>',
)
class BoundInnerHtmlComponent {
  String html = 'Initial <span>HTML</span>';
}

@Component(
  selector: 'bound-class-name-alias',
  template: '<div class="initial" [class]="classes"></div>',
)
class BoundClassNameAlias {
  String classes = 'foo bar';
}
