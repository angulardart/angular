@Tags(const ['codegen'])
@TestOn('browser')

import 'dart:async';

import 'package:angular2/angular2.dart';
import 'package:angular2/src/debug/debug_node.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
  tearDown(disposeAnyRunningTest);

  test('should allow variables in for loops', () async {
    final testBed = new NgTestBed<VarInLoopComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, '1-hello');
  });

  test('should support updating host element via host attribute', () async {
    final testBed = new NgTestBed<HostAttributeFromDirectiveComponent>();
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.children.first;
    expect(div.attributes, containsPair('role', 'button'));
  });

  test('should support updating host element via host properties', () async {
    final testBed = new NgTestBed<HostPropertyFromDirectiveComponent>();
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.children.first;
    final directive = getDebugNode(div).inject(DirectiveUpdatingHostProperties);
    expect(div.id, 'one');
    await testFixture.update((_) => directive.id = 'two');
    expect(div.id, 'two');
  });

  test('should allow ViewContainerRef at any bound location', () async {
    final testBed = new NgTestBed<DynamicChildComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, 'dynamic greet');
  });

  test('should support static attributes', () async {
    final testBed = new NgTestBed<StaticAttributesComponent>();
    final testFixture = await testBed.create();
    final input = testFixture.rootElement.children.first;
    final needsAttribute = getDebugNode(input).inject(NeedsAttribute);
    expect(needsAttribute.typeAttribute, 'text');
    expect(needsAttribute.staticAttribute, '');
    expect(needsAttribute.fooAttribute, null);
  });

  test('should remove script tags from templates', () async {
    final testBed = new NgTestBed<UnsafeComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.rootElement.querySelectorAll('script'), isEmpty);
  });
}

@Component(selector: 'child-cmp-no-template', template: '')
class ChildCompNoTemplate {
  String ctxProp = 'hello';
}

@Component(
  selector: 'var-in-loop',
  template: '<template ngFor [ngForOf]="[1]" let-i>'
      '<child-cmp-no-template #cmp></child-cmp-no-template>'
      '{{i}}-{{cmp.ctxProp}}</template>',
  directives: const [ChildCompNoTemplate, NgFor],
)
class VarInLoopComponent {}

@Directive(selector: '[update-host-attributes]', host: const {'role': 'button'})
class DirectiveUpdatingHostAttributes {}

@Component(
  selector: 'directive-host-attributes',
  template: '<div update-host-attributes></div>',
  directives: const [DirectiveUpdatingHostAttributes],
)
class HostAttributeFromDirectiveComponent {}

@Directive(selector: '[update-host-properties]', host: const {'[id]': 'id'})
class DirectiveUpdatingHostProperties {
  String id = 'one';
}

@Component(
  selector: 'directive-host-properties',
  template: '<div update-host-properties></div>',
  directives: const [DirectiveUpdatingHostProperties],
)
class HostPropertyFromDirectiveComponent {}

@Injectable()
class MyService {
  String greeting = 'hello';
}

@Component(selector: 'child-cmp-svc', template: '{{ctxProp}}')
class ChildCompUsingService {
  String ctxProp;

  ChildCompUsingService(MyService service) {
    ctxProp = service.greeting;
  }
}

@Directive(selector: 'dynamic-vp')
class DynamicViewport {
  Future<dynamic> done;

  DynamicViewport(ViewContainerRef vc, ComponentResolver compiler) {
    final myService = new MyService()..greeting = 'dynamic greet';
    final injector = new Injector.map({
      MyService: myService,
    }, vc.injector);
    done = compiler.resolveComponent(ChildCompUsingService).then(
        (componentFactory) =>
            vc.createComponent(componentFactory, 0, injector));
  }
}

@Component(
  selector: 'dynamic-child-component',
  template: '<div><dynamic-vp></dynamic-vp></div>',
  directives: const [
    DynamicViewport,
  ],
)
class DynamicChildComponent {}

@Directive(selector: '[static]')
class NeedsAttribute {
  var typeAttribute;
  var staticAttribute;
  var fooAttribute;

  NeedsAttribute(
      @Attribute('type') this.typeAttribute,
      @Attribute('static') this.staticAttribute,
      @Attribute('foo') this.fooAttribute);
}

@Component(
  selector: 'static-attributes',
  template: '<input static type="text" title>',
  directives: const [NeedsAttribute],
)
class StaticAttributesComponent {}

@Component(
  selector: 'unsafe-component',
  template: '''
<script>alert("Ooops");</script>
<div>
  <script>alert("Ooops");</script>
</div>''',
)
class UnsafeComponent {}
