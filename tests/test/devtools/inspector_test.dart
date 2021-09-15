import 'dart:html' as html;

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/devtools.dart';
import 'package:angular_test/angular_test.dart';

import 'inspector_test.template.dart' as ng;

void main() {
  debugCheckBindings();
  enableDevTools();

  // The use of groups in this test is not representative of how they should be
  // used. A user of the component inspector service should dispose one group
  // after successfully requesting another, but for the sake of simplicity, this
  // test uses the same group for all requests.
  final groupName = 'test';

  tearDown(disposeAnyRunningTest);

  // TODO(b/194920649): remove.
  group('getComponents', () {
    test('component views', () async {
      final testBed = NgTestBed(ng.createTestComponentViewsFactory());
      await testBed.create();

      final components = Inspector.instance.getComponents(groupName);
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
        final testFixture = await testBed.create();

        // Should not return embedded component before it's created.
        var components = Inspector.instance.getComponents(groupName);
        expect(components, hasLength(1));

        var component = components[0];
        expect(component, containsPair('name', 'TestConditionalEmbeddedViews'));
        expect(component, isNot(contains('children')));

        // Should return embedded component after it's created.
        await testFixture.update((component) {
          component.isChildVisible = true;
        });
        components = Inspector.instance.getComponents(groupName);
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
        components = Inspector.instance.getComponents(groupName);
        expect(components, hasLength(1));

        component = components[0];
        expect(component, containsPair('name', 'TestConditionalEmbeddedViews'));
        expect(component, isNot(contains('children')));
      });

      test('repeated', () async {
        final testBed = NgTestBed(ng.createTestRepeatedEmbeddedViewsFactory());
        final testFixture = await testBed.create(
          beforeChangeDetection: (component) {
            component.values = [1, 2, 4];
          },
        );

        // Should return embedded components after they're created.
        var components = Inspector.instance.getComponents(groupName);
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
        components = Inspector.instance.getComponents(groupName);
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
        components = Inspector.instance.getComponents(groupName);
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
        await testBed.create();

        final components = Inspector.instance.getComponents(groupName);
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
      final testFixture = await testBed.create();

      // Should not return imperatively loaded component before it's created.
      var components = Inspector.instance.getComponents(groupName);
      expect(components, hasLength(1));

      var component = components[0];
      expect(component, containsPair('name', 'TestHostViews'));
      expect(component, isNot(contains('children')));

      // Should return imperatively loaded component after it's created.
      await testFixture.update((component) {
        component.load();
      });
      components = Inspector.instance.getComponents(groupName);
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
      components = Inspector.instance.getComponents(groupName);
      expect(components, hasLength(1));

      component = components[0];
      expect(component, containsPair('name', 'TestHostViews'));
      expect(component, isNot(contains('children')));
    });

    test('projected content', () async {
      final testBed = NgTestBed(ng.createTestProjectedContentFactory());
      await testBed.create();

      final components = Inspector.instance.getComponents(groupName);
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

    group('external content root', () {
      late html.Element container;
      late NgTestFixture<TestExternalContentRoots> testFixture;

      setUp(() async {
        container = createContentRoot();
        final testBed = NgTestBed(ng.createTestExternalContentRootsFactory());
        testFixture = await testBed.create();
      });

      tearDown(() {
        container.remove();
      });

      test('with no components', () async {
        await testFixture.update((component) {
          component.initExternalContent(
            container,
            component.noComponentTemplateRef!,
          );
        });

        final components = Inspector.instance.getComponents(groupName);
        expect(components, hasLength(1));
      });

      test('with one component', () async {
        await testFixture.update((component) {
          component.initExternalContent(
            container,
            component.oneComponentTemplateRef!,
          );
        });

        final components = Inspector.instance.getComponents(groupName);
        expect(components, hasLength(2));
      });

      test('with multiple components', () async {
        await testFixture.update((component) {
          component.initExternalContent(
            container,
            component.multipleComponentTemplateRef!,
          );
        });

        final components = Inspector.instance.getComponents(groupName);
        expect(components, hasLength(3));
      });
    });

    test('multiple external content roots', () async {
      final containerOne = createContentRoot();
      final containerTwo = createContentRoot();
      final testBed = NgTestBed(ng.createTestExternalContentRootsFactory());
      final testFixture = await testBed.create();

      await testFixture.update((component) {
        component
          ..initExternalContent(
            containerOne,
            component.oneComponentTemplateRef!,
          )
          ..initExternalContent(
            containerTwo,
            component.oneComponentTemplateRef!,
          );
      });

      final components = Inspector.instance.getComponents(groupName);
      expect(components, hasLength(3));
    });

    test('is coalesced by existing content root', () async {
      final testBed = NgTestBed(ng.createTestExternalContentRootsFactory());
      final testFixture = await testBed.create();
      final container = createContentRoot(parent: testFixture.rootElement);

      await testFixture.update((component) {
        component.initExternalContent(
          container,
          component.oneComponentTemplateRef!,
        );
      });

      final components = Inspector.instance.getComponents(groupName);
      expect(components, hasLength(1));
    });

    test('coalesces existing content roots', () async {
      final testBed = NgTestBed(ng.createTestExternalContentRootsFactory());
      final testFixture = await testBed.create();
      final childContainer = html.DivElement();
      final parentContainer = testFixture.rootElement.parent!
        ..append(childContainer);
      registerContentRoot(childContainer);
      registerContentRoot(parentContainer);

      await testFixture.update((component) {
        component
          ..initExternalContent(
            parentContainer,
            component.oneComponentTemplateRef!,
          )
          ..initExternalContent(
            childContainer,
            component.oneComponentTemplateRef!,
          );
      });

      final components = Inspector.instance.getComponents(groupName);
      expect(components, hasLength(3));
    });
  });

  /// Returns the root node of the inspected app for testing.
  InspectorNode rootNode() {
    return anonymize(Inspector.instance.getNodes(groupName).single);
  }

  InspectorDirective.defaultIdForTesting = -1;

  group('getNodes', () {
    test('component views', () async {
      final testBed = NgTestBed(ng.createTestComponentViewsFactory());
      await testBed.create();

      expect(
        rootNode(),
        InspectorNode((b) => b
          ..component.name = '$TestComponentViews'
          ..children.replace([
            InspectorNode((b) => b
              ..component.name = '$TestComponentViews1'
              ..children.replace([
                InspectorNode((b) => b.component.name = '$TestComponentViews2'),
                InspectorNode((b) => b.component.name = '$TestComponentViews3'),
              ])),
          ])),
      );
    });

    group('embedded views', () {
      test('conditional', () async {
        final testBed =
            NgTestBed(ng.createTestConditionalEmbeddedViewsFactory());
        final testFixture = await testBed.create();

        // Should not return embedded component before it's created.
        expect(
          rootNode(),
          InspectorNode((b) => b
            ..component.name = '$TestConditionalEmbeddedViews'
            ..children.replace([
              InspectorNode(
                (b) => b.directives.replace([
                  InspectorDirective((b) => b.name = '$NgIf'),
                ]),
              ),
            ])),
        );

        // Should return embedded component after it's created.
        await testFixture.update((component) {
          component.isChildVisible = true;
        });

        expect(
          rootNode(),
          InspectorNode((b) => b
            ..component.name = '$TestConditionalEmbeddedViews'
            ..children.replace([
              InspectorNode(
                (b) => b.directives.replace([
                  InspectorDirective((b) => b.name = '$NgIf'),
                ]),
              ),
              // TODO(b/196106275): should be a child of the NgIf node.
              InspectorNode((b) => b.component.name = '$TestEmbeddedViews1'),
            ])),
        );

        // Should not return embedded component after it's destroyed.
        await testFixture.update((component) {
          component.isChildVisible = false;
        });

        expect(
          rootNode(),
          InspectorNode((b) => b
            ..component.name = '$TestConditionalEmbeddedViews'
            ..children.replace([
              InspectorNode(
                (b) => b.directives.replace([
                  InspectorDirective((b) => b.name = '$NgIf'),
                ]),
              ),
            ])),
        );
      });

      test('repeated', () async {
        final testBed = NgTestBed(ng.createTestRepeatedEmbeddedViewsFactory());
        final testFixture = await testBed.create(
          beforeChangeDetection: (component) {
            component.values = [1, 2, 4];
          },
        );

        // Should return embedded components after they're created.
        expect(
          rootNode(),
          InspectorNode((b) => b
            ..component.name = '$TestRepeatedEmbeddedViews'
            ..children.replace([
              InspectorNode(
                (b) => b.directives.replace([
                  InspectorDirective((b) => b.name = '$NgFor'),
                ]),
              ),
              // TODO(b/196106275): should be children of the NgFor node.
              for (var i = 0; i < 3; i++)
                InspectorNode((b) => b.component.name = '$TestEmbeddedViews1'),
            ])),
        );

        await testFixture.update((component) {
          component.values.insert(2, 3); // [1, 2, 3, 4];
        });

        // Should reflect additions to embedded views.
        expect(
          rootNode(),
          InspectorNode((b) => b
            ..component.name = '$TestRepeatedEmbeddedViews'
            ..children.replace([
              InspectorNode(
                (b) => b.directives.replace([
                  InspectorDirective((b) => b.name = '$NgFor'),
                ]),
              ),
              // TODO(b/196106275): should be children of the NgFor node.
              for (var i = 0; i < 4; i++)
                InspectorNode((b) => b.component.name = '$TestEmbeddedViews1'),
            ])),
        );

        await testFixture.update((component) {
          component.values.removeRange(0, 2);
        });

        // Should reflect removals to embedded components.
        expect(
          rootNode(),
          InspectorNode((b) => b
            ..component.name = '$TestRepeatedEmbeddedViews'
            ..children.replace([
              InspectorNode(
                (b) => b.directives.replace([
                  InspectorDirective((b) => b.name = '$NgFor'),
                ]),
              ),
              // TODO(b/196106275): should be children of the NgFor node.
              for (var i = 0; i < 2; i++)
                InspectorNode((b) => b.component.name = '$TestEmbeddedViews1'),
            ])),
        );
      });

      test('transplated', () async {
        final testBed =
            NgTestBed(ng.createTestTransplantedEmbeddedViewsFactory());
        await testBed.create();

        expect(
          rootNode(),
          InspectorNode((b) => b
            ..component.name = '$TestTransplantedEmbeddedViews'
            ..children.replace([
              InspectorNode((b) => b
                ..component.name = '$TestEmbeddedViews2'
                ..children.replace([
                  InspectorNode(
                    (b) => b.directives.replace([
                      InspectorDirective((b) => b.name = '$NgTemplateOutlet'),
                    ]),
                  ),
                  // TODO(b/196106275): should be a child of NgTemplateOutlet.
                  InspectorNode(
                      (b) => b.component.name = '$TestEmbeddedViews1'),
                ])),
            ])),
        );
      });
    });

    test('host views', () async {
      final testBed = NgTestBed(ng.createTestHostViewsFactory());
      final testFixture = await testBed.create();

      // Should not return imperatively loaded component before it's created.
      expect(
        rootNode(),
        InspectorNode((b) => b.component.name = '$TestHostViews'),
      );

      await testFixture.update((component) {
        component.load();
      });

      // Should return imperatively loaded component after it's created.
      expect(
        rootNode(),
        InspectorNode((b) => b
          ..component.name = '$TestHostViews'
          ..children.replace([
            InspectorNode((b) => b.component.name = '$TestHostViews1'),
          ])),
      );

      await testFixture.update((component) {
        component.clear();
      });

      // Should not return imperatively loaded component after it's destroyed.
      expect(
        rootNode(),
        InspectorNode((b) => b.component.name = '$TestHostViews'),
      );
    });

    test('projected content', () async {
      final testBed = NgTestBed(ng.createTestProjectedContentFactory());
      await testBed.create();

      expect(
        rootNode(),
        InspectorNode((b) => b
          ..component.name = '$TestProjectedContent'
          ..children.replace([
            InspectorNode((b) => b
              ..component.name = '$TestProjectedContent1'
              ..children.replace([
                InspectorNode(
                    (b) => b.component.name = '$TestProjectedContent3'),
                InspectorNode(
                    (b) => b.component.name = '$TestProjectedContent2'),
                InspectorNode((b) => b
                  ..component.name = '$TestProjectedContent5'
                  ..children.replace([
                    InspectorNode(
                        (b) => b.component.name = '$TestProjectedContent4'),
                  ])),
              ])),
          ])),
      );
    });

    group('external content root', () {
      late html.Element container;
      late NgTestFixture<TestExternalContentRoots> testFixture;

      setUp(() async {
        container = createContentRoot();
        final testBed = NgTestBed(ng.createTestExternalContentRootsFactory());
        testFixture = await testBed.create();
      });

      tearDown(() {
        container.remove();
      });

      test('with no components', () async {
        await testFixture.update((component) {
          component.initExternalContent(
            container,
            component.noComponentTemplateRef!,
          );
        });

        final nodes = Inspector.instance.getNodes(groupName);
        expect(nodes, hasLength(1));
      });

      test('with one component', () async {
        await testFixture.update((component) {
          component.initExternalContent(
            container,
            component.oneComponentTemplateRef!,
          );
        });

        final nodes = Inspector.instance.getNodes(groupName);
        expect(nodes, hasLength(2));
      });

      test('with multiple components', () async {
        await testFixture.update((component) {
          component.initExternalContent(
            container,
            component.multipleComponentTemplateRef!,
          );
        });

        final nodes = Inspector.instance.getNodes(groupName);
        expect(nodes, hasLength(3));
      });
    });

    test('multiple external content roots', () async {
      final containerOne = createContentRoot();
      final containerTwo = createContentRoot();
      final testBed = NgTestBed(ng.createTestExternalContentRootsFactory());
      final testFixture = await testBed.create();

      await testFixture.update((component) {
        component
          ..initExternalContent(
            containerOne,
            component.oneComponentTemplateRef!,
          )
          ..initExternalContent(
            containerTwo,
            component.oneComponentTemplateRef!,
          );
      });

      final nodes = Inspector.instance.getNodes(groupName);
      expect(nodes, hasLength(3));
    });

    test('is coalesced by existing content root', () async {
      final testBed = NgTestBed(ng.createTestExternalContentRootsFactory());
      final testFixture = await testBed.create();
      final container = createContentRoot(parent: testFixture.rootElement);

      await testFixture.update((component) {
        component.initExternalContent(
          container,
          component.oneComponentTemplateRef!,
        );
      });

      final nodes = Inspector.instance.getNodes(groupName);
      expect(nodes, hasLength(1));
    });

    test('coalesces existing content roots', () async {
      final testBed = NgTestBed(ng.createTestExternalContentRootsFactory());
      final testFixture = await testBed.create();
      final childContainer = html.DivElement();
      final parentContainer = testFixture.rootElement.parent!
        ..append(childContainer);
      registerContentRoot(childContainer);
      registerContentRoot(parentContainer);

      await testFixture.update((component) {
        component
          ..initExternalContent(
            parentContainer,
            component.oneComponentTemplateRef!,
          )
          ..initExternalContent(
            childContainer,
            component.oneComponentTemplateRef!,
          );
      });

      final nodes = Inspector.instance.getNodes(groupName);
      expect(nodes, hasLength(3));
    });
  });

  // TODO(b/194920649): remove.
  group('getComponentInputs', () {
    // Returns the ID of the first child component in the app.
    int firstChildComponentId() {
      final components = Inspector.instance.getComponents(groupName);
      final component = components.first;
      final children = component['children'] as List<Map<String, Object>>;
      final child = children.first;
      return child['id'] as int;
    }

    test('no inputs', () async {
      final testBed = NgTestBed(ng.createTestUsedInputsFactory());
      await testBed.create();

      final components = Inspector.instance.getComponents(groupName);
      final component = components.first;
      final id = component['id'] as int;

      final inputs = Inspector.instance.getComponentInputs(id);
      expect(inputs, isEmpty);
    });

    test('omits unused inputs', () async {
      final testBed = NgTestBed(ng.createTestUnusedInputsFactory());
      await testBed.create();

      final id = firstChildComponentId();
      final inputs = Inspector.instance.getComponentInputs(id);
      expect(inputs, isEmpty);
    });

    test('omits inputs until set', () async {
      final testBed = NgTestBed(ng.createTestUsedInputsFactory());
      final testFixture = await testBed.create();

      final id = firstChildComponentId();
      var inputs = Inspector.instance.getComponentInputs(id);
      expect(inputs, isEmpty);

      await testFixture.update((component) {
        component.title = 'Hello!';
      });

      inputs = Inspector.instance.getComponentInputs(id);
      expect(inputs, hasLength(1));
      expect(inputs, containsPair('name', 'Hello!'));

      await testFixture.update((component) {
        component.numbers = [1, 2, 3];
      });

      inputs = Inspector.instance.getComponentInputs(id);
      expect(inputs, hasLength(2));
      expect(inputs, containsPair('name', 'Hello!'));
      expect(inputs, containsPair('data', [1, 2, 3]));
    });

    test('updates inputs when changed', () async {
      final testBed = NgTestBed(ng.createTestUsedInputsFactory());
      final testFixture = await testBed.create(
        beforeChangeDetection: (component) {
          component.title = 'Hello!';
        },
      );

      final id = firstChildComponentId();
      var inputs = Inspector.instance.getComponentInputs(id);
      expect(inputs, {'name': 'Hello!'});

      await testFixture.update((component) {
        component.title = 'Goodbye.';
      });

      inputs = inputs = Inspector.instance.getComponentInputs(id);
      expect(inputs, {'name': 'Goodbye.'});
    });

    test('records immutable expressions', () async {
      final testBed = NgTestBed(ng.createTestImmutableInputsFactory());
      final testFixture = await testBed.create();

      final id = firstChildComponentId();
      final inputs = Inspector.instance.getComponentInputs(id);
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

  group('getInputs', () {
    // Returns the ID of the first child component in the app.
    int firstChildComponentId() {
      final nodes = Inspector.instance.getNodes(groupName);
      return nodes.first.children.first.component!.id;
    }

    test('no inputs', () async {
      final testBed = NgTestBed(ng.createTestUsedInputsFactory());
      await testBed.create();

      final nodes = Inspector.instance.getNodes(groupName);
      final rootComponentId = nodes.first.component!.id;
      final inputs = Inspector.instance.getInputs(rootComponentId);
      expect(inputs, isEmpty);
    });

    test('omits unused inputs', () async {
      final testBed = NgTestBed(ng.createTestUnusedInputsFactory());
      await testBed.create();

      final id = firstChildComponentId();
      final inputs = Inspector.instance.getInputs(id);
      expect(inputs, isEmpty);
    });

    test('omits inputs until set', () async {
      final testBed = NgTestBed(ng.createTestUsedInputsFactory());
      final testFixture = await testBed.create();

      final id = firstChildComponentId();
      var inputs = Inspector.instance.getInputs(id);
      expect(inputs, isEmpty);

      await testFixture.update((component) {
        component.title = 'Hello!';
      });

      inputs = Inspector.instance.getInputs(id);
      expect(inputs, hasLength(1));
      expect(inputs, containsPair('name', 'Hello!'));

      await testFixture.update((component) {
        component.numbers = [1, 2, 3];
      });

      inputs = Inspector.instance.getInputs(id);
      expect(inputs, hasLength(2));
      expect(inputs, containsPair('name', 'Hello!'));
      expect(inputs, containsPair('data', [1, 2, 3]));
    });

    test('updates inputs when changed', () async {
      final testBed = NgTestBed(ng.createTestUsedInputsFactory());
      final testFixture = await testBed.create(
        beforeChangeDetection: (component) {
          component.title = 'Hello!';
        },
      );

      final id = firstChildComponentId();
      var inputs = Inspector.instance.getInputs(id);
      expect(inputs, {'name': 'Hello!'});

      await testFixture.update((component) {
        component.title = 'Goodbye.';
      });

      inputs = inputs = Inspector.instance.getInputs(id);
      expect(inputs, {'name': 'Goodbye.'});
    });

    test('records immutable expressions', () async {
      final testBed = NgTestBed(ng.createTestImmutableInputsFactory());
      final testFixture = await testBed.create();

      final id = firstChildComponentId();
      final inputs = Inspector.instance.getInputs(id);
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

    test('captures directive inputs', () async {
      final testBed = NgTestBed(ng.createTestConditionalEmbeddedViewsFactory());
      final testFixture = await testBed.create();
      final nodes = Inspector.instance.getNodes(groupName);
      final ngIfId = nodes.first.children.first.directives.first.id;

      var inputs = Inspector.instance.getInputs(ngIfId);
      expect(inputs, hasLength(1));
      expect(inputs, containsPair('ngIf', false));

      await testFixture.update((component) {
        component.isChildVisible = true;
      });

      inputs = Inspector.instance.getInputs(ngIfId);
      expect(inputs, hasLength(1));
      expect(inputs, containsPair('ngIf', true));
    });
  });
}

html.Element createContentRoot({html.Element? parent}) {
  final root = html.DivElement();
  (parent ?? html.document.body!).append(root);
  registerContentRoot(root);
  return root;
}

/// Sets all IDs to [InspectorDirective.defaultIdForTesting].
InspectorNode anonymize(InspectorNode node) {
  final defaultId = InspectorDirective.defaultIdForTesting!;
  return node.rebuild((b) {
    if (node.component != null) {
      b.component.id = defaultId;
    }
    b.directives.map((directive) => directive.rebuild((b) => b.id = defaultId));
    b.children.map(anonymize);
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
  selector: 'test-external-content-roots',
  template: '''
    <template #none>
      <p>Hello, world!</p>
    </template>
    <template #one>
      <test-2></test-2>
    </template>
    <template #multiple>
      <test-2></test-2>
      <div>
        <test-2></test-2>
      </div>
    </template>
  ''',
  directives: [TestComponentViews2],
)
class TestExternalContentRoots {
  TestExternalContentRoots(this._viewContainerRef);

  final ViewContainerRef _viewContainerRef;

  @ViewChild('none')
  TemplateRef? noComponentTemplateRef;

  @ViewChild('one')
  TemplateRef? oneComponentTemplateRef;

  @ViewChild('multiple')
  TemplateRef? multipleComponentTemplateRef;

  void initExternalContent(html.Element container, TemplateRef content) {
    final viewRef = _viewContainerRef.createEmbeddedView(content);
    for (final node in viewRef.rootNodes) {
      container.append(node);
    }
  }
}

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
