import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'misc_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should allow variables in for loops', () async {
    final testBed = NgTestBed(ng.createVarInLoopComponentFactory());
    final testFixture = await testBed.create();
    expect(testFixture.text, '1-hello');
  });

  test('should support updating host element via host attribute', () async {
    final testBed =
        NgTestBed(ng.createHostAttributeFromDirectiveComponentFactory());
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.children.first;
    expect(div.attributes, containsPair('role', 'button'));
  });

  test('should support updating host element via host properties', () async {
    final testBed =
        NgTestBed(ng.createHostPropertyFromDirectiveComponentFactory());
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.children.first;
    expect(div.id, 'one');
    await testFixture.update((component) => component.directive!.id = 'two');
    expect(div.id, 'two');
  });

  test('should allow ViewContainerRef at any bound location', () async {
    final testBed = NgTestBed(ng.createDynamicChildComponentFactory());
    final testFixture = await testBed.create();
    expect(testFixture.text, 'dynamic greet');
  });

  test('should support static attributes', () async {
    final testBed = NgTestBed(ng.createStaticAttributesComponentFactory());
    final testFixture = await testBed.create();
    final needsAttribute = testFixture.assertOnlyInstance.needsAttribute!;
    expect(needsAttribute.typeAttribute, 'text');
    expect(needsAttribute.staticAttribute, '');
    expect(needsAttribute.fooAttribute, null);
  });

  test('should remove script tags from templates', () async {
    final testBed = NgTestBed(ng.createUnsafeComponentFactory());
    final testFixture = await testBed.create();
    expect(testFixture.rootElement.querySelectorAll('script'), isEmpty);
  });

  test('should support named arguments in method calls', () async {
    final testBed = NgTestBed(ng.createNamedArgMethodComponentFactory());
    final testFixture = await testBed.create();
    expect(testFixture.text, 'Hello');
  });

  test('should support named arguments in exported function calls', () async {
    final testBed = NgTestBed(ng.createNamedArgFunctionComponentFactory());
    final testFixture = await testBed.create();
    expect(testFixture.text, 'Hello');
  });
}

@Component(
  selector: 'child-cmp-no-template',
  template: '',
)
class ChildCompNoTemplate {
  String ctxProp = 'hello';
}

@Component(
  selector: 'var-in-loop',
  template: '<template ngFor [ngForOf]="list" let-i>'
      '<child-cmp-no-template #cmp></child-cmp-no-template>'
      '{{i}}-{{cmp.ctxProp}}</template>',
  directives: [ChildCompNoTemplate, NgFor],
)
class VarInLoopComponent {
  static const list = [1];
}

@Directive(
  selector: '[update-host-attributes]',
)
class DirectiveUpdatingHostAttributes {
  @HostBinding('attr.role')
  static const hostRole = 'button';
}

@Component(
  selector: 'directive-host-attributes',
  template: '<div update-host-attributes></div>',
  directives: [DirectiveUpdatingHostAttributes],
)
class HostAttributeFromDirectiveComponent {}

@Directive(
  selector: '[update-host-properties]',
)
class DirectiveUpdatingHostProperties {
  @HostBinding('id')
  String id = 'one';
}

@Component(
  selector: 'directive-host-properties',
  template: '<div update-host-properties></div>',
  directives: [DirectiveUpdatingHostProperties],
)
class HostPropertyFromDirectiveComponent {
  @ViewChild(DirectiveUpdatingHostProperties)
  DirectiveUpdatingHostProperties? directive;
}

@Injectable()
class MyService {
  String greeting = 'hello';
}

@Component(
  selector: 'child-cmp-svc',
  template: '{{ctxProp}}',
)
class ChildCompUsingService {
  late final String ctxProp;

  ChildCompUsingService(MyService service) {
    ctxProp = service.greeting;
  }
}

@Directive(
  selector: 'dynamic-vp',
)
class DynamicViewport {
  late final Future<dynamic> done;

  DynamicViewport(ViewContainerRef vc) {
    final myService = MyService()..greeting = 'dynamic greet';
    final injector = Injector.map({
      MyService: myService,
    }, vc.injector);
    final factoryFuture = Future.value(
      ng.createChildCompUsingServiceFactory(),
    );
    done = factoryFuture.then((componentFactory) =>
        vc.createComponent(componentFactory, 0, injector));
  }
}

@Component(
  selector: 'dynamic-child-component',
  template: '<div><dynamic-vp></dynamic-vp></div>',
  directives: [
    DynamicViewport,
  ],
)
class DynamicChildComponent {}

@Directive(
  selector: '[static]',
)
class NeedsAttribute {
  String? typeAttribute;
  String? staticAttribute;
  String? fooAttribute;

  NeedsAttribute(
      @Attribute('type') this.typeAttribute,
      @Attribute('static') this.staticAttribute,
      @Attribute('foo') this.fooAttribute);
}

@Component(
  selector: 'static-attributes',
  template: '<input static type="text" title>',
  directives: [NeedsAttribute],
)
class StaticAttributesComponent {
  @ViewChild(NeedsAttribute)
  NeedsAttribute? needsAttribute;
}

@Component(
  selector: 'unsafe-component',
  template: '''
<script>alert("Ooops");</script>
<div>
  <script>alert("Ooops");</script>
</div>''',
)
class UnsafeComponent {}

@Component(
  selector: 'named-arg-method-component',
  template: r'''
    {{getName(name: 'Hello')}}
  ''',
)
class NamedArgMethodComponent {
  String? getName({String? name}) => name;
}

String? getName({String? name}) => name;

@Component(
  selector: 'named-arg-function-component',
  template: r'''
    {{getName(name: 'Hello')}}
  ''',
  exports: [getName],
)
class NamedArgFunctionComponent {}
