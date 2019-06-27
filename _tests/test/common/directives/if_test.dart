@TestOn('browser')

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/src/runtime.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'if_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('ngIf', () {
    tearDown(() => disposeAnyRunningTest());

    test("should work in a template element", () async {
      var testBed = NgTestBed<NgIfInTemplateComponent>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement;
      expect(element.querySelectorAll("copy-me"), hasLength(1));
      expect(element.innerHtml, contains('hello2'));
    });

    test("should toggle node when condition changes", () async {
      var testBed = NgTestBed<NgIfToggleTestComponent>();
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
      var testBed = NgTestBed<NgIfNestedTestComponent>();
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

    test("should update multiple bindings", () async {
      var testBed = NgTestBed<NgIfMultiUpdateTestComponent>();
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
      var testBed = NgTestBed<NgIfThrowsDuringChangeDetection>();
      var fixture = await testBed.create();
      expect(
        fixture.update((c) => c.startFailing = true),
        throwsA(isExpressionChanged),
      );
    });
  });
}

const isExpressionChanged = TypeMatcher<UnstableExpressionError>();

@Directive(
  selector: 'copy-me',
)
class CopyMe {}

@Component(
  selector: 'ngif-intemplate-test',
  template: '''
    <div>
      <template [ngIf]="booleanCondition">
        <copy-me>hello2</copy-me>
      </template>
    </div>
  ''',
  directives: [
    CopyMe,
    NgIf,
  ],
)
class NgIfInTemplateComponent {
  bool booleanCondition = true;
}

@Component(
  selector: 'ngif-toggle-test',
  template: '''
    <div>
      <copy-me *ngIf="booleanCondition">hello</copy-me>
    </div>
  ''',
  directives: [
    CopyMe,
    NgIf,
  ],
)
class NgIfToggleTestComponent {
  bool booleanCondition = true;
}

@Component(
  selector: 'ngif-nested-test',
  template: '''
    <div>
      <template [ngIf]="booleanCondition">
        <copy-me *ngIf="nestedBooleanCondition">hello</copy-me>
      </template>
    </div>
  ''',
  directives: [
    CopyMe,
    NgIf,
  ],
)
class NgIfNestedTestComponent {
  bool booleanCondition = true;
  bool nestedBooleanCondition = true;
}

@Component(
  selector: 'ngif-multiupdate-test',
  template: '<div>'
      '<copy-me *ngIf="numberCondition + 1 >= 2">helloNumber</copy-me>'
      '<copy-me *ngIf="stringCondition == \'foo\'">helloString</copy-me>'
      '<copy-me *ngIf="functionCondition(stringCondition, numberCondition)">helloFunction</copy-me>'
      '</div>',
  directives: [
    CopyMe,
    NgIf,
  ],
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
  directives: [
    CopyMe,
    NgIf,
  ],
)
class NgIfThrowsDuringChangeDetection {
  bool _value = false;

  // This is considered illegal and should throw in dev-mode.
  bool get value => _value = !_value;

  bool startFailing = false;
}
