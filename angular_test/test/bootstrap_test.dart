import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/src/bootstrap.dart';

import 'bootstrap_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  Injector _noopInjector(Injector i) => i;

  test('should create a new component in the DOM', () async {
    final host = Element.div();
    final test = await bootstrapForTest(
      ng_generated.createNewComponentInDomFactory(),
      host,
      _noopInjector,
    );
    expect(host.text, contains('Hello World'));
    test.destroy();
  });

  test('should call a synchronous handler before initial load', () async {
    final host = Element.div();
    final test = await bootstrapForTest<BeforeChangeDetection>(
      ng_generated.createBeforeChangeDetectionFactory(),
      host,
      _noopInjector,
      beforeChangeDetection: (comp) => comp.users.add('Mati'),
    );
    expect(host.text, contains('Hello Mati!'));
    test.destroy();
  });

  test('should call an asynchronous handler before initial load', () async {
    final host = Element.div();
    final test = await bootstrapForTest<BeforeChangeDetection>(
      ng_generated.createBeforeChangeDetectionFactory(),
      host,
      _noopInjector,
      beforeChangeDetection: (comp) async => comp.users.add('Mati'),
    );
    expect(host.text, contains('Hello Mati!'));
    test.destroy();
  });

  test('should include user-specified providers', () async {
    final host = Element.div();
    final test = await bootstrapForTest(
      ng_generated.createAddProvidersFactory(),
      host,
      (i) => Injector.map({TestService: TestService()}, i),
    );
    var instance = test.instance;
    expect(instance._testService, isNotNull);
    test.destroy();
  });

  test('should be able to call injector before component creation', () async {
    final host = Element.div();
    TestService? testService;
    final test = await bootstrapForTest(
        ng_generated.createAddProvidersFactory(),
        host,
        (i) => Injector.map({TestService: TestService()}, i),
        beforeComponentCreated: (injector) {
      testService = injector.provideType(TestService);
      testService!.count++;
    }, beforeChangeDetection: (_) {
      if (testService == null) {
        fail('`beforeComponentCreated` should be invoked before'
            ' `beforeChangeDetection`, `testService` should not be null.');
      }
    });
    var instance = test.instance;
    expect(testService, instance._testService);
    expect(testService!.count, 1);
    test.destroy();
  });

  test('should be able to call asynchronous injector before component creation',
      () async {
    final host = Element.div();
    TestService? testService;
    final test = await bootstrapForTest(
      ng_generated.createAddProvidersFactory(),
      host,
      (i) => Injector.map({TestService: TestService()}, i),
      beforeComponentCreated: (injector) =>
          Future.delayed(Duration(milliseconds: 200), () {}).then((_) {
        testService = injector.provideType(TestService);
        testService!.count++;
      }),
      beforeChangeDetection: (_) {
        if (testService == null) {
          fail('`beforeComponentCreated` should be invoked before'
              ' `beforeChangeDetection`, `testService` should not be null.');
        }
      },
    );
    var instance = test.instance;
    expect(testService, instance._testService);
    expect(testService!.count, 1);
    test.destroy();
  });
}

@Component(
  selector: 'test',
  template: 'Hello World',
)
class NewComponentInDom {}

@Component(
  selector: 'test',
  template: 'Hello {{users.first}}!',
)
class BeforeChangeDetection {
  // This will fail with an NPE if not initialized before change detection.
  final users = <String>[];
}

@Component(
  selector: 'test',
  template: '',
)
class AddProviders {
  final TestService _testService;

  AddProviders(this._testService);
}

@Injectable()
class TestService {
  int count = 0;
}
