@TestOn('browser')

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'visibility_test.template.dart' as ng_generated;

// TODO(leonsenft): expect specific DI error when introduced; b/64980526.
void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  group('Visibility', () {
    group('local', () {
      test('component should not be injectable by child component', () async {
        final testBed = new NgTestBed<ShouldFailToInjectParentComponent>();
        expect(testBed.create(), throwsInAngular(anything));
      });

      test('directive should be accessible via a query', () async {
        final testBed = new NgTestBed<ShouldQueryDirective>();
        final testFixture = await testBed.create();
        await testFixture.update((component) {
          expect(component.directive, isNotNull);
        });
      });

      test('directive should not be injectable on same element', () async {
        final testBed = new NgTestBed<ShouldFailToInjectFromElement>();
        expect(testBed.create(), throwsInAngular(anything));
      });

      test('directive should not be injectable in same view', () async {
        final testBed = new NgTestBed<ShouldFailToInjectFromView>();
        expect(testBed.create(), throwsInAngular(anything));
      });

      test('directive should not be injectable in child view', () async {
        final testBed = new NgTestBed<ShouldFailToInjectFromParentView>();
        expect(testBed.create(), throwsInAngular(anything));
      });

      test('service on Visibility.none component is injectable', () async {
        final testBed = new NgTestBed<MyComponentWithServiceTest>();
        var testFixture = await testBed.create();
        expect(testFixture.rootElement, isNotNull);
      });
    });

    group('all', () {
      test('component should be injectable by child component', () async {
        final testBed = new NgTestBed<ShouldInjectParentComponent>();
        final testFixture = await testBed.create();
        final testComponent = testFixture.assertOnlyInstance;
        expect(testComponent.child.parent, testComponent);
      });
    });
  });
}

@Component(
  selector: 'injects-visibility-local',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class InjectsVisibilityLocalComponent {
  ShouldFailToInjectParentComponent parent;
  InjectsVisibilityLocalComponent(this.parent);
}

@Component(
  selector: 'should-fail-to-inject-parent-component',
  template: '<injects-visibility-local></injects-visibility-local>',
  directives: const [InjectsVisibilityLocalComponent],
  visibility: Visibility.local,
)
class ShouldFailToInjectParentComponent {}

@Directive(selector: '[visibility-none]', visibility: Visibility.local)
class VisibilityNoneDirective {}

@Component(
  selector: 'should-query-directive',
  template: '<div visibility-none></div>',
  directives: const [VisibilityNoneDirective],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ShouldQueryDirective {
  @ViewChild(VisibilityNoneDirective)
  VisibilityNoneDirective directive;
}

@Component(
  selector: 'injects-directive',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class InjectsDirectiveComponent {
  VisibilityNoneDirective directive;
  InjectsDirectiveComponent(this.directive);
}

@Component(
  selector: 'should-fail-to-inject-from-element',
  template: '<injects-directive visibility-none></injects-directive>',
  directives: const [InjectsDirectiveComponent, VisibilityNoneDirective],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ShouldFailToInjectFromElement {}

@Component(
  selector: 'should-fail-to-inject-from-view',
  template: '''
  <div visibility-none>
    <injects-directive></injects-directive>
  </div>
  ''',
  directives: const [InjectsDirectiveComponent, VisibilityNoneDirective],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ShouldFailToInjectFromView {}

@Component(
  selector: 'injects-directive-host',
  template: '<injects-directive></injects-directive>',
  directives: const [InjectsDirectiveComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class InjectsDirectiveHostComponent {}

@Component(
  selector: 'should-fail-to-inject-from-parent-view',
  template: '''
  <div visibility-none>
    <injects-directive-host></injects-directive-host>
  </div>
  ''',
  directives: const [
    InjectsDirectiveHostComponent,
    VisibilityNoneDirective,
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ShouldFailToInjectFromParentView {}

/// This service is exposed through a component that is marked Visibility.none.
/// The test verifies that injectorGet calls in compiler use the service not
/// useExisting token.
abstract class SomeService {
  void foo();
}

@Component(
  selector: 'my-component-with-service-test',
  template: '<child-component-provides-service>'
      '<div *dirNeedsService></div>'
      '</child-component-provides-service>',
  directives: const [MyChildComponentProvidesService, MyDirectiveNeedsService],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class MyComponentWithServiceTest {}

@Component(
  selector: 'child-component-provides-service',
  providers: const [
    const Provider(SomeService, useExisting: MyChildComponentProvidesService)
  ],
  template: '<div></div>',
  visibility: Visibility.local,
)
class MyChildComponentProvidesService implements SomeService {
  @override
  foo() {}
}

@Directive(
  selector: '[dirNeedsService]',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class MyDirectiveNeedsService {
  final SomeService someService;
  MyDirectiveNeedsService(
      this.someService, ViewContainerRef ref, TemplateRef templateRef);
}

@Component(
  selector: 'injects-visibility-all',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class InjectsVisibilityAllComponent {
  final ShouldInjectParentComponent parent;
  InjectsVisibilityAllComponent(this.parent);
}

@Component(
  selector: 'should-inject-parent-component',
  template: '<injects-visibility-all></injects-visibility-all>',
  directives: const [InjectsVisibilityAllComponent],
  visibility: Visibility.all,
)
class ShouldInjectParentComponent {
  @ViewChild(InjectsVisibilityAllComponent)
  InjectsVisibilityAllComponent child;
}
