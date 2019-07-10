@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'visibility_test.template.dart' as ng_generated;

final throwsNoProviderError = throwsA(const TypeMatcher<NoProviderError>());

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  group('Visibility', () {
    group('local', () {
      test('component should not be injectable by child component', () async {
        final testBed = NgTestBed<ShouldFailToInjectParentComponent>();
        expect(testBed.create(), throwsNoProviderError);
      });

      test('directive should be accessible via a query', () async {
        final testBed = NgTestBed<ShouldQueryDirective>();
        final testFixture = await testBed.create();
        expect(testFixture.assertOnlyInstance.directive, isNotNull);
      });

      test('directive should be injectable on same element', () async {
        final testBed = NgTestBed<ShouldInjectFromElement>();
        final testFixture = await testBed.create();
        expect(testFixture.assertOnlyInstance.child.directive, isNotNull);
      });

      test('directive should be injectable in same view', () async {
        final testBed = NgTestBed<ShouldInjectFromView>();
        final testFixture = await testBed.create();
        expect(testFixture.assertOnlyInstance.child.directive, isNotNull);
      });

      test('directive should not be injectable in child view', () async {
        final testBed = NgTestBed<ShouldFailToInjectFromParentView>();
        expect(testBed.create(), throwsNoProviderError);
      });

      test('directive should inject host component', () async {
        final testBed = NgTestBed<ShouldInjectHost>();
        final testFixture = await testBed.create();
        expect(testFixture.assertOnlyInstance.directive.host, isNotNull);
      });

      test('service on Visibility.none component is injectable', () async {
        final testBed = NgTestBed<MyComponentWithServiceTest>();
        var testFixture = await testBed.create();
        expect(testFixture.rootElement, isNotNull);
      });

      test('component may provide itself via another token', () async {
        final testBed = NgTestBed<ShouldInjectAliasedLocal>();
        final testFixture = await testBed.create();
        expect(testFixture.text, testFixture.assertOnlyInstance.text);
      });

      test('directive may provide itself for a multi-token', () async {
        final testBed = NgTestBed<ShouldInjectMultiToken>();
        final testFixture = await testBed.create();
        expect(testFixture.assertOnlyInstance.child.dependencies, [
          const TypeMatcher<VisibilityLocalImplementation>(),
          const TypeMatcher<VisibilityAllImplementation>(),
        ]);
      });

      test('should support $FactoryProvider', () async {
        final testBed = NgTestBed.forComponent(
            ng_generated.ShouldSupportFactoryProviderNgFactory);
        final testFixture = await testBed.create();
        expect(testFixture.assertOnlyInstance.child.interface, isNotNull);
      });

      test('should support $ClassProvider', () async {
        final testBed = NgTestBed.forComponent(
            ng_generated.ShouldSupportClassProviderNgFactory);
        final testFixture = await testBed.create();
        expect(testFixture.assertOnlyInstance.child.interface, isNotNull);
      });
    });

    group('all', () {
      test('component should be injectable by child component', () async {
        final testBed = NgTestBed<ShouldInjectParentComponent>();
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
  directives: [InjectsVisibilityLocalComponent],
)
class ShouldFailToInjectParentComponent {}

@Directive(
  selector: '[visibility-none]',
)
class VisibilityNoneDirective {}

@Component(
  selector: 'should-query-directive',
  template: '<div visibility-none></div>',
  directives: [VisibilityNoneDirective],
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
  directives: [InjectsDirectiveComponent, VisibilityNoneDirective],
)
class ShouldInjectFromElement {
  @ViewChild(InjectsDirectiveComponent)
  InjectsDirectiveComponent child;
}

@Component(
  selector: 'should-fail-to-inject-from-view',
  template: '''
  <div visibility-none>
    <injects-directive></injects-directive>
  </div>
  ''',
  directives: [InjectsDirectiveComponent, VisibilityNoneDirective],
)
class ShouldInjectFromView {
  @ViewChild(InjectsDirectiveComponent)
  InjectsDirectiveComponent child;
}

@Component(
  selector: 'injects-directive-host',
  template: '<injects-directive></injects-directive>',
  directives: [InjectsDirectiveComponent],
)
class InjectsDirectiveHostComponent {}

@Component(
  selector: 'should-fail-to-inject-from-parent-view',
  template: '''
  <div visibility-none>
    <injects-directive-host></injects-directive-host>
  </div>
  ''',
  directives: [
    InjectsDirectiveHostComponent,
    VisibilityNoneDirective,
  ],
)
class ShouldFailToInjectFromParentView {}

@Component(
  selector: 'visibility-local',
  template: '',
)
class VisibilityLocalComponent {}

@Directive(selector: '[injects-visibility-local]')
class InjectsVisibilityLocal {
  final VisibilityLocalComponent host;

  InjectsVisibilityLocal(this.host);
}

@Component(
  selector: 'test',
  template: '<visibility-local injects-visibility-local></visibility-local>',
  directives: [InjectsVisibilityLocal, VisibilityLocalComponent],
)
class ShouldInjectHost {
  @ViewChild(InjectsVisibilityLocal)
  InjectsVisibilityLocal directive;
}

/// This service is exposed through a component that is marked Visibility.none.
/// The test verifies that injectorGet calls in compiler use the service not
/// useExisting token.
abstract class SomeService {
  void foo();
}

@Component(
  selector: 'my-component-with-service-test',
  template: '''
    <child-component-provides-service>
      <div *dirNeedsService></div>
    </child-component-provides-service>
  ''',
  directives: [MyChildComponentProvidesService, MyDirectiveNeedsService],
)
class MyComponentWithServiceTest {}

@Component(
  selector: 'child-component-provides-service',
  providers: [ExistingProvider(SomeService, MyChildComponentProvidesService)],
  template: '<div><ng-content></ng-content></div>',
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
  directives: [InjectsAliasedLocal],
  providers: [
    ExistingProvider(Dependency, ShouldInjectAliasedLocal),
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
  directives: [InjectsVisibilityAllComponent],
  visibility: Visibility.all,
)
class ShouldInjectParentComponent {
  @ViewChild(InjectsVisibilityAllComponent)
  InjectsVisibilityAllComponent child;
}

abstract class Interface {}

const implementations = MultiToken<Interface>();

@Directive(
  selector: '[all]',
  providers: [
    ExistingProvider.forToken(
      implementations,
      VisibilityAllImplementation,
    ),
  ],
  visibility: Visibility.all,
)
class VisibilityAllImplementation implements Interface {}

@Directive(
  selector: '[local]',
  providers: [
    ExistingProvider.forToken(
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
  selector: 'should-inject-multi-token',
  template: '<injects-multi-token local all></injects-multi-token>',
  directives: [
    InjectsMultiToken,
    VisibilityLocalImplementation,
    VisibilityAllImplementation,
  ],
)
class ShouldInjectMultiToken {
  @ViewChild(InjectsMultiToken)
  InjectsMultiToken child;
}

Interface getInterfaceFromImpl(ShouldSupportFactoryProvider impl) => impl;

@Component(
  selector: 'test',
  template: '<should-inject-interface></should-inject-interface>',
  directives: [
    ShouldInjectInterface,
  ],
  providers: [
    FactoryProvider(Interface, getInterfaceFromImpl),
  ],
)
class ShouldSupportFactoryProvider implements Interface {
  @ViewChild(ShouldInjectInterface)
  ShouldInjectInterface child;
}

@Component(
  selector: 'should-inject-interface',
  template: '',
)
class ShouldInjectInterface {
  Interface interface;
  ShouldInjectInterface(this.interface);
}

@Component(
  selector: 'test',
  template: '<should-inject-interface></should-inject-interface>',
  directives: [
    ShouldInjectInterface,
  ],
  providers: [
    ClassProvider(Interface, useClass: ShouldSupportClassProvider),
  ],
)
class ShouldSupportClassProvider implements Interface {
  @ViewChild(ShouldInjectInterface)
  ShouldInjectInterface child;
}
