@Tags(const ['codegen'])
@TestOn('browser')

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

// TODO(leonsenft): expect specific DI error when introduced; b/64980526.
void main() {
  tearDown(disposeAnyRunningTest);

  group('Visibility.none', () {
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
}

@Component(
  selector: 'injects-parent',
  template: '',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class InjectsParentComponent {
  ShouldFailToInjectParentComponent parent;
  InjectsParentComponent(this.parent);
}

@Component(
  selector: 'should-fail-to-inject-parent-component',
  template: '<injects-parent></injects-parent>',
  directives: const [InjectsParentComponent],
  visibility: Visibility.none,
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class ShouldFailToInjectParentComponent {}

@Directive(selector: '[visibility-none]', visibility: Visibility.none)
class VisibilityNoneDirective {}

@Component(
  selector: 'should-query-directive',
  template: '<div visibility-none></div>',
  directives: const [VisibilityNoneDirective],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class ShouldQueryDirective {
  @ViewChild(VisibilityNoneDirective)
  VisibilityNoneDirective directive;
}

@Component(
  selector: 'injects-directive',
  template: '',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class InjectsDirectiveComponent {
  VisibilityNoneDirective directive;
  InjectsDirectiveComponent(this.directive);
}

@Component(
  selector: 'should-fail-to-inject-from-element',
  template: '<injects-directive visibility-none></injects-directive>',
  directives: const [InjectsDirectiveComponent, VisibilityNoneDirective],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
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
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class ShouldFailToInjectFromView {}

@Component(
  selector: 'injects-directive-host',
  template: '<injects-directive></injects-directive>',
  directives: const [InjectsDirectiveComponent],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
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
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
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
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class MyComponentWithServiceTest {}

@Component(
  selector: 'child-component-provides-service',
  providers: const [
    const Provider(SomeService, useExisting: MyChildComponentProvidesService)
  ],
  template: '<div></div>',
  visibility: Visibility.none,
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class MyChildComponentProvidesService implements SomeService {
  @override
  foo() {}
}

@Directive(selector: '[dirNeedsService]')
class MyDirectiveNeedsService {
  final SomeService someService;
  MyDirectiveNeedsService(
      this.someService, ViewContainerRef ref, TemplateRef templateRef);
}
