import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/core/linker/dynamic_component_loader.dart';
import 'package:angular_test/angular_test.dart';
import 'package:angular_test/compatibility.dart';

import 'compatibility_test.template.dart' as ng;

void main() {
  ng.initReflector();

  late Element docRoot;
  late Element testRoot;

  setUp(() {
    docRoot = Element.tag('doc-root');
    testRoot = Element.tag('ng-test-bed-example-test');
    docRoot.append(testRoot);
  });

  tearDown(disposeAnyRunningTest);

  test('createTestInjector should support SlowComponentLoader', () async {
    final injector = createTestInjector([]);
    final loader = injector.provideType<SlowComponentLoader>(
      SlowComponentLoader,
    );
    expect(
      () => loader.load(TestSlowComponentLoaderAccess, Injector.empty()),
      returnsNormally,
    );
  });

  group('with injector', () {
    late NgTestBed<AngularInjector> testBed;
    TestService? testService;

    setUp(() {
      testService = null;
      testBed = NgTestBed(
        ng.createAngularInjectorFactory(),
        host: testRoot,
        rootInjector: (i) => Injector.map({TestService: TestService()}, i),
      );
    });

    test('should render, update, and destroy a component', () async {
      // We are going to verify that the document root has a new node created
      // (our component), the node is updated (after change detection), and
      // after destroying the test the document root has been cleared.
      final fixture = await testBed.create();
      expect(docRoot.text, isEmpty);
      testService = injectFromFixture(fixture, TestService);
      await fixture.update((_) => testService!.value = 'New value');
      expect(docRoot.text, 'New value');
      await fixture.dispose();
      print(docRoot.innerHtml);
      expect(docRoot.text, isEmpty);
    });
    group('and beforeComponentCreated without error', () {
      test('should handle synchronous fn', () async {
        final fixture = await testBed.create(beforeComponentCreated: (i) {
          testService = i.provideType(TestService);
          testService!.value = 'New value';
        }, beforeChangeDetection: (_) {
          expect(testService, isNotNull);
        });
        expect(docRoot.text, 'New value');
        await fixture.dispose();
      });

      test('should handle asynchronous fn', () async {
        final fixture = await testBed.create(beforeComponentCreated: (i) async {
          testService = i.provideType(TestService);
          testService!.value = 'New value';
        }, beforeChangeDetection: (_) {
          expect(testService, isNotNull);
        });
        expect(docRoot.text, 'New value');
        await fixture.dispose();
      });

      test('should handle asynchronous fn with delayed future', () async {
        final fixture = await testBed.create(
          beforeComponentCreated: (i) =>
              Future.delayed(Duration(milliseconds: 200), () {}).then((_) {
            testService = i.provideType(TestService);
            testService!.value = 'New value';
          }),
          beforeChangeDetection: (_) {
            expect(testService, isNotNull);
          },
        );
        expect(docRoot.text, 'New value');
        await fixture.dispose();
      });
    });

    group('and beforeComponentCreated with error', () {
      test('should handle synchronous fn', () async {
        expect(testBed.create(beforeComponentCreated: (_) {
          throw Error();
        }), throwsA(const TypeMatcher<Error>()));
      });

      test('should handle asynchronous fn', () async {
        expect(testBed.create(beforeComponentCreated: (_) async {
          throw Error();
        }), throwsA(const TypeMatcher<Error>()));
      });

      test('should handle asynchronous fn with delayed future', () async {
        expect(
          testBed.create(
            beforeComponentCreated: (_) =>
                Future.delayed(Duration(milliseconds: 200), () {}).then((_) {
              throw Error();
            }),
          ),
          throwsA(const TypeMatcher<Error>()),
        );
      });
    });
  });
}

@Component(
  selector: 'test',
  template: '{{value}}',
)
class AngularInjector {
  final TestService _testService;

  AngularInjector(this._testService);

  String? get value => _testService.value;
}

@Injectable()
class TestService {
  String? value;
}

@Component(
  selector: 'test',
  template: '',
)
class TestSlowComponentLoaderAccess {}
