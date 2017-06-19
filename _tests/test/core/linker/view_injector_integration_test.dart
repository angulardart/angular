@TestOn('browser')
@Tags(const ['codegen'])

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/debug/debug_node.dart';

void main() {
  group('View Injector', () {
    tearDown(disposeAnyRunningTest);
    group('injection', () {
      test('should instantiate directives that have no dependencies', () async {
        var testBed = new NgTestBed<NoDependencyTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.children[0].inject(SimpleDirective),
            new isInstanceOf<SimpleDirective>());
      });
      test('should instantiate directives that depend on another directive',
          () async {
        var testBed = new NgTestBed<SimpleDependencyTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        var d = el.children[0].inject(NeedsDirective);
        expect(d, new isInstanceOf<NeedsDirective>());
        expect(d.dependency, new isInstanceOf<SimpleDirective>());
      });
      test('should instantiate providers that have dependencies with SkipSelf',
          () async {
        var testBed = new NgTestBed<SkipSelfTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.children[0].children[0].inject('injectable2'),
            'injectable1-injectable2');
      });
      test('should instantiate providers that have dependencies', () async {
        var testBed = new NgTestBed<ProviderDependencyTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.children[0].inject('injectable2'), 'injectable1-injectable2');
      });
      test('should instantiate viewProviders that have dependencies', () async {
        var testBed = new NgTestBed<ViewProviderDependencyTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.children[0].inject('injectable2'), 'injectable1-injectable2');
      });
      test(
          'should instantiate components that depend on '
          'viewProviders providers', () async {
        var testBed = new NgTestBed<ViewProviderProviderTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(
            el.children[0]
                .inject(ViewProviderProviderNeedsServiceComponent)
                .service,
            'service');
      });
      test('should instantiate multi providers', () async {
        var testBed = new NgTestBed<MultiProviderTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.children[0].inject('injectable1'),
            ['injectable11', 'injectable12']);
      });
      test('should instantiate providers lazily', () async {
        _lazilyCreated = false;
        var testBed = new NgTestBed<LazyInitializationTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(_lazilyCreated, false);
        el.children[0].inject('service');
        expect(_lazilyCreated, true);
      });
      test('should instantiate view providers lazily', () async {
        _lazilyCreated = false;
        var testBed = new NgTestBed<ViewProviderLazyInitializationTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(_lazilyCreated, false);
        el.children[0].inject('service');
        expect(_lazilyCreated, true);
      });
      test(
          'should not instantiate other directives '
          'that depend on viewProviders providers', () {
        var testBed = new NgTestBed<ViewProvidersFailTest>();
        expect(
            testBed.create(),
            throwsInAngular(predicate(
                (e) => '$e'.contains('No provider found for service'))));
      });
      test(
          'should instantiate directives that depend '
          'on providers of other directives', () async {
        var testBed = new NgTestBed<NestedDirectiveProvideTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.children[0].children[0].inject(NeedsService).service,
            'parentService');
      });
      test(
          'should instantiate directives that depend '
          'on providers in a parent view', () async {
        var testBed = new NgTestBed<ParentViewProvideTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.children[0].children[0].inject(NeedsService).service,
            'parentService');
      });
      test(
          'should instantiate directives that depend '
          'on providers of a component', () async {
        var testBed = new NgTestBed<DirectiveProviderTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.children[0].children[0].inject(NeedsService).service,
            'hostService');
      });
      test(
          'should instantiate directives that depend '
          'on view providers of a component', () async {
        var testBed = new NgTestBed<DirectiveViewProviderTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.children[0].children[0].inject(NeedsService).service,
            'hostService');
      });
      test(
          'should instantiate directives in a root embedded view '
          'that depend on view providers of a component', () async {
        var testBed = new NgTestBed<DirectiveViewProviderTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.children[0].children[0].inject(NeedsService).service,
            'hostService');
      });
      test(
          'should instantiate directives that depend '
          'on instances in the app injector', () async {
        var testBed = new NgTestBed<AppProviderTest>().addProviders(
            [const Provider('appService', useValue: 'appService')]);
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.children[0].inject(NeedsAppService).service, 'appService');
      });
      test('should instantiate directives that depend on other directives',
          () async {
        var testBed = new NgTestBed<DependOnOtherDirectiveTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        var d = el.children[0].children[0].inject(NeedsDirective);
        expect(d, new isInstanceOf<NeedsDirective>());
        expect(d.dependency, new isInstanceOf<SimpleDirective>());
      });
      test('should throw when a dependency cannot be resolved', () async {
        var testBed = new NgTestBed<ThrowWhenUnresolvedDependencyTest>();
        expect(
            testBed.create(),
            throwsInAngular(predicate(
                (e) => '$e'.contains('No provider found for service'))));
      });
      test('should inject null when an optional dependency cannot be resolved',
          () async {
        var testBed = new NgTestBed<InjectMissingOptionalTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(
            el.children[0].inject(OptionallyNeedsDirective).dependency, isNull);
      });
      test('should instantiate directives that depend on the host component',
          () async {
        var testBed = new NgTestBed<DependOnHostComponentTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        var d = el.children[0].children[0].inject(NeedsComponentFromHost);
        expect(d.dependency, new isInstanceOf<DependOnHostSimpleComponent>());
      });
      test(
          'should instantiate host view for components '
          'that have a @Host dependency', () async {
        var testBed = new NgTestBed<NeedsHostAppService>().addProviders(
            [const Provider('appService', useValue: 'appService')]);
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.componentInstance.service, 'appService');
      });
    });
    group('static attributes', () {
      test('should be injectable', () async {
        var testBed = new NgTestBed<InjectStaticAttributeTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        var needsAttribute = el.children[0].inject(NeedsAttribute);
        expect(needsAttribute.typeAttribute, 'text');
        expect(needsAttribute.titleAttribute, '');
        expect(needsAttribute.fooAttribute, null);
      });
      test('should be injectable without type annotation', () async {
        var testBed = new NgTestBed<InjectStaticAttributeNoTypeTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        var needsAttribute = el.children[0].inject(NeedsAttributeNoType);
        expect(needsAttribute.fooAttribute, 'bar');
      });
    });
    group('refs', () {
      test('should inject ElementRef', () async {
        var testBed = new NgTestBed<InjectElementRefTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.children[0].inject(NeedsElementRef).elementRef.nativeElement,
            el.children[0].nativeElement);
      });
      test(
          'should inject ChangeDetectorRef of the component\'s '
          'view into the component via a proxy', () async {
        var testBed = new NgTestBed<InjectChangeDetectorTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        var comp = el.children[0].inject(PushComponentNeedsChangeDetectorRef);
        await fixture.update((_) {
          comp.counter = 1;
        });
        expect(fixture.text, '0');
        await fixture.update((_) {
          comp.changeDetectorRef.markForCheck();
        });
        expect(fixture.text, '1');
      });
      test(
          'should inject ChangeDetectorRef of the containing '
          'component into directives', () async {
        var testBed = new NgTestBed<InjectChangeDetectorDirectiveTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        var comp =
            el.children[0].inject(PushComponentWithChangeDetectorDirective);
        await fixture.update((_) {
          comp.counter = 1;
        });
        expect(fixture.text, '0');
        await fixture.update((_) {
          el.children[0].children[0]
              .inject(DirectiveNeedsChangeDetectorRef)
              .changeDetectorRef
              .markForCheck();
        });
        expect(fixture.text, '1');
      });
      test('should inject ViewContainerRef', () async {
        var testBed = new NgTestBed<InjectViewContainerRefTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(
            el.children[0]
                .inject(NeedsViewContainerRef)
                .viewContainer
                .element
                .nativeElement,
            el.children[0].nativeElement);
      });
      test('should inject TemplateRef', () async {
        var testBed = new NgTestBed<InjectTemplateRefTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(
            el.childNodes[0]
                .inject(NeedsTemplateRef)
                .templateRef
                .elementRef
                .nativeElement,
            el.childNodes[0]
                .inject(NeedsViewContainerRef)
                .viewContainer
                .element
                .nativeElement);
      });
      test('should throw if there is no TemplateRef', () async {
        var testBed = new NgTestBed<ThrowIfNoTemplateRefTest>();
        expect(
            testBed.create(),
            throwsInAngular(predicate(
                (e) => '$e'.contains('No provider found for TemplateRef'))));
      });
      test(
          'should inject null if there is no TemplateRef '
          'when the dependency is optional', () async {
        var testBed = new NgTestBed<OptionalTemplateRefTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.children[0].inject(OptionallyNeedsTemplateRef).templateRef,
            isNull);
      });
    });
    group('pipes', () {
      test('should instantiate pipes that have dependencies', () async {
        var testBed = new NgTestBed<PipeDependencyTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.children[0].inject(SimpleDirective).value.service,
            'pipeService');
      });
      test('should overwrite pipes with later entry in the pipes array',
          () async {
        var testBed = new NgTestBed<DuplicatePipeTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        expect(el.children[0].inject(SimpleDirective).value,
            new isInstanceOf<DuplicatePipe2>());
      });
      test('should inject ChangeDetectorRef into pipes', () async {
        var testBed = new NgTestBed<PipeChangeDetectorRefTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        var cdRef = el.children[0]
            .inject(DirectiveNeedsChangeDetectorRef)
            .changeDetectorRef;
        expect(el.children[0].inject(SimpleDirective).value.changeDetectorRef,
            cdRef);
      });
      test('should cache pure pipes', () async {
        var testBed = new NgTestBed<CachePurePipesTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        var purePipe1 = el.children[0].inject(SimpleDirective).value;
        var purePipe2 = el.children[1].inject(SimpleDirective).value;
        var purePipe3 = el.children[2].inject(SimpleDirective).value;
        var purePipe4 = el.children[3].inject(SimpleDirective).value;
        expect(purePipe1, new isInstanceOf<PurePipe>());
        expect(purePipe2, purePipe1);
        expect(purePipe3, purePipe1);
        expect(purePipe4, purePipe1);
      });
      test('should not cache impure pipes', () async {
        var testBed = new NgTestBed<NoCacheImpurePipesTest>();
        var fixture = await testBed.create();
        var el = getDebugNode(fixture.rootElement) as DebugElement;
        var impurePipe1 = el.children[0].inject(SimpleDirective).value;
        var impurePipe2 = el.children[1].inject(SimpleDirective).value;
        var impurePipe3 = el.children[2].inject(SimpleDirective).value;
        var impurePipe4 = el.children[3].inject(SimpleDirective).value;
        expect(impurePipe1, new isInstanceOf<ImpurePipe>());
        expect(impurePipe2, new isInstanceOf<ImpurePipe>());
        expect(impurePipe2, isNot(impurePipe1));
        expect(impurePipe3, new isInstanceOf<ImpurePipe>());
        expect(impurePipe3, isNot(impurePipe1));
        expect(impurePipe4, new isInstanceOf<ImpurePipe>());
        expect(impurePipe4, isNot(impurePipe1));
      });
    });
  });
}

@Directive(selector: '[simpleDirective]')
class SimpleDirective {
  @Input('simpleDirective')
  dynamic value;
}

@Directive(selector: '[optionallyNeedsDirective]')
class OptionallyNeedsDirective {
  SimpleDirective dependency;
  OptionallyNeedsDirective(@Self() @Optional() SimpleDirective dependency) {
    this.dependency = dependency;
  }
}

@Directive(selector: '[needsComponentFromHost]')
class NeedsComponentFromHost {
  DependOnHostSimpleComponent dependency;
  NeedsComponentFromHost(@Host() DependOnHostSimpleComponent dependency) {
    this.dependency = dependency;
  }
}

@Directive(selector: '[needsDirective]')
class NeedsDirective {
  SimpleDirective dependency;
  NeedsDirective(SimpleDirective dependency) {
    this.dependency = dependency;
  }
}

@Directive(selector: '[needsService]')
class NeedsService {
  dynamic service;
  NeedsService(@Inject('service') service) {
    this.service = service;
  }
}

@Directive(selector: '[needsAppService]')
class NeedsAppService {
  dynamic service;
  NeedsAppService(@Inject('appService') service) {
    this.service = service;
  }
}

@Component(
  selector: 'needsHostAppService',
  template: '',
)
class NeedsHostAppService {
  dynamic service;
  NeedsHostAppService(@Host() @Inject('appService') service) {
    this.service = service;
  }
}

@Directive(selector: '[needsAttribute]')
class NeedsAttribute {
  var typeAttribute;
  var titleAttribute;
  var fooAttribute;
  NeedsAttribute(
      @Attribute('type') String typeAttribute,
      @Attribute('title') String titleAttribute,
      @Attribute('foo') String fooAttribute) {
    this.typeAttribute = typeAttribute;
    this.titleAttribute = titleAttribute;
    this.fooAttribute = fooAttribute;
  }
}

@Directive(selector: '[needsAttributeNoType]')
class NeedsAttributeNoType {
  var fooAttribute;
  NeedsAttributeNoType(@Attribute('foo') fooAttribute) {
    this.fooAttribute = fooAttribute;
  }
}

@Directive(selector: '[needsElementRef]')
class NeedsElementRef {
  var elementRef;
  NeedsElementRef(ElementRef ref) {
    this.elementRef = ref;
  }
}

@Directive(selector: '[needsViewContainerRef]')
class NeedsViewContainerRef {
  var viewContainer;
  NeedsViewContainerRef(ViewContainerRef vc) {
    this.viewContainer = vc;
  }
}

@Directive(selector: '[needsTemplateRef]')
class NeedsTemplateRef {
  var templateRef;
  NeedsTemplateRef(TemplateRef ref) {
    this.templateRef = ref;
  }
}

@Directive(selector: '[optionallyNeedsTemplateRef]')
class OptionallyNeedsTemplateRef {
  var templateRef;
  OptionallyNeedsTemplateRef(@Optional() TemplateRef ref) {
    this.templateRef = ref;
  }
}

@Directive(selector: '[directiveNeedsChangeDetectorRef]')
class DirectiveNeedsChangeDetectorRef {
  ChangeDetectorRef changeDetectorRef;
  DirectiveNeedsChangeDetectorRef(this.changeDetectorRef);
}

@Component(
    selector: 'componentNeedsChangeDetectorRef',
    template: '{{counter}}',
    changeDetection: ChangeDetectionStrategy.OnPush)
class PushComponentNeedsChangeDetectorRef {
  ChangeDetectorRef changeDetectorRef;
  num counter = 0;
  PushComponentNeedsChangeDetectorRef(this.changeDetectorRef);
}

@Pipe('purePipe', pure: true)
class PurePipe implements PipeTransform {
  PurePipe();
  dynamic transform(dynamic value) {
    return this;
  }
}

@Pipe('impurePipe', pure: false)
class ImpurePipe implements PipeTransform {
  dynamic transform(dynamic value) {
    return this;
  }
}

@Pipe('pipeNeedsChangeDetectorRef')
class PipeNeedsChangeDetectorRef {
  ChangeDetectorRef changeDetectorRef;
  PipeNeedsChangeDetectorRef(this.changeDetectorRef);
  dynamic transform(dynamic value) {
    return this;
  }
}

@Pipe('pipeNeedsService')
class PipeNeedsService implements PipeTransform {
  dynamic service;
  PipeNeedsService(@Inject('service') service) {
    this.service = service;
  }
  dynamic transform(dynamic value) {
    return this;
  }
}

@Pipe('duplicatePipe')
class DuplicatePipe1 implements PipeTransform {
  dynamic transform(dynamic value) {
    return this;
  }
}

@Pipe('duplicatePipe')
class DuplicatePipe2 implements PipeTransform {
  dynamic transform(dynamic value) {
    return this;
  }
}

@Component(
  selector: 'no-dependency-test',
  template: '<div simpleDirective>',
  directives: const [SimpleDirective],
)
class NoDependencyTest {}

@Component(
  selector: 'simple-dependency-test',
  template: '<div simpleDirective needsDirective>',
  directives: const [SimpleDirective, NeedsDirective],
)
class SimpleDependencyTest {}

@Directive(
  selector: '[simpleDirective]',
  providers: const [const Provider('injectable1', useValue: 'injectable1')],
)
class SkipSelfSimpleDirective {}

@Directive(
  selector: '[someOtherDirective]',
  providers: const [
    const Provider('injectable1', useValue: 'new-injectable1'),
    const Provider(
      'injectable2',
      useFactory: skipSelfFactory,
    ),
  ],
)
class SkipSelfSomeOtherDirective {}

String skipSelfFactory(@SkipSelf() @Inject('injectable1') val) =>
    '$val-injectable2';

@Component(
  selector: 'skip-self-test',
  template: '<div simpleDirective><span someOtherDirective></span></div>',
  directives: const [SkipSelfSimpleDirective, SkipSelfSomeOtherDirective],
)
class SkipSelfTest {}

@Component(
    selector: 'provider-dependency-test',
    template: '<div simpleDirective></div>',
    directives: const [ProviderDependencySimpleDirective])
class ProviderDependencyTest {}

@Directive(
  selector: '[simpleDirective]',
  providers: const [
    const Provider('injectable1', useValue: 'injectable1'),
    const Provider(
      'injectable2',
      useFactory: providerDependencyFactory,
    ),
  ],
)
class ProviderDependencySimpleDirective {}

String providerDependencyFactory(@Inject('injectable1') val) =>
    '$val-injectable2';

@Component(
  selector: 'view-provider-dependency-test',
  template: '<simpleComponent></simpleComponent>',
  directives: const [ViewProviderSimpleComponent],
)
class ViewProviderDependencyTest {}

@Component(
  selector: 'simpleComponent',
  template: '',
  viewProviders: const [
    const Provider('injectable1', useValue: 'injectable1'),
    const Provider('injectable2', useFactory: viewProviderDependencyFactory),
  ],
)
class ViewProviderSimpleComponent {}

String viewProviderDependencyFactory(@Inject('injectable1') val) =>
    '$val-injectable2';

@Component(
  selector: 'view-provider-provider-test',
  template: '<needsServiceComponent></needsServiceComponent>',
  directives: const [ViewProviderProviderNeedsServiceComponent],
)
class ViewProviderProviderTest {}

@Component(
  selector: 'needsServiceComponent',
  template: '',
  viewProviders: const [const Provider('service', useValue: 'service')],
)
class ViewProviderProviderNeedsServiceComponent {
  dynamic service;
  ViewProviderProviderNeedsServiceComponent(@Inject('service') service) {
    this.service = service;
  }
}

@Component(
  selector: 'multi-provider-test',
  template: '<div simpleDirective></div>',
  directives: const [MultiProviderSimpleDirective],
)
class MultiProviderTest {}

@Directive(
  selector: '[simpleDirective]',
  providers: const [
    const Provider('injectable1', useValue: 'injectable11', multi: true),
    const Provider('injectable1', useValue: 'injectable12', multi: true),
  ],
)
class MultiProviderSimpleDirective {}

@Component(
  selector: 'lazy-initialization-test',
  template: '<div simpleDirective></div>',
  directives: const [LazyInitializationSimpleDirective],
)
class LazyInitializationTest {}

@Directive(
  selector: '[simpleDirective]',
  providers: const [
    const Provider('service', useFactory: lazyCreationFactory),
  ],
)
class LazyInitializationSimpleDirective {}

var _lazilyCreated = false;
lazyCreationFactory() => _lazilyCreated = true;

@Component(
  selector: 'lazy-initialization-test',
  template: '<simpleComponent></simpleComponent>',
  directives: const [ViewProviderLazyInitializationSimpleComponent],
)
class ViewProviderLazyInitializationTest {}

@Component(
  selector: 'simpleComponent',
  template: '',
  providers: const [
    const Provider('service', useFactory: lazyCreationFactory),
  ],
)
class ViewProviderLazyInitializationSimpleComponent {}

@Component(
  selector: 'view-providers-fail-test',
  template: '<simpleComponent needsService></simpleComponent>',
  directives: const [ViewProvidersFailSimpleComponent, NeedsService],
)
class ViewProvidersFailTest {}

@Component(
  selector: 'simpleComponent',
  template: '',
  viewProviders: const [
    const Provider('service', useValue: 'service'),
  ],
)
class ViewProvidersFailSimpleComponent {}

@Component(
  selector: 'nested-directive-provide-test',
  template: '<div simpleDirective><div needsService></div></div>',
  directives: const [ParentServiceSimpleDirective, NeedsService],
)
class NestedDirectiveProvideTest {}

@Directive(
  selector: '[simpleDirective]',
  providers: const [
    const Provider('service', useValue: 'parentService'),
  ],
)
class ParentServiceSimpleDirective {}

@Component(
  selector: 'parent-view-provide-test',
  template: '<div simpleDirective><template [ngIf]="true">'
      '<div *ngIf="true" needsService></div></template></div>',
  directives: const [ParentServiceSimpleDirective, NeedsService, NgIf],
)
class ParentViewProvideTest {}

@Component(
  selector: 'directive-provider-test',
  template: '<simpleComponent></simpleComponent>',
  directives: const [DirectiveProviderSimpleComponent],
)
class DirectiveProviderTest {}

@Component(
  selector: 'simpleComponent',
  template: '<div needsService></div>',
  directives: const [NeedsService],
  providers: const [
    const Provider('service', useValue: 'hostService'),
  ],
)
class DirectiveProviderSimpleComponent {}

@Component(
  selector: 'directive-provider-test',
  template: '<simpleComponent></simpleComponent>',
  directives: const [DirectiveViewProviderSimpleComponent],
)
class DirectiveViewProviderTest {}

@Component(
  selector: 'simpleComponent',
  template: '<div needsService></div>',
  directives: const [NeedsService],
  viewProviders: const [
    const Provider('service', useValue: 'hostService'),
  ],
)
class DirectiveViewProviderSimpleComponent {}

@Component(
  selector: 'directive-provider-test',
  template: '<simpleComponent></simpleComponent>',
  directives: const [DirectiveEmbeddedViewProviderSimpleComponent],
)
class DirectiveEmbeddedViewProviderTest {}

@Component(
  selector: 'simpleComponent',
  template: '<div *ngIf="true" needsService></div>',
  directives: const [NeedsService, NgIf],
  viewProviders: const [
    const Provider('service', useValue: 'hostService'),
  ],
)
class DirectiveEmbeddedViewProviderSimpleComponent {}

@Component(
  selector: 'app-provider-test',
  template: '<div needsAppService></div>',
  directives: const [NeedsAppService],
)
class AppProviderTest {}

@Component(
  selector: 'depend-on-other-directive-test',
  template: '<div simpleDirective><div needsDirective></div></div>',
  directives: const [SimpleDirective, NeedsDirective],
)
class DependOnOtherDirectiveTest {}

@Component(
  selector: 'throw-when-unresolved-dependency-test',
  template: '<div needsService></div>',
  directives: const [NeedsService],
)
class ThrowWhenUnresolvedDependencyTest {}

@Component(
  selector: 'inject-missing-optional-test',
  template: '<div optionallyNeedsDirective></div>',
  directives: const [OptionallyNeedsDirective],
)
class InjectMissingOptionalTest {}

@Component(
  selector: 'depend-on-host-component-test',
  template: '<simpleComponent></simpleComponent>',
  directives: const [DependOnHostSimpleComponent],
)
class DependOnHostComponentTest {}

@Component(
  selector: 'simpleComponent',
  template: '<div needsComponentFromHost></div>',
  directives: const [NeedsComponentFromHost],
)
class DependOnHostSimpleComponent {}

@Component(
  selector: 'inject-static-attribute-test',
  template: '<div needsAttribute type="text" title></div>',
  directives: const [NeedsAttribute],
)
class InjectStaticAttributeTest {}

@Component(
  selector: 'inject-static-attribute-no-type-test',
  template: '<div needsAttributeNoType foo=\'bar\'></div>',
  directives: const [NeedsAttributeNoType],
)
class InjectStaticAttributeNoTypeTest {}

@Component(
  selector: 'inject-element-ref-test',
  template: '<div needsElementRef></div>',
  directives: const [NeedsElementRef],
)
class InjectElementRefTest {}

@Component(
  selector: 'inject-change-detector-test',
  template:
      '<componentNeedsChangeDetectorRef></componentNeedsChangeDetectorRef>',
  directives: const [PushComponentNeedsChangeDetectorRef],
)
class InjectChangeDetectorTest {}

@Component(
  selector: 'inject-change-detector-directive-test',
  template:
      '<componentNeedsChangeDetectorRef></componentNeedsChangeDetectorRef>',
  directives: const [PushComponentWithChangeDetectorDirective],
)
class InjectChangeDetectorDirectiveTest {}

@Component(
    selector: 'componentNeedsChangeDetectorRef',
    template: '{{counter}}<div directiveNeedsChangeDetectorRef></div>',
    directives: const [DirectiveNeedsChangeDetectorRef],
    changeDetection: ChangeDetectionStrategy.OnPush)
class PushComponentWithChangeDetectorDirective {
  num counter = 0;
  PushComponentWithChangeDetectorDirective();
}

@Component(
  selector: 'inject-view-container-ref-test',
  template: '<div needsViewContainerRef></div>',
  directives: const [NeedsViewContainerRef],
)
class InjectViewContainerRefTest {}

@Component(
  selector: 'inject-template-ref-test',
  template: '<template needsViewContainerRef needsTemplateRef></template>',
  directives: const [NeedsViewContainerRef, NeedsTemplateRef],
)
class InjectTemplateRefTest {}

@Component(
  selector: 'throw-if-no-template-ref-test',
  template: '<div needsTemplateRef></div>',
  directives: const [NeedsTemplateRef],
)
class ThrowIfNoTemplateRefTest {}

@Component(
  selector: 'optional-template-ref-test',
  template: '<div optionallyNeedsTemplateRef></div>',
  directives: const [OptionallyNeedsTemplateRef],
)
class OptionalTemplateRefTest {}

@Component(
  selector: 'pipe-dependency-test',
  template: '<div [simpleDirective]="true | pipeNeedsService"></div>',
  directives: const [SimpleDirective],
  pipes: const [PipeNeedsService],
  providers: const [const Provider('service', useValue: 'pipeService')],
)
class PipeDependencyTest {}

@Component(
  selector: 'duplicate-pipe-test',
  template: '<div [simpleDirective]="true | duplicatePipe"></div>',
  directives: const [SimpleDirective],
  pipes: const [DuplicatePipe1, DuplicatePipe2],
)
class DuplicatePipeTest {}

@Component(
    selector: 'pipe-change-detector-ref-test',
    template: '<div [simpleDirective]="true | pipeNeedsChangeDetectorRef" '
        'directiveNeedsChangeDetectorRef></div>',
    directives: const [SimpleDirective, DirectiveNeedsChangeDetectorRef],
    pipes: const [PipeNeedsChangeDetectorRef])
class PipeChangeDetectorRefTest {}

@Component(
    selector: 'cache-pure-pipes-test',
    template: '<div [simpleDirective]="true | purePipe"></div>'
        '<div [simpleDirective]="true | purePipe"></div>'
        '<div *ngFor="let x of [1,2]" [simpleDirective]="true | purePipe">'
        '</div>',
    directives: const [SimpleDirective, NgFor],
    pipes: const [PurePipe])
class CachePurePipesTest {}

@Component(
    selector: 'no-cache-impure-pipes-test',
    template: '<div [simpleDirective]="true | impurePipe"></div>'
        '<div [simpleDirective]="true | impurePipe"></div>'
        '<div *ngFor="let x of [1,2]" [simpleDirective]="true | impurePipe">'
        '</div>',
    directives: const [SimpleDirective, NgFor],
    pipes: const [ImpurePipe])
class NoCacheImpurePipesTest {}
