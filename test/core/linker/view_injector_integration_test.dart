@TestOn('browser')
library angular2.test.core.linker.view_injector_integration_test;

import "package:angular2/testing_internal.dart";
import "package:angular2/src/facade/lang.dart" show isBlank, stringify;
import "package:angular2/core.dart";
import "package:angular2/common.dart";
import 'package:test/test.dart';

const ALL_DIRECTIVES = const [
  SimpleDirective,
  CycleDirective,
  SimpleComponent,
  SomeOtherDirective,
  NeedsDirectiveFromSelf,
  NeedsServiceComponent,
  OptionallyNeedsDirective,
  NeedsComponentFromHost,
  NeedsDirectiveFromHost,
  NeedsDirective,
  NeedsService,
  NeedsAppService,
  NeedsAttribute,
  NeedsAttributeNoType,
  NeedsElementRef,
  NeedsViewContainerRef,
  NeedsTemplateRef,
  OptionallyNeedsTemplateRef,
  DirectiveNeedsChangeDetectorRef,
  PushComponentNeedsChangeDetectorRef,
  NeedsServiceFromHost,
  NeedsAttribute,
  NeedsAttributeNoType,
  NeedsElementRef,
  NeedsViewContainerRef,
  NeedsTemplateRef,
  OptionallyNeedsTemplateRef,
  DirectiveNeedsChangeDetectorRef,
  PushComponentNeedsChangeDetectorRef,
  NeedsHostAppService,
  NgIf,
  NgFor
];
const ALL_PIPES = const [
  PipeNeedsChangeDetectorRef,
  PipeNeedsService,
  PurePipe,
  ImpurePipe,
  DuplicatePipe1,
  DuplicatePipe2
];

@Directive(selector: "[simpleDirective]")
class SimpleDirective {
  @Input("simpleDirective")
  dynamic value = null;
}

@Component(
    selector: "[simpleComponent]", template: "", directives: ALL_DIRECTIVES)
class SimpleComponent {}

class SimpleService {}

@Directive(selector: "[someOtherDirective]")
class SomeOtherDirective {}

@Directive(selector: "[cycleDirective]")
class CycleDirective {
  CycleDirective(CycleDirective self) {}
}

@Directive(selector: "[needsDirectiveFromSelf]")
class NeedsDirectiveFromSelf {
  SimpleDirective dependency;
  NeedsDirectiveFromSelf(@Self() SimpleDirective dependency) {
    this.dependency = dependency;
  }
}

@Directive(selector: "[optionallyNeedsDirective]")
class OptionallyNeedsDirective {
  SimpleDirective dependency;
  OptionallyNeedsDirective(@Self() @Optional() SimpleDirective dependency) {
    this.dependency = dependency;
  }
}

@Directive(selector: "[needsComponentFromHost]")
class NeedsComponentFromHost {
  SimpleComponent dependency;
  NeedsComponentFromHost(@Host() SimpleComponent dependency) {
    this.dependency = dependency;
  }
}

@Directive(selector: "[needsDirectiveFromHost]")
class NeedsDirectiveFromHost {
  SimpleDirective dependency;
  NeedsDirectiveFromHost(@Host() SimpleDirective dependency) {
    this.dependency = dependency;
  }
}

@Directive(selector: "[needsDirective]")
class NeedsDirective {
  SimpleDirective dependency;
  NeedsDirective(SimpleDirective dependency) {
    this.dependency = dependency;
  }
}

@Directive(selector: "[needsService]")
class NeedsService {
  dynamic service;
  NeedsService(@Inject("service") service) {
    this.service = service;
  }
}

@Directive(selector: "[needsAppService]")
class NeedsAppService {
  dynamic service;
  NeedsAppService(@Inject("appService") service) {
    this.service = service;
  }
}

@Component(
    selector: "[needsHostAppService]", template: "", directives: ALL_DIRECTIVES)
class NeedsHostAppService {
  dynamic service;
  NeedsHostAppService(@Host() @Inject("appService") service) {
    this.service = service;
  }
}

@Component(selector: "[needsServiceComponent]", template: "")
class NeedsServiceComponent {
  dynamic service;
  NeedsServiceComponent(@Inject("service") service) {
    this.service = service;
  }
}

@Directive(selector: "[needsServiceFromHost]")
class NeedsServiceFromHost {
  dynamic service;
  NeedsServiceFromHost(@Host() @Inject("service") service) {
    this.service = service;
  }
}

@Directive(selector: "[needsAttribute]")
class NeedsAttribute {
  var typeAttribute;
  var titleAttribute;
  var fooAttribute;
  NeedsAttribute(
      @Attribute("type") String typeAttribute,
      @Attribute("title") String titleAttribute,
      @Attribute("foo") String fooAttribute) {
    this.typeAttribute = typeAttribute;
    this.titleAttribute = titleAttribute;
    this.fooAttribute = fooAttribute;
  }
}

@Directive(selector: "[needsAttributeNoType]")
class NeedsAttributeNoType {
  var fooAttribute;
  NeedsAttributeNoType(@Attribute("foo") fooAttribute) {
    this.fooAttribute = fooAttribute;
  }
}

@Directive(selector: "[needsElementRef]")
class NeedsElementRef {
  var elementRef;
  NeedsElementRef(ElementRef ref) {
    this.elementRef = ref;
  }
}

@Directive(selector: "[needsViewContainerRef]")
class NeedsViewContainerRef {
  var viewContainer;
  NeedsViewContainerRef(ViewContainerRef vc) {
    this.viewContainer = vc;
  }
}

@Directive(selector: "[needsTemplateRef]")
class NeedsTemplateRef {
  var templateRef;
  NeedsTemplateRef(TemplateRef ref) {
    this.templateRef = ref;
  }
}

@Directive(selector: "[optionallyNeedsTemplateRef]")
class OptionallyNeedsTemplateRef {
  var templateRef;
  OptionallyNeedsTemplateRef(@Optional() TemplateRef ref) {
    this.templateRef = ref;
  }
}

@Directive(selector: "[directiveNeedsChangeDetectorRef]")
class DirectiveNeedsChangeDetectorRef {
  ChangeDetectorRef changeDetectorRef;
  DirectiveNeedsChangeDetectorRef(this.changeDetectorRef) {}
}

@Component(
    selector: "[componentNeedsChangeDetectorRef]",
    template: "{{counter}}",
    directives: ALL_DIRECTIVES,
    changeDetection: ChangeDetectionStrategy.OnPush)
class PushComponentNeedsChangeDetectorRef {
  ChangeDetectorRef changeDetectorRef;
  num counter = 0;
  PushComponentNeedsChangeDetectorRef(this.changeDetectorRef) {}
}

@Pipe(name: "purePipe", pure: true)
class PurePipe implements PipeTransform {
  PurePipe() {}
  dynamic transform(dynamic value) {
    return this;
  }
}

@Pipe(name: "impurePipe", pure: false)
class ImpurePipe implements PipeTransform {
  ImpurePipe() {}
  dynamic transform(dynamic value) {
    return this;
  }
}

@Pipe(name: "pipeNeedsChangeDetectorRef")
class PipeNeedsChangeDetectorRef {
  ChangeDetectorRef changeDetectorRef;
  PipeNeedsChangeDetectorRef(this.changeDetectorRef) {}
  dynamic transform(dynamic value) {
    return this;
  }
}

@Pipe(name: "pipeNeedsService")
class PipeNeedsService implements PipeTransform {
  dynamic service;
  PipeNeedsService(@Inject("service") service) {
    this.service = service;
  }
  dynamic transform(dynamic value) {
    return this;
  }
}

@Pipe(name: "duplicatePipe")
class DuplicatePipe1 implements PipeTransform {
  dynamic transform(dynamic value) {
    return this;
  }
}

@Pipe(name: "duplicatePipe")
class DuplicatePipe2 implements PipeTransform {
  dynamic transform(dynamic value) {
    return this;
  }
}

@Component(selector: "root")
class TestComp {}

class Engine {}

@Injectable()
class Car {
  Engine engine;
  Car(Engine engine) {
    this.engine = engine;
  }
}

@Injectable()
class SomeService {}

@InjectorModule(providers: const [Car])
class SomeModuleWithProvider {
  SomeModuleWithProvider() {}
}

@InjectorModule()
class SomeModuleWithDeps {
  SomeService someService;
  SomeModuleWithDeps(this.someService) {}
}

@InjectorModule()
class SomeModuleWithProp {
  @Provides(Engine)
  String a = "aChildValue";
  @Provides("multiProp", multi: true)
  var multiProp = "aMultiValue";
}

ComponentFixture createCompFixture(String template, TestComponentBuilder tcb,
    [Type comp = null]) {
  if (isBlank(comp)) {
    comp = TestComp;
  }
  return tcb
      .overrideView(
          comp,
          new ViewMetadata(
              template: template, directives: ALL_DIRECTIVES, pipes: ALL_PIPES))
      .createFakeAsync(comp);
}

DebugElement createComp(String template, TestComponentBuilder tcb,
    [Type comp = null]) {
  var fixture = createCompFixture(template, tcb, comp);
  fixture.detectChanges();
  return fixture.debugElement;
}

main() {
  TestComponentBuilder tcb;

  group("View Injector", () {
    beforeEachProviders(() => [provide("appService", useValue: "appService")]);
    setUp(() async {
      await inject([TestComponentBuilder], (_tcb) {
        tcb = _tcb;
      });
    });
    group("injection", () {
      test("should instantiate directives that have no dependencies",
          fakeAsync(() {
        var el = createComp("<div simpleDirective>", tcb);
        expect(el.children[0].inject(SimpleDirective),
            new isInstanceOf<SimpleDirective>());
      }));
      test("should instantiate directives that depend on another directive",
          fakeAsync(() {
        var el = createComp("<div simpleDirective needsDirective>", tcb);
        var d = el.children[0].inject(NeedsDirective);
        expect(d, new isInstanceOf<NeedsDirective>());
        expect(d.dependency, new isInstanceOf<SimpleDirective>());
      }));
      test("should instantiate providers that have dependencies with SkipSelf",
          fakeAsync(() {
        var el = createComp(
            "<div simpleDirective><span someOtherDirective></span></div>",
            tcb.overrideProviders(SimpleDirective, [
              provide("injectable1", useValue: "injectable1")
            ]).overrideProviders(SomeOtherDirective, [
              provide("injectable1", useValue: "new-injectable1"),
              provide("injectable2",
                  useFactory: (val) => '''${ val}-injectable2''',
                  deps: [
                    [new InjectMetadata("injectable1"), new SkipSelfMetadata()]
                  ])
            ]));
        expect(el.children[0].children[0].inject("injectable2"),
            "injectable1-injectable2");
      }));
      test("should instantiate providers that have dependencies", fakeAsync(() {
        var providers = [
          provide("injectable1", useValue: "injectable1"),
          provide("injectable2",
              useFactory: (val) => '''${ val}-injectable2''',
              deps: ["injectable1"])
        ];
        var el = createComp("<div simpleDirective></div>",
            tcb.overrideProviders(SimpleDirective, providers));
        expect(el.children[0].inject("injectable2"), "injectable1-injectable2");
      }));
      test("should instantiate viewProviders that have dependencies",
          fakeAsync(() {
        var viewProviders = [
          provide("injectable1", useValue: "injectable1"),
          provide("injectable2",
              useFactory: (val) => '''${ val}-injectable2''',
              deps: ["injectable1"])
        ];
        var el = createComp("<div simpleComponent></div>",
            tcb.overrideViewProviders(SimpleComponent, viewProviders));
        expect(el.children[0].inject("injectable2"), "injectable1-injectable2");
      }));
      test(
          "should instantiate components that depend on viewProviders providers",
          fakeAsync(() {
        var el = createComp(
            "<div needsServiceComponent></div>",
            tcb.overrideViewProviders(NeedsServiceComponent,
                [provide("service", useValue: "service")]));
        expect(el.children[0].inject(NeedsServiceComponent).service, "service");
      }));
      test("should instantiate multi providers", fakeAsync(() {
        var providers = [
          provide("injectable1", useValue: "injectable11", multi: true),
          provide("injectable1", useValue: "injectable12", multi: true)
        ];
        var el = createComp("<div simpleDirective></div>",
            tcb.overrideProviders(SimpleDirective, providers));
        expect(el.children[0].inject("injectable1"),
            ["injectable11", "injectable12"]);
      }));
      test("should instantiate providers lazily", fakeAsync(() {
        var created = false;
        var el = createComp(
            "<div simpleDirective></div>",
            tcb.overrideProviders(SimpleDirective,
                [provide("service", useFactory: () => created = true)]));
        expect(created, isFalse);
        el.children[0].inject("service");
        expect(created, isTrue);
      }));
      test("should instantiate view providers lazily", fakeAsync(() {
        var created = false;
        var el = createComp(
            "<div simpleComponent></div>",
            tcb.overrideViewProviders(SimpleComponent,
                [provide("service", useFactory: () => created = true)]));
        expect(created, isFalse);
        el.children[0].inject("service");
        expect(created, isTrue);
      }));
      test(
          "should not instantiate other directives that depend on viewProviders providers",
          fakeAsync(() {
        expect(
            () => createComp(
                "<div simpleComponent needsService></div>",
                tcb.overrideViewProviders(SimpleComponent,
                    [provide("service", useValue: "service")])),
            throwsWith('No provider for service!'));
      }));
      test(
          "should instantiate directives that depend on providers of other directives",
          fakeAsync(() {
        var el = createComp(
            "<div simpleDirective><div needsService></div></div>",
            tcb.overrideProviders(SimpleDirective,
                [provide("service", useValue: "parentService")]));
        expect(el.children[0].children[0].inject(NeedsService).service,
            "parentService");
      }));
      test(
          "should instantiate directives that depend on providers in a parent view",
          fakeAsync(() {
        var el = createComp(
            "<div simpleDirective><template [ngIf]=\"true\"><div *ngIf=\"true\" needsService></div></template></div>",
            tcb.overrideProviders(SimpleDirective,
                [provide("service", useValue: "parentService")]));
        expect(el.children[0].children[0].inject(NeedsService).service,
            "parentService");
      }));
      test(
          "should instantiate directives that depend on providers of a component",
          fakeAsync(() {
        var el = createComp(
            "<div simpleComponent></div>",
            tcb
                .overrideTemplate(SimpleComponent, "<div needsService></div>")
                .overrideProviders(SimpleComponent,
                    [provide("service", useValue: "hostService")]));
        expect(el.children[0].children[0].inject(NeedsService).service,
            "hostService");
      }));
      test(
          "should instantiate directives that depend on view providers of a component",
          fakeAsync(() {
        var el = createComp(
            "<div simpleComponent></div>",
            tcb
                .overrideTemplate(SimpleComponent, "<div needsService></div>")
                .overrideViewProviders(SimpleComponent,
                    [provide("service", useValue: "hostService")]));
        expect(el.children[0].children[0].inject(NeedsService).service,
            "hostService");
      }));
      test(
          "should instantiate directives in a root embedded view that depend on view providers of a component",
          fakeAsync(() {
        var el = createComp(
            "<div simpleComponent></div>",
            tcb
                .overrideTemplate(
                    SimpleComponent, "<div *ngIf=\"true\" needsService></div>")
                .overrideViewProviders(SimpleComponent,
                    [provide("service", useValue: "hostService")]));
        expect(el.children[0].children[0].inject(NeedsService).service,
            "hostService");
      }));
      test(
          "should instantiate directives that depend on instances in the app injector",
          fakeAsync(() {
        var el = createComp("<div needsAppService></div>", tcb);
        expect(el.children[0].inject(NeedsAppService).service, "appService");
      }));
      test("should not instantiate a directive with cyclic dependencies",
          fakeAsync(() {
        expect(
            () => createComp("<div cycleDirective></div>", tcb),
            throwsWith(
                'Template parse errors:\nCannot instantiate cyclic dependency! '
                'CycleDirective (\"[ERROR ->]<div cycleDirective></div>\"): '
                'TestComp@0:0'));
      }));
      test(
          "should not instantiate a directive in a view that has a host dependency on providers" +
              " of the component", fakeAsync(() {
        expect(
            () => createComp(
                "<div simpleComponent></div>",
                tcb.overrideProviders(SimpleComponent, [
                  provide("service", useValue: "hostService")
                ]).overrideTemplate(
                    SimpleComponent, "<div needsServiceFromHost><div>")),
            throwsWith('''Template parse errors:
No provider for service ("[ERROR ->]<div needsServiceFromHost><div>"): SimpleComponent@0:0'''));
      }));
      test(
          "should not instantiate a directive in a view that has a host dependency on providers" +
              " of a decorator directive", fakeAsync(() {
        expect(
            () => createComp(
                "<div simpleComponent someOtherDirective></div>",
                tcb.overrideProviders(SomeOtherDirective, [
                  provide("service", useValue: "hostService")
                ]).overrideTemplate(
                    SimpleComponent, "<div needsServiceFromHost><div>")),
            throwsWith('''Template parse errors:
No provider for service ("[ERROR ->]<div needsServiceFromHost><div>"): SimpleComponent@0:0'''));
      }));
      test(
          "should not instantiate a directive in a view that has a self dependency on a parent directive",
          fakeAsync(() {
        expect(
            () => createComp(
                "<div simpleDirective><div needsDirectiveFromSelf></div></div>",
                tcb),
            throwsWith('''Template parse errors:
No provider for SimpleDirective ("<div simpleDirective>[ERROR ->]<div needsDirectiveFromSelf></div></div>"): TestComp@0:21'''));
      }));
      test("should instantiate directives that depend on other directives",
          fakeAsync(() {
        var el = createComp(
            "<div simpleDirective><div needsDirective></div></div>", tcb);
        var d = el.children[0].children[0].inject(NeedsDirective);
        expect(d, new isInstanceOf<NeedsDirective>());
        expect(d.dependency, new isInstanceOf<SimpleDirective>());
      }));
      test("should throw when a dependency cannot be resolved", fakeAsync(() {
        expect(() => createComp("<div needsService></div>", tcb),
            throwsWith('No provider for service!'));
      }));
      test("should inject null when an optional dependency cannot be resolved",
          fakeAsync(() {
        var el = createComp("<div optionallyNeedsDirective></div>", tcb);
        var d = el.children[0].inject(OptionallyNeedsDirective);
        expect(d.dependency, null);
      }));
      test("should instantiate directives that depends on the host component",
          fakeAsync(() {
        var el = createComp(
            "<div simpleComponent></div>",
            tcb.overrideTemplate(
                SimpleComponent, "<div needsComponentFromHost></div>"));
        var d = el.children[0].children[0].inject(NeedsComponentFromHost);
        expect(d.dependency, new isInstanceOf<SimpleComponent>());
      }));
      test(
          "should instantiate host views for components that have a @Host dependency ",
          fakeAsync(() {
        var el = createComp("", tcb, NeedsHostAppService);
        expect(el.componentInstance.service, "appService");
      }));
      test(
          "should not instantiate directives that depend on other directives on the host element",
          fakeAsync(() {
        expect(
            () => createComp(
                "<div simpleComponent simpleDirective></div>",
                tcb.overrideTemplate(
                    SimpleComponent, "<div needsDirectiveFromHost></div>")),
            throwsWith('''Template parse errors:
No provider for SimpleDirective ("[ERROR ->]<div needsDirectiveFromHost></div>"): SimpleComponent@0:0'''));
      }));
    });
    group("static attributes", () {
      test("should be injectable", fakeAsync(() {
        var el =
            createComp("<div needsAttribute type=\"text\" title></div>", tcb);
        var needsAttribute = el.children[0].inject(NeedsAttribute);
        expect(needsAttribute.typeAttribute, "text");
        expect(needsAttribute.titleAttribute, "");
        expect(needsAttribute.fooAttribute, null);
      }));
      test("should be injectable without type annotation", fakeAsync(() {
        var el =
            createComp("<div needsAttributeNoType foo=\"bar\"></div>", tcb);
        var needsAttribute = el.children[0].inject(NeedsAttributeNoType);
        expect(needsAttribute.fooAttribute, "bar");
      }));
    });
    group("refs", () {
      test("should inject ElementRef", fakeAsync(() {
        var el = createComp("<div needsElementRef></div>", tcb);
        expect(el.children[0].inject(NeedsElementRef).elementRef.nativeElement,
            el.children[0].nativeElement);
      }));
      test(
          "should inject ChangeDetectorRef of the component's view into the component via a proxy",
          fakeAsync(() {
        var cf = createCompFixture(
            "<div componentNeedsChangeDetectorRef></div>", tcb);
        cf.detectChanges();
        var compEl = cf.debugElement.children[0];
        var comp = compEl.inject(PushComponentNeedsChangeDetectorRef);
        comp.counter = 1;
        cf.detectChanges();
        expect(compEl.nativeElement, hasTextContent("0"));
        comp.changeDetectorRef.markForCheck();
        cf.detectChanges();
        expect(compEl.nativeElement, hasTextContent("1"));
      }));
      test(
          "should inject ChangeDetectorRef of the containing component into directives",
          fakeAsync(() {
        var cf = createCompFixture(
            "<div componentNeedsChangeDetectorRef></div>",
            tcb.overrideTemplate(PushComponentNeedsChangeDetectorRef,
                "{{counter}}<div directiveNeedsChangeDetectorRef></div>"));
        cf.detectChanges();
        var compEl = cf.debugElement.children[0];
        var comp = compEl.inject(PushComponentNeedsChangeDetectorRef);
        comp.counter = 1;
        cf.detectChanges();
        expect(compEl.nativeElement, hasTextContent("0"));
        compEl.children[0]
            .inject(DirectiveNeedsChangeDetectorRef)
            .changeDetectorRef
            .markForCheck();
        cf.detectChanges();
        expect(compEl.nativeElement, hasTextContent("1"));
      }));
      test("should inject ViewContainerRef", fakeAsync(() {
        var el = createComp("<div needsViewContainerRef></div>", tcb);
        expect(
            el.children[0]
                .inject(NeedsViewContainerRef)
                .viewContainer
                .element
                .nativeElement,
            el.children[0].nativeElement);
      }));
      test("should inject TemplateRef", fakeAsync(() {
        var el = createComp(
            "<template needsViewContainerRef needsTemplateRef></template>",
            tcb);
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
      }));
      test("should throw if there is no TemplateRef", fakeAsync(() {
        expect(() => createComp("<div needsTemplateRef></div>", tcb),
            throwsWith('No provider for TemplateRef!'));
      }));
      test(
          "should inject null if there is no TemplateRef when the dependency is optional",
          fakeAsync(() {
        var el = createComp("<div optionallyNeedsTemplateRef></div>", tcb);
        var instance = el.children[0].inject(OptionallyNeedsTemplateRef);
        expect(instance.templateRef, isNull);
      }));
    });
    group("pipes", () {
      test("should instantiate pipes that have dependencies", fakeAsync(() {
        var el = createComp(
            "<div [simpleDirective]=\"true | pipeNeedsService\"></div>",
            tcb.overrideProviders(
                TestComp, [provide("service", useValue: "pipeService")]));
        expect(el.children[0].inject(SimpleDirective).value.service,
            "pipeService");
      }));
      test("should overwrite pipes with later entry in the pipes array",
          fakeAsync(() {
        var el = createComp(
            "<div [simpleDirective]=\"true | duplicatePipe\"></div>", tcb);
        expect(el.children[0].inject(SimpleDirective).value,
            new isInstanceOf<DuplicatePipe2>());
      }));
      test("should inject ChangeDetectorRef into pipes", fakeAsync(() {
        var el = createComp(
            "<div [simpleDirective]=\"true | pipeNeedsChangeDetectorRef\" directiveNeedsChangeDetectorRef></div>",
            tcb);
        var cdRef = el.children[0]
            .inject(DirectiveNeedsChangeDetectorRef)
            .changeDetectorRef;
        expect(el.children[0].inject(SimpleDirective).value.changeDetectorRef,
            cdRef);
      }));
      test("should cache pure pipes", fakeAsync(() {
        var el = createComp(
            "<div [simpleDirective]=\"true | purePipe\"></div><div [simpleDirective]=\"true | purePipe\"></div>" +
                "<div *ngFor=\"let x of [1,2]\" [simpleDirective]=\"true | purePipe\"></div>",
            tcb);
        var purePipe1 = el.children[0].inject(SimpleDirective).value;
        var purePipe2 = el.children[1].inject(SimpleDirective).value;
        var purePipe3 = el.children[2].inject(SimpleDirective).value;
        var purePipe4 = el.children[3].inject(SimpleDirective).value;
        expect(purePipe1, new isInstanceOf<PurePipe>());
        expect(purePipe2, purePipe1);
        expect(purePipe3, purePipe1);
        expect(purePipe4, purePipe1);
      }));
      test("should not cache impure pipes", fakeAsync(() {
        var el = createComp(
            "<div [simpleDirective]=\"true | impurePipe\"></div><div [simpleDirective]=\"true | impurePipe\"></div>" +
                "<div *ngFor=\"let x of [1,2]\" [simpleDirective]=\"true | impurePipe\"></div>",
            tcb);
        var purePipe1 = el.children[0].inject(SimpleDirective).value;
        var purePipe2 = el.children[1].inject(SimpleDirective).value;
        var purePipe3 = el.children[2].inject(SimpleDirective).value;
        var purePipe4 = el.children[3].inject(SimpleDirective).value;
        expect(purePipe1, new isInstanceOf<ImpurePipe>());
        expect(purePipe2, new isInstanceOf<ImpurePipe>());
        expect(purePipe2 != purePipe1, isTrue);
        expect(purePipe3, new isInstanceOf<ImpurePipe>());
        expect(purePipe3 != purePipe1, isTrue);
        expect(purePipe4, new isInstanceOf<ImpurePipe>());
        expect(purePipe4 != purePipe1, isTrue);
      }));
    });
    group("modules", () {
      test("should use the providers of modules (types)", fakeAsync(() {
        var injector = createComp(
                "",
                tcb.overrideProviders(
                    TestComp, [SomeModuleWithProvider, Engine]),
                TestComp)
            .injector;
        expect(injector.get(SomeModuleWithProvider),
            new isInstanceOf<SomeModuleWithProvider>());
        expect(injector.get(Car), new isInstanceOf<Car>());
      }));
      test("should use the providers of modules (providers)", fakeAsync(() {
        var injector = createComp(
                "",
                tcb.overrideProviders(TestComp, [
                  provide(SomeModuleWithProvider,
                      useClass: SomeModuleWithProvider),
                  Engine
                ]),
                TestComp)
            .injector;
        expect(injector.get(SomeModuleWithProvider),
            new isInstanceOf<SomeModuleWithProvider>());
        expect(injector.get(Car), new isInstanceOf<Car>());
      }));
      test("should inject deps into modules", fakeAsync(() {
        var injector = createComp(
                "",
                tcb.overrideProviders(
                    TestComp, [SomeModuleWithDeps, SomeService]),
                TestComp)
            .injector;
        expect(injector.get(SomeModuleWithDeps).someService,
            new isInstanceOf<SomeService>());
      }));
    });
    group("provider properties", () {
      test("should support provider properties", fakeAsync(() {
        var inj = createComp("",
                tcb.overrideProviders(TestComp, [SomeModuleWithProp]), TestComp)
            .injector;
        expect(inj.get(Engine), "aChildValue");
      }));
      test("should support multi providers", fakeAsync(() {
        var inj = createComp(
                "",
                tcb.overrideProviders(TestComp, [
                  SomeModuleWithProp,
                  new Provider("multiProp",
                      useValue: "bMultiValue", multi: true)
                ]),
                TestComp)
            .injector;
        expect(inj.get("multiProp"), ["aMultiValue", "bMultiValue"]);
      }));
      test("should throw if the module is missing when the value is read",
          fakeAsync(() {
        var inj = createComp(
                "",
                tcb.overrideProviders(TestComp, [
                  new Provider(Engine,
                      useProperty: "a", useExisting: SomeModuleWithProp)
                ]),
                TestComp)
            .injector;
        expect(
            () => inj.get(Engine),
            throwsWith(
                'No provider for ${ stringify ( SomeModuleWithProp )}!'));
      }));
    });
  });
}
