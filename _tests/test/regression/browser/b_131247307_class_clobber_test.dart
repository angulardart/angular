@TestOn('browser')
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'b_131247307_class_clobber_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should render static class and ngClass', () async {
    final testBed = NgTestBed.forComponent<TestStaticClassWithNgClass>(
      ng.createTestStaticClassWithNgClassFactory(),
    );
    final fixture = await testBed.create(
      beforeChangeDetection: (i) => i.name = 'dynamic',
    );
    expect(fixture.rootElement.allCssClasses, ['static', 'dynamic']);
  });

  test('should render static class and [class.]', () async {
    final testBed = NgTestBed.forComponent<TestStaticClassWithClassDot>(
      ng.createTestStaticClassWithClassDotFactory(),
    );
    final fixture = await testBed.create(
      beforeChangeDetection: (i) => i.enabled = true,
    );
    expect(fixture.rootElement.allCssClasses, ['static', 'enabled']);
  });

  test('should render static class and [attr.class] but DOES NOT', () async {
    final testBed = NgTestBed.forComponent<TestStaticClassWithAttrClass>(
      ng.createTestStaticClassWithAttrClassFactory(),
    );
    final fixture = await testBed.create(
      beforeChangeDetection: (i) => i.name = 'dynamic',
    );
    expect(
      fixture.rootElement.allCssClasses,
      ['dynamic'],
      reason: '"static" is overriden by [attr.class]',
    );
  });

  test('should render static class and @HostBinding but DOES NOT', () async {
    final testBed = NgTestBed.forComponent<TestStaticClassWithHostClass>(
      ng.createTestStaticClassWithHostClassFactory(),
    );
    final fixture = await testBed.create(
      beforeChangeDetection: (i) => i.name = 'dynamic',
    );
    expect(
      fixture.rootElement.allCssClasses,
      ['dynamic'],
      reason: '"static" is overriden by the @HostBinding of the child',
    );
  });

  test('should render static class, [class.], and ngClass', () async {
    final testBed = NgTestBed.forComponent<TestStaticClassWithClassDotNgClass>(
      ng.createTestStaticClassWithClassDotNgClassFactory(),
    );
    final fixture = await testBed.create(
      beforeChangeDetection: (i) => i
        ..name = 'dynamic'
        ..enabled = true,
    );
    expect(
      fixture.rootElement.allCssClasses,
      ['static', 'dynamic', 'enabled'],
    );
  });

  test('should render dynamic class and ngClass', () async {
    final testBed = NgTestBed.forComponent<TestDynamicClassWithNgClass>(
      ng.createTestDynamicClassWithNgClassFactory(),
    );
    final fixture = await testBed.create(
      beforeChangeDetection: (i) => i
        ..name1 = 'dynamic1'
        ..name2 = 'dynamic2',
    );
    expect(fixture.rootElement.allCssClasses, ['dynamic1', 'dynamic2']);
  });

  test('should render dynamic class and [class.] but DOES NOT', () async {
    final testBed = NgTestBed.forComponent<TestDynamicClassWithClassDot>(
      ng.createTestDynamicClassWithClassDotFactory(),
    );
    final fixture = await testBed.create(
      beforeChangeDetection: (i) => i
        ..name = 'dynamic'
        ..enabled = true,
    );
    expect(
      fixture.rootElement.allCssClasses,
      ['dynamic'],
      reason: '"enabled" is overriden by class="{{..}}"',
    );
  });

  test('should render dynamic class and [attr.class] but DOES NOT', () async {
    final testBed = NgTestBed.forComponent<TestDynamicClassWithAttrClass>(
      ng.createTestDynamicClassWithAttrClassFactory(),
    );
    final fixture = await testBed.create(
      beforeChangeDetection: (i) => i
        ..name1 = 'dynamic1'
        ..name2 = 'dynamic2',
    );
    expect(
      fixture.rootElement.allCssClasses,
      ['dynamic1'],
      reason: '"dynamic2" is overriden by class="{{..}}"',
    );
  });

  test('should render dynamic class and @HostBinding but DOES NOT', () async {
    final testBed = NgTestBed.forComponent<TestDynamicClassWithHostClass>(
      ng.createTestDynamicClassWithHostClassFactory(),
    );
    final fixture = await testBed.create(
      beforeChangeDetection: (i) => i
        ..name1 = 'dynamic1'
        ..name2 = 'dynamic2',
    );
    expect(
      fixture.rootElement.allCssClasses,
      ['dynamic2'],
      reason: '"dynamic1" is overriden by child\'s @HostBinding',
    );
  });
}

extension _SumCssClasses on Element {
  Iterable<String> get allCssClasses {
    return querySelectorAll('*').map((e) => e.classes).expand((c) => c);
  }
}

@Component(
  selector: 'child',
  template: '',
)
class ChildWithHostClass {
  @Input()
  String name;

  @HostBinding('class')
  String get className => name;
}

@Component(
  selector: 'test',
  directives: [
    NgClass,
  ],
  template: r'''
    <div class="static" [ngClass]="name"></div>
  ''',
)
class TestStaticClassWithNgClass {
  String name;
}

@Component(
  selector: 'test',
  template: r'''
    <div class="static" [class.enabled]="enabled"></div>
  ''',
)
class TestStaticClassWithClassDot {
  bool enabled = false;
}

@Component(
  selector: 'test',
  template: r'''
    <div class="static" [attr.class]="name"></div>
  ''',
)
class TestStaticClassWithAttrClass {
  String name;
}

@Component(
  selector: 'test',
  directives: [
    ChildWithHostClass,
  ],
  template: r'''
    <child class="static" [name]="name"></child>
  ''',
)
class TestStaticClassWithHostClass {
  String name;
}

@Component(
  selector: 'test',
  directives: [
    NgClass,
  ],
  template: r'''
    <div class="static" [class.enabled]="enabled" [ngClass]="name"></div>
  ''',
)
class TestStaticClassWithClassDotNgClass {
  bool enabled = false;
  String name;
}

@Component(
  selector: 'test',
  directives: [
    NgClass,
  ],
  template: r'''
    <div class="{{name1}}" [ngClass]="name2"></div>
  ''',
)
class TestDynamicClassWithNgClass {
  String name1;
  String name2;
}

@Component(
  selector: 'test',
  template: r'''
    <div class="{{name}}" [class.enabled]="enabled"></div>
  ''',
)
class TestDynamicClassWithClassDot {
  String name;
  bool enabled = false;
}

@Component(
  selector: 'test',
  template: r'''
    <div class="{{name1}}" [attr.class]="name2"></div>
  ''',
)
class TestDynamicClassWithAttrClass {
  String name1;
  String name2;
}

@Component(
  selector: 'test',
  directives: [
    ChildWithHostClass,
  ],
  template: r'''
    <child class="{{name1}}" [name]="name2"></child>
  ''',
)
class TestDynamicClassWithHostClass {
  String name1;
  String name2;
}
