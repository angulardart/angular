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

  test('should assign a component to a reference', () async {
    final testBed = new NgTestBed<ComponentReferenceBindingComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.assertOnlyInstance.child,
        new isInstanceOf<ChildComponent>());
  });

  test('should assign a directive to a reference', () async {
    final testBed = new NgTestBed<DirectiveReferenceBindingComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.assertOnlyInstance.directive,
        new isInstanceOf<ExportDir>());
  });

  test('should assign an element to a reference', () async {
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

  test('should assign two component instances each with a reference', () async {
    final testBed = new NgTestBed<TwoComponentReferencesComponent>();
    final testFixture = await testBed.create();
    final alice = testFixture.assertOnlyInstance.alice;
    final bob = testFixture.assertOnlyInstance.bob;
    expect(alice, new isInstanceOf<ChildComponent>());
    expect(bob, new isInstanceOf<ChildComponent>());
    expect(alice, isNot(bob));
  });

  test('should be case sensitive', () async {
    final testBed = new NgTestBed<CaseSensitiveRefComponent>();
    final testFixture = await testBed.create();
    final caseSensitive = testFixture.assertOnlyInstance.caseSensitive;
    final caseInsensitive = testFixture.assertOnlyInstance.caseInsensitive;
    expect(caseSensitive, new isInstanceOf<ChildComponent>());
    expect(caseInsensitive, isNull);
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
)
class ComponentReferenceBindingComponent {
  @ViewChild('alice')
  ChildComponent child;
}

@Directive(
  selector: '[export-dir]',
  exportAs: 'dir',
)
class ExportDir {}

@Component(
  selector: 'directive-reference-binding',
  template: '<div><div export-dir #localdir="dir"></div></div>',
  directives: const [ExportDir],
)
class DirectiveReferenceBindingComponent {
  @ViewChild('localdir')
  ExportDir directive;
}

@Component(
  selector: 'element-reference-binding',
  template: '<div><div #alice><i>Hello</i></div></div>',
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
)
class UseRefBeforeDeclarationComponent {}

@Component(
  selector: 'two-component-references',
  template: '<p><child #alice></child><child #bob></child></p>',
  directives: const [ChildComponent],
)
class TwoComponentReferencesComponent {
  @ViewChild('alice')
  ChildComponent alice;

  @ViewChild('bob')
  ChildComponent bob;
}

@Component(
  selector: 'case-sensitive-ref',
  template: '<child #superAlice></child>',
  directives: const [ChildComponent],
)
class CaseSensitiveRefComponent {
  @ViewChild('superAlice')
  ChildComponent caseSensitive;

  @ViewChild('superalice')
  ChildComponent caseInsensitive;
}
