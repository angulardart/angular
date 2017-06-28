@Tags(const ['codegen'])
@TestOn('browser')

import 'dart:async';
import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

void main() {
  tearDown(disposeAnyRunningTest);

  group('@ContentChildren', () {
    test('should be inherited', () async {
      TestDerivedComponent testComponent;
      final testBed = new NgTestBed<TestDerivedComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component;
      });
      expect(testComponent.derivedComponent.contentChildren, hasLength(3));
    });

    test('selector should be overriden', () async {
      TestAnnotatedDerivedComponent testComponent;
      final testBed = new NgTestBed<TestAnnotatedDerivedComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component;
      });
      expect(testComponent.derivedComponent.contentChildren, hasLength(2));
    });
  });

  group('@HostBinding', () {
    test('should be inherited', () async {
      final testBed = new NgTestBed<TestDerivedComponent>();
      final testFixture = await testBed.create();
      final hostElement = testFixture.rootElement.querySelector('derived');
      expect(hostElement.attributes, containsPair('title', 'inherited'));
    });

    test('implementation should be overriden', () async {
      final testBed = new NgTestBed<TestOverrideComponent>();
      final testFixture = await testBed.create();
      final hostElement = testFixture.rootElement.querySelector('override');
      expect(hostElement.attributes, containsPair('title', 'overridden'));
    });

    test('should allow multiple bindings to inherited property', () async {
      final testBed = new NgTestBed<TestAnnotatedDerivedComponent>();
      final testFixture = await testBed.create();
      final hostElement =
          testFixture.rootElement.querySelector('annotated-derived');
      expect(hostElement.attributes, containsPair('title', 'inherited'));
      expect(hostElement.attributes, containsPair('id', 'inherited'));
    });
  });

  group('@HostListener', () {
    test('should be inherited', () async {
      final testBed = new NgTestBed<TestDerivedComponent>();
      final testFixture = await testBed.create()
        ..rootElement
            .querySelector('derived')
            .dispatchEvent(new MouseEvent('click'));
      await testFixture.update((component) {
        expect(component.derivedComponent.clickMessage, 'Original message');
      });
    });

    test('implementation should be overriden', () async {
      final testBed = new NgTestBed<TestOverrideComponent>();
      final testFixture = await testBed.create()
        ..rootElement
            .querySelector('override')
            .dispatchEvent(new MouseEvent('click'));
      await testFixture.update((component) {
        expect(component.derivedComponent.clickMessage, 'Overridden message');
      });
    });
  });

  group('@Input', () {
    test('should be inherited', () async {
      TestDerivedComponent testComponent;
      final testBed = new NgTestBed<TestDerivedComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component..input = 'Hello';
      });
      expect(testComponent.derivedComponent.input, 'Hello');
    });

    test('implementation should be overridden', () async {
      TestOverrideComponent testComponent;
      final testBed = new NgTestBed<TestOverrideComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component..input = 'Hello';
      });
      expect(testComponent.derivedComponent.input, 'Hello!');
    });
  });

  group('@Output', () {
    test('should be inherited', () async {
      TestDerivedComponent testComponent;
      final testBed = new NgTestBed<TestDerivedComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component..derivedComponent.dispatchOutput('Bye');
      });
      expect(testComponent.receivedOutput, 'Bye');
    });

    test('implementation should be overridden', () async {
      TestOverrideComponent testComponent;
      final testBed = new NgTestBed<TestOverrideComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component..derivedComponent.dispatchOutput('Bye');
      });
      expect(testComponent.receivedOutput, 'Bye!');
    });
  });

  group('@ViewChildren', () {
    test('should be inherited', () async {
      TestDerivedComponent testComponent;
      final testBed = new NgTestBed<TestDerivedComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component;
      });
      expect(testComponent.derivedComponent.viewChildren, hasLength(3));
    });

    test('selector should be overriden', () async {
      TestAnnotatedDerivedComponent testComponent;
      final testBed = new NgTestBed<TestAnnotatedDerivedComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component;
      });
      expect(testComponent.derivedComponent.viewChildren, hasLength(2));
    });
  });

  test('Component should inherit metadata from Directive', () async {
    final testBed = new NgTestBed<TestDirectiveDerivedComponent>();
    final testFixture =
        await testBed.create(beforeChangeDetection: (component) {
      component.input = 'Hello!';
    });
    expect(testFixture.text, 'Hello!');
  });
}

/// Base component from which all other components will be derived for testing.
@Component(
  selector: 'root',
  template: '',
)
class RootComponent {
  final StreamController<String> _outputController =
      new StreamController<String>();

  String clickMessage;

  @HostBinding()
  String title = 'inherited';

  @HostListener('click')
  void onClick() => clickMessage = 'Original message';

  @Input()
  String input;

  @Output()
  Stream<String> get output => _outputController.stream;

  @ContentChildren(QueryTargetComponent)
  QueryList<QueryTargetComponent> contentChildren;

  @ViewChildren(QueryTargetComponent)
  QueryList<QueryTargetComponent> viewChildren;

  void dispatchOutput(String outputData) {
    _outputController.add(outputData);
  }
}

/// Tests inherited metadata.
@Component(
  selector: 'derived',
  template: '''
    <ng-content></ng-content>
    <query-target></query-target>
    <query-target #view></query-target>
    <query-target #view></query-target>''',
  directives: const [QueryTargetComponent],
)
class DerivedComponent extends RootComponent {}

@Component(
  selector: 'query-target',
  template: '',
)
class QueryTargetComponent {}

@Component(
  selector: 'test-derived',
  template: '''
    <derived
        [input]="input"
        (output)="receivedOutput = \$event">
      <query-target></query-target>
      <query-target #content></query-target>
      <query-target #content></query-target>
    </derived>''',
  directives: const [DerivedComponent, QueryTargetComponent],
)
class TestDerivedComponent {
  @ViewChild(DerivedComponent)
  DerivedComponent derivedComponent;

  String input;
  String receivedOutput;
}

/// Tests overriding inherited metadata implementations.
@Component(
  selector: 'override',
  template: '',
)
class OverrideComponent extends RootComponent {
  String get title => 'overridden';

  void onClick() {
    clickMessage = 'Overridden message';
  }

  set input(String value) {
    super.input = '$value!';
  }

  Stream<String> get output => super.output.map((data) => '$data!');
}

@Component(
  selector: 'test-override',
  template: '''
    <override
        [input]="input"
        (output)="receivedOutput = \$event">
    </override>''',
  directives: const [OverrideComponent],
)
class TestOverrideComponent {
  @ViewChild(OverrideComponent)
  OverrideComponent derivedComponent;

  String input;
  String receivedOutput;
}

/// Tests annotating fields already annotated in the base component.
@Component(
  selector: 'annotated-derived',
  template: '''
    <query-target></query-target>
    <query-target #view></query-target>
    <query-target #view></query-target>''',
  directives: const [QueryTargetComponent],
)
class AnnotatedDerivedComponent extends RootComponent {
  @HostBinding('id')
  String get title => super.title;

  @ContentChildren('content')
  set contentChildren(QueryList<QueryTargetComponent> value) {
    super.contentChildren = value;
  }

  @ViewChildren('view')
  set viewChildren(QueryList<QueryTargetComponent> value) {
    super.viewChildren = value;
  }
}

@Component(
  selector: 'test-redefine',
  template: '''
    <annotated-derived>
      <query-target></query-target>
      <query-target #content></query-target>
      <query-target #content></query-target>
    </annotated-derived>''',
  directives: const [AnnotatedDerivedComponent, QueryTargetComponent],
)
class TestAnnotatedDerivedComponent {
  @ViewChild(AnnotatedDerivedComponent)
  AnnotatedDerivedComponent derivedComponent;
}

@Directive(
  selector: 'base',
)
class BaseDirective {
  @Input()
  String input;
}

@Component(
  selector: 'directive-derived',
  template: '<div>{{input}}</div>',
)
class DirectiveDerivedComponent extends BaseDirective {}

@Component(
  selector: 'test-directive-derived',
  template: '<directive-derived [input]="input"></directive-derived>',
  directives: const [DirectiveDerivedComponent],
)
class TestDirectiveDerivedComponent {
  String input;
}
