@TestOn('browser')
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'functional_directive_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should be invoked once', () async {
    final testBed = NgTestBed<TestInvokeOnceComponent>();
    final testFixture = await testBed.create();
    // Force a second change detection cycle to be certain the functional
    // directive is invoked once per view construction, and not once per change
    // detection cycle.
    await testFixture.update();
    final testElement = testFixture.rootElement.querySelector('#test');
    expect(testElement.children, hasLength(1));
  });

  test('should support dependency injection', () async {
    final attributeProvider = AttributeProvider(const {
      'foo': '1',
      'bar': '2',
    });
    final testBed = NgTestBed<TestDependencyInjectionComponent>().addProviders([
      provide(AttributeProvider, useValue: attributeProvider),
    ]);
    final testFixture = await testBed.create();
    final testElement = testFixture.rootElement.querySelector('#test');
    attributeProvider.attributes.forEach((key, value) {
      expect(testElement.attributes, containsPair(key, value));
    });
  });

  test('should support dependency injection via token', () async {
    const attributes = {
      'foo': '1',
      'bar': '2',
    };
    final testBed =
        NgTestBed<TestDependencyInjectionViaTokenComponent>().addProviders([
      provide('attributesForToken', useValue: attributes),
    ]);
    final testFixture = await testBed.create();
    final testElement = testFixture.rootElement.querySelector('#test');
    attributes.forEach((key, value) {
      expect(testElement.attributes, containsPair(key, value));
    });
  });

  test('should support attribute injection', () async {
    final testBed = NgTestBed<TestAttributeInjectionComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, 'hello world');
  });

  test('should apply to projected content', () async {
    final attributeProvider = AttributeProvider({
      'foo': '1',
      'bar': '2',
    });
    final testBed = NgTestBed<TestContentProjectionComponent>().addProviders([
      provide(AttributeProvider, useValue: attributeProvider),
    ]);
    final testFixture = await testBed.create();
    final testElement = testFixture.rootElement.querySelector('#test');
    attributeProvider.attributes.forEach((key, value) {
      expect(testElement.attributes, containsPair(key, value));
    });
  });

  test('should support use as structural directive', () async {
    final testBed = NgTestBed<TestFunctionalStructuralDirectiveComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.rootElement.querySelector('#first'), isNotNull);
    expect(testFixture.rootElement.querySelector('#second'), isNull);
  });

  test("should be invoked after creation of host element's subtree", () async {
    final textRecorder = TextRecorder();
    final testBed = NgTestBed<TestInvocationAfterSubtreeCreationComponent>()
        .addProviders([provide(TextRecorder, useValue: textRecorder)]);
    await testBed.create();
    expect(textRecorder.texts, containsAllInOrder(['Child', 'ParentChild']));
  });

  test('should provide service for injection by children', () async {
    final testBed = NgTestBed<TestProvidesServiceComponent>();
    await testBed.create(); // Fails if directive doesn't provide service.
  });
}

@Directive(selector: '[addChildDiv]')
void addChildDivDirective(Element element) {
  element.append(DivElement());
}

@Component(
  selector: 'test-invoke-once',
  template: '<div id="test" addChildDiv></div>',
  directives: [addChildDivDirective],
)
class TestInvokeOnceComponent {}

@Component(
  selector: 'test-invoke-each-build',
  template: '<div id="test" *ngIf="visible" addChildDiv></div>',
  directives: [addChildDivDirective, NgIf],
)
class TestInvokeEachBuildComponent {
  bool visible = true;
}

@Injectable()
class AttributeProvider {
  final Map<String, String> attributes;

  AttributeProvider(this.attributes);
}

@Directive(selector: '[addAttributes]')
void addAttributesDirective(
  Element element,
  AttributeProvider attributeProvider,
) {
  element.attributes.addAll(attributeProvider.attributes);
}

@Component(
  selector: 'test-dependency-injection',
  template: '<div id="test" addAttributes></div>',
  directives: [addAttributesDirective],
)
class TestDependencyInjectionComponent {}

@Directive(selector: '[addAttributes]')
void addAttributesForTokenDirective(
  Element element,
  @Inject("attributesForToken") Map<String, String> attributes,
) {
  element.attributes.addAll(attributes);
}

@Component(
  selector: 'test-dependency-injection',
  template: '<div id="test" addAttributes></div>',
  directives: [addAttributesForTokenDirective],
)
class TestDependencyInjectionViaTokenComponent {}

@Directive(selector: '[embedText]')
void embedTextDirective(Element element, @Attribute('embedText') String text) {
  element.appendText(text);
}

@Component(
  selector: 'test-attribute-injection',
  template: '<div embedText="hello world"></div>',
  directives: [embedTextDirective],
)
class TestAttributeInjectionComponent {}

@Component(
  selector: 'content-host',
  template: '<ng-content></ng-content>',
)
class ContentHostComponent {}

@Component(
  selector: 'test-content-projection',
  template: '<content-host><div id="test" addAttributes></div></content-host>',
  directives: [addAttributesDirective, ContentHostComponent],
)
class TestContentProjectionComponent {}

@Directive(selector: '[if]')
void ifDirective(
  @Attribute('if') String condition,
  ViewContainerRef viewContainerRef,
  TemplateRef templateRef,
) {
  if (condition == 'true') {
    viewContainerRef.createEmbeddedView(templateRef);
  }
}

@Component(
  selector: 'test-functional-structural-directive',
  template: '''
    <template if="true"><div id="first"></div></template>
    <template if="false"><div id="second"></div></template>
  ''',
  directives: [ifDirective],
)
class TestFunctionalStructuralDirectiveComponent {}

class TextRecorder {
  final _texts = <String>[];

  List<String> get texts => List<String>.unmodifiable(_texts);

  void recordText(String text) => _texts.add(text);
}

@Directive(selector: '[recordText]')
void recordTextDirective(HtmlElement element, TextRecorder textRecorder) {
  textRecorder.recordText(element.text);
}

@Component(
  selector: 'test-invocation-after-subtree-creation',
  template: '''
    <div recordText>
      Parent
      <div recordText>Child</div>
    </div>
  ''',
  directives: [recordTextDirective],
)
class TestInvocationAfterSubtreeCreationComponent {}

@Injectable()
class Service {}

@Directive(selector: '[serviceProvider]', providers: [Service])
void serviceProviderDirective() {}

@Component(
  selector: 'service-consumer',
  template: '',
)
class ServiceConsumerComponent {
  final Service service;
  ServiceConsumerComponent(this.service);
}

@Component(
  selector: 'test-provides-service',
  template: '''
    <div serviceProvider>
      <service-consumer></service-consumer>
    </div>
  ''',
  directives: [serviceProviderDirective, ServiceConsumerComponent],
)
class TestProvidesServiceComponent {}
