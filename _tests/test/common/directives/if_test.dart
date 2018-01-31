@Tags(const ['codegen'])
@TestOn('browser')
library angular2.test.common.directives.if_test;

import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'if_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('ngIf', () {
    tearDown(() => disposeAnyRunningTest());

    test("should work in a template attribute", () async {
      var testBed = new NgTestBed<NgIfInTemplateAttributeComponent>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement;
      expect(element.querySelectorAll("copy-me"), hasLength(1));
      expect(element.innerHtml, contains('hello'));
    });

    test("should work in a template element", () async {
      var testBed = new NgTestBed<NgIfInTemplateComponent>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement;
      expect(element.querySelectorAll("copy-me"), hasLength(1));
      expect(element.innerHtml, contains('hello2'));
    });

    test("should toggle node when condition changes", () async {
      var testBed = new NgTestBed<NgIfToggleTestComponent>();
      NgTestFixture<NgIfToggleTestComponent> testFixture =
          await testBed.create();
      Element element = testFixture.rootElement;

      await testFixture.update((NgIfToggleTestComponent component) {
        component.booleanCondition = false;
      });
      expect(element.querySelectorAll("copy-me"), hasLength(0));

      await testFixture.update((NgIfToggleTestComponent component) {
        component.booleanCondition = true;
      });
      expect(element.querySelectorAll("copy-me"), hasLength(1));

      await testFixture.update((NgIfToggleTestComponent component) {
        component.booleanCondition = false;
      });
      expect(element.querySelectorAll("copy-me"), hasLength(0));
    });

    test("should handle nested if correctly", () async {
      var testBed = new NgTestBed<NgIfNestedTestComponent>();
      NgTestFixture<NgIfNestedTestComponent> testFixture =
          await testBed.create();
      Element element = testFixture.rootElement;

      await testFixture.update((NgIfNestedTestComponent component) {
        component.booleanCondition = false;
      });
      expect(element.querySelectorAll("copy-me"), hasLength(0));
      expect(element.innerHtml.contains('hello'), false);

      await testFixture.update((NgIfNestedTestComponent component) {
        component.booleanCondition = true;
      });
      expect(element.querySelectorAll("copy-me"), hasLength(1));
      expect(element.innerHtml.contains('hello'), true);

      await testFixture.update((NgIfNestedTestComponent component) {
        component.nestedBooleanCondition = false;
      });
      expect(element.querySelectorAll("copy-me"), hasLength(0));
      expect(element.innerHtml.contains('hello'), false);

      await testFixture.update((NgIfNestedTestComponent component) {
        component.nestedBooleanCondition = true;
      });
      expect(element.querySelectorAll("copy-me"), hasLength(1));
      expect(element.innerHtml.contains('hello'), true);

      await testFixture.update((NgIfNestedTestComponent component) {
        component.booleanCondition = false;
      });
      expect(element.querySelectorAll("copy-me"), hasLength(0));
      expect(element.innerHtml.contains('hello'), false);
    });

    test("should work in a template attribute", () async {
      var testBed = new NgTestBed<NgIfMultiUpdateTestComponent>();
      NgTestFixture<NgIfMultiUpdateTestComponent> testFixture =
          await testBed.create();
      Element element = testFixture.rootElement;
      // Check startup.
      expect(element.querySelectorAll("copy-me"), hasLength(3));
      expect(element.text, "helloNumberhelloStringhelloFunction");

      await testFixture.update((NgIfMultiUpdateTestComponent component) {
        component.numberCondition = 0;
      });
      expect(element.querySelectorAll("copy-me"), hasLength(1));
      expect(element.text, "helloString");

      await testFixture.update((NgIfMultiUpdateTestComponent component) {
        component.numberCondition = 1;
        component.stringCondition = 'bar';
      });
      expect(element.querySelectorAll("copy-me"), hasLength(1));
      expect(element.text, "helloNumber");
      await testFixture.update((NgIfMultiUpdateTestComponent component) {
        component.booleanCondition = false;
      });
    });

    test('should throw during change detection if getter changes', () async {
      var testBed = new NgTestBed<NgIfThrowsDuringChangeDetection>();
      var fixture = await testBed.create();
      expect(
        fixture.update((c) => c.startFailing = true),
        throwsInAngular(isExpressionChanged),
      );
    });
  });
}

const isExpressionChanged =
    const isInstanceOf<ExpressionChangedAfterItHasBeenCheckedException>();

@Component(
  selector: 'ngif-intemplate-attr-test',
  template: '<div><copy-me template="ngIf booleanCondition">'
      'hello</copy-me></div>',
  directives: const [NgIf],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NgIfInTemplateAttributeComponent {
  bool booleanCondition = true;
}

@Component(
  selector: 'ngif-intemplate-test',
  template: '<div><template [ngIf]="booleanCondition">'
      '<copy-me>hello2</copy-me></template></div>',
  directives: const [NgIf],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NgIfInTemplateComponent {
  bool booleanCondition = true;
}

@Component(
  selector: 'ngif-toggle-test',
  template: '<div><copy-me template="ngIf booleanCondition">hello</copy-me>'
      '</div>',
  directives: const [NgIf],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NgIfToggleTestComponent {
  bool booleanCondition = true;
}

@Component(
  selector: 'ngif-nested-test',
  template: '<div><template [ngIf]="booleanCondition">'
      '<copy-me *ngIf="nestedBooleanCondition">hello</copy-me>'
      '</template></div>',
  directives: const [NgIf],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NgIfNestedTestComponent {
  bool booleanCondition = true;
  bool nestedBooleanCondition = true;
}

@Component(
  selector: 'ngif-multiupdate-test',
  template: '<div>'
      '<copy-me template="ngIf numberCondition + 1 >= 2">helloNumber</copy-me>'
      '<copy-me template="ngIf stringCondition == \'foo\'">helloString</copy-me>'
      '<copy-me template="ngIf functionCondition(stringCondition, numberCondition)">helloFunction</copy-me>'
      '</div>',
  directives: const [NgIf],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NgIfMultiUpdateTestComponent {
  bool booleanCondition = true;
  bool nestedBooleanCondition = true;
  num numberCondition = 1;
  String stringCondition = 'foo';
  bool functionCondition(s, n) => s == "foo" && n == 1;
}

@Component(
  selector: 'ngif-checkbinding-test',
  template: r'''
    <template [ngIf]="startFailing">
      <div *ngIf="value">Hello</div>
    </template>
  ''',
  directives: const [NgIf],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NgIfThrowsDuringChangeDetection {
  bool _value = false;

  // This is considered illegal and should throw in dev-mode.
  bool get value => _value = !_value;

  bool startFailing = false;
}
