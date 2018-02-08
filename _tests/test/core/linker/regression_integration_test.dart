@TestOn('browser')

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'regression_integration_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should evaluate conditional operator with right precedence', () async {
    final testBed = new NgTestBed<RightPrecedenceConditionalComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, 'red');
    await testFixture.update((component) => component.hasBorder = true);
    expect(testFixture.text, 'red border');
  });

  group('Provider', () {
    void testProvider(dynamic token, dynamic tokenValue) {
      final injector = ReflectiveInjector.resolveAndCreate([
        provide(token, useValue: tokenValue),
      ]);
      expect(injector.get(token), tokenValue);
    }

    test("should support OpaqueToken with name containing '.'", () {
      testProvider(new OpaqueToken('a.b'), 1);
    });

    test("should support string token containing '.'", () {
      testProvider('a.b', 1);
    });

    test('should support anonymous function token', () {
      testProvider(() => true, 1);
    });

    test('should support OpaqueToken with a String-keyed Map value', () {
      testProvider(const OpaqueToken('token'), {'a': 1});
    });
  });

  test("should interpolate previous element's class binding", () async {
    final testBed = new NgTestBed<InterpolateClassBindingComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, 'foo');
  });

  test('should support ngClass before a component and transclusion inside ngIf',
      () async {
    final testBed = new NgTestBed<ContentProviderComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, 'ABC');
  });
}

@Component(
  selector: 'right-precedence-conditional',
  template: '{{"red" + (hasBorder ? " border" : "")}}',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class RightPrecedenceConditionalComponent {
  bool hasBorder = false;
}

@Component(
  selector: 'interpolate-class-binding',
  template: '<div [class.foo]="true" #element>{{element.className}}</div>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class InterpolateClassBindingComponent {}

@Component(
  selector: 'content-host',
  template: '<ng-content></ng-content>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ContentHostComponent {}

@Component(
  selector: 'content-provider',
  template: 'A<content-host *ngIf="true" [ngClass]="\'red\'">B</content-host>C',
  directives: const [
    ContentHostComponent,
    NgClass,
    NgIf,
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ContentProviderComponent {}
