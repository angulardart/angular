import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/core/app.dart';
import 'package:angular/src/devtools.dart';
import 'package:angular_test/angular_test.dart';

import 'component_inspector_test.template.dart' as ng;

void main() {
  debugCheckBindings();
  enableDevTools();

  /// The use of groups in this test is not representative of how they should be
  /// used. A user of the component inspector service should dispose one group
  /// after successfully requesting another, but for the sake of simplicity,
  /// this test uses the same group for all requests.
  final groupName = 'test';

  tearDown(() async {
    await disposeAnyRunningTest();
    // TODO(b/157073968): remove once NgTestBed handles this automatically.
    ComponentInspector.instance.dispose();
  });

  // TODO(b/157073968): remove once NgTestBed handles this automatically.
  void setLegacyApp(Injector injector) {
    App.setLegacyApp(injector.provideType(ApplicationRef));
  }

  group('getComponents', () {
    test('component views', () async {
      final testBed = NgTestBed(ng.createTestComponentViewsFactory());
      await testBed.create(beforeComponentCreated: setLegacyApp);

      final components = ComponentInspector.instance.getComponents(groupName);
      expect(components, hasLength(1));

      var component = components[0];
      expect(component, containsPair('name', 'TestComponentViews'));
      expect(component, containsPair('children', hasLength(1)));
      {
        final components = component['children'] as List<Map<String, Object>>;
        component = components[0];
        expect(component, containsPair('name', 'TestComponentViews1'));
        expect(component, containsPair('children', hasLength(2)));
        {
          final components = component['children'] as List<Map<String, Object>>;
          component = components[0];
          expect(component, containsPair('name', 'TestComponentViews2'));
          expect(component, isNot(contains('children')));

          component = components[1];
          expect(component, containsPair('name', 'TestComponentViews3'));
          expect(component, isNot(contains('children')));
        }
      }
    });

    group('embedded views', () {
      test('conditional', () async {
        final testBed =
            NgTestBed(ng.createTestConditionalEmbeddedViewsFactory());
        final testFixture =
            await testBed.create(beforeComponentCreated: setLegacyApp);

        // Should not return embedded component before it's created.
        var components = ComponentInspector.instance.getComponents(groupName);
        expect(components, hasLength(1));

        var component = components[0];
        expect(component, containsPair('name', 'TestConditionalEmbeddedViews'));
        expect(component, isNot(contains('children')));

        // Should return embedded component after it's created.
        await testFixture.update((component) {
          component.isChildVisible = true;
        });
        components = ComponentInspector.instance.getComponents(groupName);
        expect(components, hasLength(1));

        component = components[0];
        expect(component, containsPair('name', 'TestConditionalEmbeddedViews'));
        expect(component, containsPair('children', hasLength(1)));
        {
          final components = component['children'] as List<Map<String, Object>>;
          component = components[0];
          expect(component, containsPair('name', 'TestEmbeddedViews1'));
          expect(component, isNot(contains('children')));
        }

        // Should not return embedded component after it's destroyed.
        await testFixture.update((component) {
          component.isChildVisible = false;
        });
        components = ComponentInspector.instance.getComponents(groupName);
        expect(components, hasLength(1));

        component = components[0];
        expect(component, containsPair('name', 'TestConditionalEmbeddedViews'));
        expect(component, isNot(contains('children')));
      });

      test('repeated', () async {
        final testBed = NgTestBed(ng.createTestRepeatedEmbeddedViewsFactory());
        final testFixture = await testBed.create(
          beforeComponentCreated: setLegacyApp,
          beforeChangeDetection: (component) {
            component.values = [1, 2, 4];
          },
        );

        // Should return embedded components after they're created.
        var components = ComponentInspector.instance.getComponents(groupName);
        expect(components, hasLength(1));

        var component = components[0];
        expect(component, containsPair('name', 'TestRepeatedEmbeddedViews'));
        expect(component, containsPair('children', hasLength(3)));
        {
          final components = component['children'] as List<Map<String, Object>>;
          for (component in components) {
            expect(component, containsPair('name', 'TestEmbeddedViews1'));
            expect(component, isNot(contains('children')));
          }
        }

        // Should reflect additions to embedded components.
        await testFixture.update((component) {
          component.values.insert(2, 3); // [1, 2, 3, 4];
        });
        components = ComponentInspector.instance.getComponents(groupName);
        expect(components, hasLength(1));

        component = components[0];
        expect(component, containsPair('name', 'TestRepeatedEmbeddedViews'));
        expect(component, containsPair('children', hasLength(4)));
        {
          final components = component['children'] as List<Map<String, Object>>;
          for (component in components) {
            expect(component, containsPair('name', 'TestEmbeddedViews1'));
            expect(component, isNot(contains('children')));
          }
        }

        // Should reflect removals to embedded components.
        await testFixture.update((component) {
          component.values.removeRange(0, 2);
        });
        components = ComponentInspector.instance.getComponents(groupName);
        expect(components, hasLength(1));

        component = components[0];
        expect(component, containsPair('name', 'TestRepeatedEmbeddedViews'));
        expect(component, containsPair('children', hasLength(2)));
        {
          final components = component['children'] as List<Map<String, Object>>;
          for (component in components) {
            expect(component, containsPair('name', 'TestEmbeddedViews1'));
            expect(component, isNot(contains('children')));
          }
        }
      });

      test('transplanted', () async {
        final testBed =
            NgTestBed(ng.createTestTransplantedEmbeddedViewsFactory());
        await testBed.create(beforeComponentCreated: setLegacyApp);

        final components = ComponentInspector.instance.getComponents(groupName);
        expect(components, hasLength(1));

        var component = components[0];
        expect(
            component, containsPair('name', 'TestTransplantedEmbeddedViews'));
        expect(component, containsPair('children', hasLength(1)));
        {
          final components = component['children'] as List<Map<String, Object>>;
          component = components[0];
          expect(component, containsPair('name', 'TestEmbeddedViews2'));
          expect(component, containsPair('children', hasLength(1)));
          {
            final components =
                component['children'] as List<Map<String, Object>>;
            component = components[0];
            expect(component, containsPair('name', 'TestEmbeddedViews1'));
            expect(component, isNot(contains('children')));
          }
        }
      });
    });

    test('host views', () async {
      final testBed = NgTestBed(ng.createTestHostViewsFactory());
      final testFixture =
          await testBed.create(beforeComponentCreated: setLegacyApp);

      // Should not return imperatively loaded component before it's created.
      var components = ComponentInspector.instance.getComponents(groupName);
      expect(components, hasLength(1));

      var component = components[0];
      expect(component, containsPair('name', 'TestHostViews'));
      expect(component, isNot(contains('children')));

      // Should return imperatively loaded component after it's created.
      await testFixture.update((component) {
        component.load();
      });
      components = ComponentInspector.instance.getComponents(groupName);
      expect(components, hasLength(1));

      component = components[0];
      expect(component, containsPair('name', 'TestHostViews'));
      expect(component, containsPair('children', hasLength(1)));
      {
        final components = component['children'] as List<Map<String, Object>>;
        component = components[0];
        expect(component, containsPair('name', 'TestHostViews1'));
        expect(component, isNot(contains('children')));
      }

      // Should not return imperatively loaded component after it's destroyed.
      await testFixture.update((component) {
        component.clear();
      });
      components = ComponentInspector.instance.getComponents(groupName);
      expect(components, hasLength(1));

      component = components[0];
      expect(component, containsPair('name', 'TestHostViews'));
      expect(component, isNot(contains('children')));
    });

    test('projected content', () async {
      final testBed = NgTestBed(ng.createTestProjectedContentFactory());
      await testBed.create(beforeComponentCreated: setLegacyApp);

      final components = ComponentInspector.instance.getComponents(groupName);
      expect(components, hasLength(1));
      var component = components[0];
      expect(component, containsPair('name', 'TestProjectedContent'));
      expect(component, containsPair('children', hasLength(1)));
      {
        final components = component['children'] as List<Map<String, Object>>;
        component = components[0];
        expect(component, containsPair('name', 'TestProjectedContent1'));
        expect(component, containsPair('children', hasLength(3)));
        {
          final components = component['children'] as List<Map<String, Object>>;
          component = components[0];
          expect(component, containsPair('name', 'TestProjectedContent3'));
          expect(component, isNot(contains('children')));

          component = components[1];
          expect(component, containsPair('name', 'TestProjectedContent2'));
          expect(component, isNot(contains('children')));

          component = components[2];
          expect(component, containsPair('name', 'TestProjectedContent5'));
          expect(component, containsPair('children', hasLength(1)));
          {
            final components =
                component['children'] as List<Map<String, Object>>;
            component = components[0];
            expect(component, containsPair('name', 'TestProjectedContent4'));
            expect(component, isNot(contains('children')));
          }
        }
      }
    });
  });

  group('getComponentInputs', () {
    // Returns the ID of the first child component in the app.
    int firstChildComponentId() {
      final components = ComponentInspector.instance.getComponents(groupName);
      final component = components.first;
      final children = component['children'] as List<Map<String, Object>>;
      final child = children.first;
      return child['id'] as int;
    }

    test('no inputs', () async {
      final testBed = NgTestBed(ng.createTestUsedInputsFactory());
      await testBed.create(beforeComponentCreated: setLegacyApp);

      final components = ComponentInspector.instance.getComponents(groupName);
      final component = components.first;
      final id = component['id'] as int;

      final inputs = ComponentInspector.instance.getComponentInputs(id);
      expect(inputs, isEmpty);
    });

    test('omits unused inputs', () async {
      final testBed = NgTestBed(ng.createTestUnusedInputsFactory());
      await testBed.create(beforeComponentCreated: setLegacyApp);

      final id = firstChildComponentId();
      final inputs = ComponentInspector.instance.getComponentInputs(id);
      expect(inputs, isEmpty);
    });

    test('omits inputs until set', () async {
      final testBed = NgTestBed(ng.createTestUsedInputsFactory());
      final testFixture =
          await testBed.create(beforeComponentCreated: setLegacyApp);

      final id = firstChildComponentId();
      var inputs = ComponentInspector.instance.getComponentInputs(id);
      expect(inputs, isEmpty);

      await testFixture.update((component) {
        component.title = 'Hello!';
      });

      inputs = ComponentInspector.instance.getComponentInputs(id);
      expect(inputs, hasLength(1));
      expect(inputs, containsPair('name', 'Hello!'));

      await testFixture.update((component) {
        component.numbers = [1, 2, 3];
      });

      inputs = ComponentInspector.instance.getComponentInputs(id);
      expect(inputs, hasLength(2));
      expect(inputs, containsPair('name', 'Hello!'));
      expect(inputs, containsPair('data', [1, 2, 3]));
    });

    test('updates inputs when changed', () async {
      final testBed = NgTestBed(ng.createTestUsedInputsFactory());
      final testFixture = await testBed.create(
        beforeComponentCreated: setLegacyApp,
        beforeChangeDetection: (component) {
          component.title = 'Hello!';
        },
      );

      final id = firstChildComponentId();
      var inputs = ComponentInspector.instance.getComponentInputs(id);
      expect(inputs, {'name': 'Hello!'});

      await testFixture.update((component) {
        component.title = 'Goodbye.';
      });

      inputs = inputs = ComponentInspector.instance.getComponentInputs(id);
      expect(inputs, {'name': 'Goodbye.'});
    });

    test('records immutable expressions', () async {
      final testBed = NgTestBed(ng.createTestImmutableInputsFactory());
      final testFixture =
          await testBed.create(beforeComponentCreated: setLegacyApp);

      final id = firstChildComponentId();
      final inputs = ComponentInspector.instance.getComponentInputs(id);
      expect(inputs, hasLength(2));
      expect(
        inputs,
        containsPair('name', testFixture.assertOnlyInstance.title),
      );
      expect(
        inputs,
        containsPair('data', testFixture.assertOnlyInstance.numbers),
      );
    });
  });
}

@Component(
  selector: 'test',
  directives: [TestComponentViews1],
  template: '<test-1></test-1>',
)
class TestComponentViews {}

@Component(
  selector: 'test-1',
  directives: [
    TestComponentViews2,
    TestComponentViews3,
  ],
  template: '''
    <test-2></test-2>
    <test-3></test-3>
  ''',
)
class TestComponentViews1 {}

@Component(
  selector: 'test-2',
  template: '',
)
class TestComponentViews2 {}

@Component(
  selector: 'test-3',
  template: '',
)
class TestComponentViews3 {}

@Component(
  selector: 'test',
  directives: [NgIf, TestEmbeddedViews1],
  template: '''
    <test-1 *ngIf="isChildVisible"></test-1>
  ''',
)
class TestConditionalEmbeddedViews {
  var isChildVisible = false;
}

@Component(
  selector: 'test',
  directives: [NgFor, TestEmbeddedViews1],
  template: '''
    <test-1 *ngFor="let _ of values"></test-1>
  ''',
)
class TestRepeatedEmbeddedViews {
  var values = <int>[];
}

@Component(
  selector: 'test-1',
  template: '',
)
class TestEmbeddedViews1 {}

@Component(
  selector: 'test',
  directives: [
    TestEmbeddedViews1,
    TestEmbeddedViews2,
  ],
  template: '''
    <template #templateRef>
      <test-1></test-1>
    </template>
    <test-2 [templateRef]="templateRef"></test-2>
  ''',
)
class TestTransplantedEmbeddedViews {}

@Component(
  selector: 'test-2',
  directives: [NgTemplateOutlet],
  template: '''
    <ng-container *ngTemplateOutlet="templateRef"></ng-container>
  ''',
)
class TestEmbeddedViews2 {
  @Input()
  TemplateRef? templateRef;
}

@Component(
  selector: 'test',
  template: ''',
    <template #viewContainerRef></template>
  ''',
)
class TestHostViews {
  final componentFactory = ng.createTestHostViews1Factory();

  @ViewChild('viewContainerRef', read: ViewContainerRef)
  ViewContainerRef? viewContainerRef;

  void load() {
    viewContainerRef!
      ..clear()
      ..createComponent(componentFactory);
  }

  void clear() {
    viewContainerRef!.clear();
  }
}

@Component(
  selector: 'test-1',
  template: '''
  ''',
)
class TestHostViews1 {}

@Component(
  selector: 'test',
  directives: [
    TestProjectedContent1,
    TestProjectedContent2,
    TestProjectedContent3,
    TestProjectedContent4,
  ],
  template: '''
    <test-1>
      <test-2></test-2>
      <test-3 first></test-3>
      <test-4 nested></test-4>
    </test-1>
  ''',
)
class TestProjectedContent {}

@Component(
  selector: 'test-1',
  directives: [TestProjectedContent5],
  template: '''
    <ng-content select="[first]"></ng-content>
    <ng-content></ng-content>
    <test-5>
      <ng-content select="[nested]"></ng-content>
    </test-5>
  ''',
)
class TestProjectedContent1 {}

@Component(
  selector: 'test-2',
  template: '',
)
class TestProjectedContent2 {}

@Component(
  selector: 'test-3',
  template: '',
)
class TestProjectedContent3 {}

@Component(
  selector: 'test-4',
  template: '',
)
class TestProjectedContent4 {}

@Component(
  selector: 'test-5',
  template: '''
    <ng-content></ng-content>
  ''',
)
class TestProjectedContent5 {}

@Component(
  selector: 'test-inputs',
  template: '',
)
class TestInputs {
  @Input()
  String? name;

  @Input('data')
  List<int>? values;
}

@Component(
  selector: 'test',
  directives: [TestInputs],
  template: '''
    <test-inputs></test-inputs>
  ''',
)
class TestUnusedInputs {}

@Component(
  selector: 'test',
  directives: [TestInputs],
  template: '''
    <test-inputs [name]="title" [data]="numbers"></test-inputs>
  ''',
)
class TestUsedInputs {
  String? title;
  List<int>? numbers;
}

@Component(
  selector: 'test',
  directives: [TestInputs],
  template: '''
    <test-inputs [name]="title" [data]="numbers"></test-inputs>
  ''',
)
class TestImmutableInputs {
  final title = 'Hello!';
  final numbers = [1];
}
