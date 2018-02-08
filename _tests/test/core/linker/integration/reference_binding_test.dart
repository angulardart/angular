@TestOn('browser')

import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/debug/debug_node.dart';

import 'reference_binding_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should assign a component to a ref-', () async {
    final testBed = new NgTestBed<ComponentReferenceBindingComponent>();
    final testFixture = await testBed.create();
    final child = getDebugNode(testFixture.rootElement.querySelector('child'));
    expect(child.getLocal('alice'), new isInstanceOf<ChildComponent>());
  });

  test('should assign a directive to a ref-', () async {
    final testBed = new NgTestBed<DirectiveReferenceBindingComponent>();
    final testFixture = await testBed.create();
    final div = getDebugNode(testFixture.rootElement.firstChild.firstChild);
    expect(div.getLocal('localdir'), new isInstanceOf<ExportDir>());
  });

  test('should assign an element to a ref-', () async {
    final testBed = new NgTestBed<ElementReferenceBindingComponent>();
    final testFixture = await testBed.create();
    final div = getDebugNode(testFixture.rootElement.children.first);
    expect(div.getLocal('alice'), new isInstanceOf<DivElement>());
  });

  test('should be accessible in bindings before declaration', () async {
    final testBed = new NgTestBed<UseRefBeforeDeclarationComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, 'hello|hello|hello');
  });

  test('should assign two component instances each with a ref-', () async {
    final testBed = new NgTestBed<TwoComponentReferencesComponent>();
    final testFixture = await testBed.create();
    final p = getDebugNode(testFixture.rootElement.children.first);
    expect(p.getLocal('alice'), new isInstanceOf<ChildComponent>());
    expect(p.getLocal('bob'), new isInstanceOf<ChildComponent>());
    expect(p.getLocal('alice'), isNot(p.getLocal('bob')));
  });

  test('should support ref- shorthand syntax #', () async {
    final testBed = new NgTestBed<ShorthandRefComponent>();
    final testFixture = await testBed.create();
    final child = getDebugNode(testFixture.rootElement.querySelector('child'));
    expect(child.getLocal('alice'), new isInstanceOf<ChildComponent>());
  });

  test('should be case sensitive', () async {
    final testBed = new NgTestBed<CaseSensitiveRefComponent>();
    final testFixture = await testBed.create();
    final child = getDebugNode(testFixture.rootElement.querySelector('child'));
    expect(child.getLocal('superAlice'), new isInstanceOf<ChildComponent>());
    expect(child.getLocal('superalice'), isNull);
  });
}

@Injectable()
class MyService {
  String greeting = 'hello';
}

@Component(
  selector: 'child',
  template: '{{value}}',
  viewProviders: const [
    MyService,
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ChildComponent {
  String value;

  ChildComponent(MyService service) {
    value = service.greeting;
  }
}

@Component(
  selector: 'component-reference-binding',
  template: '<p><child #alice></child></p>',
  directives: const [ChildComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ComponentReferenceBindingComponent {}

@Directive(
  selector: '[export-dir]',
  exportAs: 'dir',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ExportDir {}

@Component(
  selector: 'directive-reference-binding',
  template: '<div><div export-dir #localdir="dir"></div></div>',
  directives: const [ExportDir],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DirectiveReferenceBindingComponent {}

@Component(
  selector: 'element-reference-binding',
  template: '<div><div #alice><i>Hello</i></div></div>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ElementReferenceBindingComponent {}

@Component(
  selector: 'use-ref-before-declaration',
  template: '<template [ngIf]="true">{{alice.value}}</template>'
      '|{{alice.value}}|<child #alice></child>',
  directives: const [
    ChildComponent,
    NgIf,
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class UseRefBeforeDeclarationComponent {}

@Component(
  selector: 'two-component-references',
  template: '<p><child #alice></child><child #bob></child></p>',
  directives: const [ChildComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TwoComponentReferencesComponent {}

@Component(
  selector: 'shorthand-ref',
  template: '<child #alice></child>',
  directives: const [ChildComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ShorthandRefComponent {}

@Component(
  selector: 'case-sensitive-ref',
  template: '<child #superAlice></child>',
  directives: const [ChildComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CaseSensitiveRefComponent {}
