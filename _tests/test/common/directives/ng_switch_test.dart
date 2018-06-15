@TestOn('browser')

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'ng_switch_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('ngSwitch', () {
    tearDown(() => disposeAnyRunningTest());

    test('should switch amongst when values', () async {
      var testBed = NgTestBed<SwitchWhenTest>();
      var testFixture = await testBed.create();
      expect(testFixture.text.trim(), '');
      await testFixture.update((SwitchWhenTest component) {
        component.switchValue = 'a';
      });
      expect(testFixture.text.trim(), 'when a');
      await testFixture.update((SwitchWhenTest component) {
        component.switchValue = 'b';
      });
      expect(testFixture.text.trim(), 'when b');
    });
    test('should switch among when-values with fallback to default', () async {
      var testBed = NgTestBed<SwitchDefaultTest>();
      var testFixture = await testBed.create();
      expect(testFixture.text.trim(), 'when default');
      await testFixture.update((SwitchDefaultTest component) {
        component.switchValue = 'a';
      });
      expect(testFixture.text.trim(), 'when a');
      await testFixture.update((SwitchDefaultTest component) {
        component.switchValue = 'b';
      });
      expect(testFixture.text.trim(), 'when default');
      await testFixture.update((SwitchDefaultTest component) {
        component.switchValue = 'c';
      });
      expect(testFixture.text.trim(), 'when default');
    });
    test('should support multiple whens with the same value', () async {
      var testBed = NgTestBed<SwitchMultipleWhenTest>();
      var testFixture = await testBed.create();
      expect(testFixture.text,
          allOf(contains('when default1;'), contains('when default2;')));
      await testFixture.update((SwitchMultipleWhenTest component) {
        component.switchValue = 'a';
      });
      expect(
          testFixture.text, allOf(contains('when a1;'), contains('when a2;')));
      await testFixture.update((SwitchMultipleWhenTest component) {
        component.switchValue = 'b';
      });
      expect(
          testFixture.text, allOf(contains('when b1;'), contains('when b2;')));
    });
    test('should change after when-values change', () async {
      var testBed = NgTestBed<SwitchWhenValueTest>();
      var testFixture = await testBed.create();
      await testFixture.update((SwitchWhenValueTest component) {
        component.when1 = 'a';
        component.when2 = 'b';
        component.switchValue = 'a';
      });
      expect(testFixture.text.trim(), 'when 1;');
      await testFixture.update((SwitchWhenValueTest component) {
        component.switchValue = 'b';
      });
      expect(testFixture.text.trim(), 'when 2;');
      await testFixture.update((SwitchWhenValueTest component) {
        component.switchValue = 'c';
      });
      expect(testFixture.text.trim(), 'when default;');
      await testFixture.update((SwitchWhenValueTest component) {
        component.when1 = 'c';
      });
      expect(testFixture.text.trim(), 'when 1;');
      await testFixture.update((SwitchWhenValueTest component) {
        component.when1 = 'd';
      });
      expect(testFixture.text.trim(), 'when default;');
    });
    test('should match equal, but not identical, string cases', () async {
      final testBed = NgTestBed<SwitchEqualStringsTest>();
      final testFixture = await testBed.create(beforeChangeDetection: (comp) {
        comp.switchCase = 'one';
      });
      expect(testFixture.text, contains('first case'));
      await testFixture.update((comp) {
        comp.switchCase = 'two';
      });
      expect(testFixture.text, contains('second case'));
    });
  });
}

@Component(
  selector: 'switch-when-test',
  directives: [NgSwitch, NgSwitchWhen],
  template: '''<div>
  <ul [ngSwitch]="switchValue">
    <template ngSwitchCase="a"><li>when a</li></template>
    <template ngSwitchCase="b"><li>when b</li></template>
  </ul></div>''',
)
class SwitchWhenTest {
  String switchValue;
}

@Component(
  selector: 'switch-default-test',
  directives: [NgSwitch, NgSwitchWhen, NgSwitchDefault],
  template: '''<div>
  <ul [ngSwitch]="switchValue">
    <li *ngSwitchCase="'a'">when a</li>
    <li *ngSwitchDefault>when default</li>
  </ul></div>''',
)
class SwitchDefaultTest {
  String switchValue;
}

@Component(
  selector: 'switch-multiple-when-test',
  directives: [NgSwitch, NgSwitchWhen, NgSwitchDefault],
  template: '''<div>
  <ul [ngSwitch]="switchValue">
    <template ngSwitchCase="a"><li>when a1;</li></template>
    <template ngSwitchCase="b"><li>when b1;</li></template>
    <template ngSwitchCase="a"><li>when a2;</li></template>
    <template ngSwitchCase="b"><li>when b2;</li></template>
    <template ngSwitchDefault><li>when default1;</li></template>
    <template ngSwitchDefault><li>when default2;</li></template>
  </ul></div>''',
)
class SwitchMultipleWhenTest {
  String switchValue;
}

@Component(
  selector: 'switch-when-value-test',
  directives: [NgSwitch, NgSwitchWhen, NgSwitchDefault],
  template: '''<div>
  <ul [ngSwitch]="switchValue">
    <template [ngSwitchCase]="when1"><li>when 1;</li></template>
    <template [ngSwitchCase]="when2"><li>when 2;</li></template>
    <template ngSwitchDefault><li>when default;</li></template>
  </ul></div>''',
)
class SwitchWhenValueTest {
  String switchValue;
  String when1;
  String when2;
}

@Component(
  selector: 'switch-equal-strings-test',
  directives: [NgSwitch, NgSwitchWhen, NgSwitchDefault],
  template: '''
  <div [ngSwitch]="'case-' + switchCase">
    <template ngSwitchCase="case-one">first case</template>
    <template ngSwitchCase="case-two">second case</template>
    <template ngSwitchDefault>default case</template>
  </div>
  ''',
)
class SwitchEqualStringsTest {
  String switchCase;
}
