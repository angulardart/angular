@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import '1670_event_handler_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should support top-level methods tear-offs for events', () async {
    final testBed = NgTestBed.forComponent<TestTopLevelMethods>(
      ng.TestTopLevelMethodsNgFactory,
    );
    final fixture = await testBed.create();
    overrideTopLevelDoCapture = expectAsync0(() {});
    await fixture.update((_) {
      fixture.rootElement.querySelector('button').click();
    });
  }, skip: 'https://github.com/dart-lang/angular/issues/1670');

  test('should support top-level methods invoked for events', () async {
    final testBed = NgTestBed.forComponent<TestTopLevelMethodsDirect>(
      ng.TestTopLevelMethodsDirectNgFactory,
    );
    final fixture = await testBed.create();
    overrideTopLevelDoCapture = expectAsync0(() {});
    await fixture.update((_) {
      fixture.rootElement.querySelector('button').click();
    });
  });

  test('should support static methods tear-offs for events', () async {
    final testBed = NgTestBed.forComponent<TestStaticMethods>(
      ng.TestStaticMethodsNgFactory,
    );
    final fixture = await testBed.create();
    TestStaticMethods.overrideDoCapture = expectAsync0(() {});
    await fixture.update((_) {
      fixture.rootElement.querySelector('button').click();
    });
  });

  test('should support static methods invoked for events', () async {
    final testBed = NgTestBed.forComponent<TestStaticMethodsDirect>(
      ng.TestStaticMethodsDirectNgFactory,
    );
    final fixture = await testBed.create();
    TestStaticMethodsDirect.overrideDoCapture = expectAsync0(() {});
    await fixture.update((_) {
      fixture.rootElement.querySelector('button').click();
    });
  });

  test('should support chained method tear-offs for events', () async {
    final testBed = NgTestBed.forComponent<TestChainedMethods>(
      ng.TestChainedMethodsNgFactory,
    );
    final fixture = await testBed.create();
    fixture.assertOnlyInstance.bar.overrideDoCapture = expectAsync0(() {});
    await fixture.update((_) {
      fixture.rootElement.querySelector('button').click();
    });
  }, skip: 'https://github.com/dart-lang/angular/issues/1670');

  test('should support chained method invoked for events', () async {
    final testBed = NgTestBed.forComponent<TestChainedMethodsDirect>(
      ng.TestChainedMethodsDirectNgFactory,
    );
    final fixture = await testBed.create();
    fixture.assertOnlyInstance.bar.overrideDoCapture = expectAsync0(() {});
    await fixture.update((_) {
      fixture.rootElement.querySelector('button').click();
    });
  });
}

void Function() overrideTopLevelDoCapture = () {};
void topLevelDoCapture() {
  overrideTopLevelDoCapture();
}

@Component(
  selector: 'test',
  exports: [topLevelDoCapture],
  template: r'<button (click)="topLevelDoCapture"></button>',
)
class TestTopLevelMethods {}

@Component(
  selector: 'test',
  exports: [topLevelDoCapture],
  template: r'<button (click)="topLevelDoCapture()"></button>',
)
class TestTopLevelMethodsDirect {}

@Component(
  selector: 'test',
  exports: [],
  template: r'<button (click)="TestStaticMethods.doCapture"></button>',
)
class TestStaticMethods {
  static void Function() overrideDoCapture = () {};
  static void doCapture() {
    overrideDoCapture();
  }
}

@Component(
  selector: 'test',
  exports: [],
  template: r'<button (click)="TestStaticMethodsDirect.doCapture()"></button>',
)
class TestStaticMethodsDirect {
  static void Function() overrideDoCapture = () {};
  static void doCapture() {
    overrideDoCapture();
  }
}

@Component(
  selector: 'test',
  template: r'<button (click)="bar.doCapture"></button>',
)
class TestChainedMethods {
  final bar = Bar();
}

@Component(
  selector: 'test',
  template: r'<button (click)="bar.doCapture()"></button>',
)
class TestChainedMethodsDirect {
  final bar = Bar();
}

class Bar {
  void Function() overrideDoCapture = () {};
  void doCapture() {
    overrideDoCapture();
  }
}
