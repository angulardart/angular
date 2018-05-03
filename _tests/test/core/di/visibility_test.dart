@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'visibility_test.template.dart' as ng_generated;

final throwsNoProviderError = throwsA(const isInstanceOf<NoProviderError>());

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  group('Visibility', () {
    group('local', () {
      test('component should not be injectable by child component', () async {
        final testBed = new NgTestBed<ShouldFailToInjectParentComponent>();
        expect(testBed.create(), throwsNoProviderError);
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
        expect(testBed.create(), throwsNoProviderError);
      });

      test('directive should not be injectable in same view', () async {
        final testBed = new NgTestBed<ShouldFailToInjectFromView>();
        expect(testBed.create(), throwsNoProviderError);
      });

      test('directive should not be injectable in child view', () async {
        final testBed = new NgTestBed<ShouldFailToInjectFromParentView>();
        expect(testBed.create(), throwsNoProviderError);
      });

      test('service on Visibility.none component is injectable', () async {
        final testBed = new NgTestBed<MyComponentWithServiceTest>();
        var testFixture = await testBed.create();
        expect(testFixture.rootElement, isNotNull);
      });

      test('component may provide itself via another token', () async {
        final testBed = new NgTestBed<ShouldInjectAliasedLocal>();
        final testFixture = await testBed.create();
        expect(testFixture.text, testFixture.assertOnlyInstance.text);
      });

      test('directive may provide itself for a multi-token', () async {
        final testBed = new NgTestBed<ShouldInjectMultiToken>();
        final testFixture = await testBed.create();
        expect(testFixture.assertOnlyInstance.child.dependencies, [
          const isInstanceOf<VisibilityLocalImplementation>(),
          const isInstanceOf<VisibilityAllImplementation>(),
        ]);
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
)
class InjectsVisibilityLocalComponent {
  ShouldFailToInjectParentComponent parent;

  InjectsVisibilityLocalComponent(this.parent);
}

@Component(
  selector: 'should-fail-to-inject-parent-component',
  template: '<injects-visibility-local></injects-visibility-local>',
  directives: const [InjectsVisibilityLocalComponent],
)
class ShouldFailToInjectParentComponent {}

@Directive(
  selector: '[visibility-none]',
)
class VisibilityNoneDirective {}

@Component(
  selector: 'should-query-directive',
  template: '<div visibility-none></div>',
  directives: const [VisibilityNoneDirective],
)
class ShouldQueryDirective {
  @ViewChild(VisibilityNoneDirective)
  VisibilityNoneDirective directive;
}

@Component(
  selector: 'injects-directive',
  template: '',
)
class InjectsDirectiveComponent {
  VisibilityNoneDirective directive;

  InjectsDirectiveComponent(this.directive);
}

@Component(
  selector: 'should-fail-to-inject-from-element',
  template: '<injects-directive visibility-none></injects-directive>',
  directives: const [InjectsDirectiveComponent, VisibilityNoneDirective],
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
)
class ShouldFailToInjectFromView {}

@Component(
  selector: 'injects-directive-host',
  template: '<injects-directive></injects-directive>',
  directives: const [InjectsDirectiveComponent],
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
)
class MyComponentWithServiceTest {}

@Component(
  selector: 'child-component-provides-service',
  providers: const [
    const Provider(SomeService, useExisting: MyChildComponentProvidesService)
  ],
  template: '<div></div>',
)
class MyChildComponentProvidesService implements SomeService {
  @override
  foo() {}
}

@Directive(
  selector: '[dirNeedsService]',
)
class MyDirectiveNeedsService {
  final SomeService someService;

  MyDirectiveNeedsService(
      this.someService, ViewContainerRef ref, TemplateRef templateRef);
}

abstract class Dependency {
  String get text;
}

@Component(
  selector: 'should-inject-aliased-local',
  template: '<injects-aliased-local></injects-aliased-local>',
  directives: const [InjectsAliasedLocal],
  providers: const [
    const Provider(Dependency, useExisting: ShouldInjectAliasedLocal),
  ],
)
class ShouldInjectAliasedLocal extends Dependency {
  final String text = 'Hello';
}

@Component(
  selector: 'injects-aliased-local',
  template: '{{dependency.text}}',
)
class InjectsAliasedLocal {
  final Dependency dependency;

  InjectsAliasedLocal(this.dependency);
}

@Component(
  selector: 'injects-visibility-all',
  template: '',
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

abstract class Interface {}

const implementations = const MultiToken<Interface>();

@Directive(
  selector: '[all]',
  providers: const [
    const ExistingProvider.forToken(
      implementations,
      VisibilityAllImplementation,
    ),
  ],
  visibility: Visibility.all,
)
class VisibilityAllImplementation implements Interface {}

@Directive(
  selector: '[local]',
  providers: const [
    const ExistingProvider.forToken(
      implementations,
      VisibilityLocalImplementation,
    ),
  ],
)
class VisibilityLocalImplementation implements Interface {}

@Component(
  selector: 'injects-multi-token',
  template: '',
)
class InjectsMultiToken {
  final List<Interface> dependencies;

  InjectsMultiToken(@implementations this.dependencies);
}

@Component(
  selector: 'should-injects-multi-token',
  template: '<injects-multi-token local all></injects-multi-token>',
  directives: const [
    InjectsMultiToken,
    VisibilityLocalImplementation,
    VisibilityAllImplementation,
  ],
)
class ShouldInjectMultiToken {
  @ViewChild(InjectsMultiToken)
  InjectsMultiToken child;
}
