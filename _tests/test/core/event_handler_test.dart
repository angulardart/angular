import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'event_handler_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  late NgTestFixture<ClickHandler> fixture;

  group('Event handler', () {
    setUp(() async {
      final testBed = NgTestBed(ng.createClickHandlerFactory());
      fixture = await testBed.create();
    });

    group('method call', () {
      test('should handle click with no args', () async {
        await fixture.update((cmp) => cmp.noArgButton!.click());
        expect(fixture.assertOnlyInstance.clicks, emits(null));
      });

      test('should handle click with one arg', () async {
        await fixture.update((cmp) => cmp.oneArgButton!.click());
        expect(fixture.assertOnlyInstance.clicks, emits(null));
      });
    });

    group('tearoffs', () {
      test('should handle click with no args', () async {
        await fixture.update((cmp) => cmp.noArgTearoffButton!.click());
        expect(fixture.assertOnlyInstance.clicks, emits(null));
      });

      test('should handle click with one arg', () async {
        await fixture.update((cmp) => cmp.oneArgTearoffButton!.click());
        expect(fixture.assertOnlyInstance.clicks, emits(null));
      });

      test('should handle click with method in superclass', () async {
        await fixture.update((cmp) => cmp.superTearoffButton!.click());
        expect(fixture.assertOnlyInstance.clicks, emits(null));
      });
    });
  });

  group('should support name arguments', () {
    test('default', () async {
      final testBed = NgTestBed<TestNamedArgsWithDefaultValue1>(
        ng.createTestNamedArgsWithDefaultValue1Factory(),
      );
      final fixture = await testBed.create();
      await fixture.update((_) {
        fixture.rootElement.querySelector('button')!.click();
      });
      expect(fixture.assertOnlyInstance.captured, ['bar']);
    });

    test('default with a tear-off', () async {
      final testBed = NgTestBed<TestNamedArgsWithDefaultValue2>(
        ng.createTestNamedArgsWithDefaultValue2Factory(),
      );
      final fixture = await testBed.create();
      await fixture.update((_) {
        fixture.rootElement.querySelector('button')!.click();
      });
      expect(fixture.assertOnlyInstance.captured, ['bar']);
    });

    test('passing a component field as positional arg', () async {
      final testBed = NgTestBed<TestPositionalArgsFromComponent>(
        ng.createTestPositionalArgsFromComponentFactory(),
      );
      final fixture = await testBed.create();
      await fixture.update((_) {
        fixture.rootElement.querySelector('button')!.click();
      });
      expect(fixture.assertOnlyInstance.captured, ['bar']);
    });

    test('passing a component field as an arg', () async {
      final testBed = NgTestBed<TestNamedArgsFromComponentField>(
        ng.createTestNamedArgsFromComponentFieldFactory(),
      );
      final fixture = await testBed.create();
      await fixture.update((_) {
        fixture.rootElement.querySelector('button')!.click();
      });
      expect(fixture.assertOnlyInstance.captured, ['bar']);
    });

    test('passing a literal value as an arg', () async {
      final testBed = NgTestBed<TestNamedArgsFromLiteralValue>(
        ng.createTestNamedArgsFromLiteralValueFactory(),
      );
      final fixture = await testBed.create();
      await fixture.update((_) {
        fixture.rootElement.querySelector('button')!.click();
      });
      expect(fixture.assertOnlyInstance.captured, ['bar']);
    });

    test('passing a template local variable as an arg', () async {
      final testBed = NgTestBed<TestNamedArgsFromLocalValue>(
        ng.createTestNamedArgsFromLocalValueFactory(),
      );
      final fixture = await testBed.create();
      await fixture.update((_) {
        fixture.rootElement.querySelector('button')!.click();
      });
      expect(fixture.assertOnlyInstance.captured, ['bar']);
    });
  });

  test('should support top-level methods tear-offs for events', () async {
    final testBed = NgTestBed<TestTopLevelMethods>(
      ng.createTestTopLevelMethodsFactory(),
    );
    final fixture = await testBed.create();
    overrideTopLevelDoCapture = expectAsync0(() {});
    await fixture.update((_) {
      fixture.rootElement.querySelector('button')!.click();
    });
  }, skip: 'https://github.com/angulardart/angular/issues/1670');

  test('should support top-level methods invoked for events', () async {
    final testBed = NgTestBed<TestTopLevelMethodsDirect>(
      ng.createTestTopLevelMethodsDirectFactory(),
    );
    final fixture = await testBed.create();
    overrideTopLevelDoCapture = expectAsync0(() {});
    await fixture.update((_) {
      fixture.rootElement.querySelector('button')!.click();
    });
  });

  test('should support static methods tear-offs for events', () async {
    final testBed = NgTestBed<TestStaticMethods>(
      ng.createTestStaticMethodsFactory(),
    );
    final fixture = await testBed.create();
    TestStaticMethods.overrideDoCapture = expectAsync0(() {});
    await fixture.update((_) {
      fixture.rootElement.querySelector('button')!.click();
    });
  });

  test('should support static methods invoked for events', () async {
    final testBed = NgTestBed<TestStaticMethodsDirect>(
      ng.createTestStaticMethodsDirectFactory(),
    );
    final fixture = await testBed.create();
    TestStaticMethodsDirect.overrideDoCapture = expectAsync0(() {});
    await fixture.update((_) {
      fixture.rootElement.querySelector('button')!.click();
    });
  });

  test('should support chained method tear-offs for events', () async {
    final testBed = NgTestBed<TestChainedMethods>(
      ng.createTestChainedMethodsFactory(),
    );
    final fixture = await testBed.create();
    fixture.assertOnlyInstance.bar.overrideDoCapture = expectAsync0(() {});
    await fixture.update((_) {
      fixture.rootElement.querySelector('button')!.click();
    });
  }, skip: 'https://github.com/angulardart/angular/issues/1670');

  test('should support chained method invoked for events', () async {
    final testBed = NgTestBed<TestChainedMethodsDirect>(
      ng.createTestChainedMethodsDirectFactory(),
    );
    final fixture = await testBed.create();
    fixture.assertOnlyInstance.bar.overrideDoCapture = expectAsync0(() {});
    await fixture.update((_) {
      fixture.rootElement.querySelector('button')!.click();
    });
  });

  // All exceptions thrown in event listeners should be caught for logging.
  test('should be able to catch a thrown event listener error', () async {
    final testBed =
        NgTestBed(ng.createComponentWithHostEventThatThrowsFactory());
    final fixture = await testBed.create();
    expect(
      fixture.update((_) => fixture.rootElement.click()),
      throwsIntentional,
    );
  });
}

@Component(
  selector: 'test',
  template: '''
  <button #noArg (click)="onClick()"></button>
  <button #oneArg (click)="clickWithEvent(\$event)"></button>
  <button #noArgTearoff (click)="onClick"></button>
  <button #oneArgTearoff (click)="clickWithEvent"></button>
  <button #superTearoff (click)="superClick"></button>
  ''',
)
class ClickHandler extends SuperClick {
  @ViewChild('noArg')
  HtmlElement? noArgButton;

  @ViewChild('oneArg')
  HtmlElement? oneArgButton;

  @ViewChild('noArgTearoff')
  HtmlElement? noArgTearoffButton;

  @ViewChild('oneArgTearoff')
  HtmlElement? oneArgTearoffButton;

  @ViewChild('superTearoff')
  HtmlElement? superTearoffButton;

  void onClick() {
    _clicks.add(null);
  }

  void clickWithEvent(Object? event) {
    if (event != null) _clicks.add(null);
  }
}

class SuperClick {
  void superClick() {
    _clicks.add(null);
  }

  Stream<void> get clicks => _clicks.stream;

  final _clicks = StreamController<void>();
}

@Component(
  selector: 'test',
  template: r'<button (click)="foo()"></button>',
)
class TestNamedArgsWithDefaultValue1 {
  final captured = <String>[];

  void foo({String bar = 'bar'}) {
    captured.add(bar);
  }
}

@Component(
  selector: 'test',
  template: r'<button (click)="foo"></button>',
)
class TestNamedArgsWithDefaultValue2 {
  final captured = <String>[];

  void foo({String bar = 'bar'}) {
    captured.add(bar);
  }
}

@Component(
  selector: 'test',
  template: r'<button (click)="foo(field)"></button>',
)
class TestPositionalArgsFromComponent {
  final field = 'bar';
  final captured = <String>[];

  void foo(String bar) {
    captured.add(bar);
  }
}

@Component(
  selector: 'test',
  template: r'<button (click)="foo(bar: field)"></button>',
)
class TestNamedArgsFromComponentField {
  final field = 'bar';
  final captured = <String>[];

  void foo({required String bar}) {
    captured.add(bar);
  }
}

@Component(
  selector: 'test',
  template: r'''<button (click)="foo(bar: 'bar')"></button>''',
)
class TestNamedArgsFromLiteralValue {
  final captured = <String>[];

  void foo({required String bar}) {
    captured.add(bar);
  }
}

@Component(
  selector: 'test',
  directives: [NgFor],
  template: r'''
    <ng-container *ngFor="let item of items">
      <button (click)="foo(bar: item)"></button>
    </ng-container>
  ''',
)
class TestNamedArgsFromLocalValue {
  final items = ['bar'];
  final captured = <String>[];

  void foo({required String bar}) {
    captured.add(bar);
  }
}

// ignore: prefer_function_declarations_over_variables
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
  // ignore: prefer_function_declarations_over_variables
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
  // ignore: prefer_function_declarations_over_variables
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
  // ignore: prefer_function_declarations_over_variables
  void Function() overrideDoCapture = () {};
  void doCapture() {
    overrideDoCapture();
  }
}

@Component(
  selector: 'test',
  template: '',
)
class ComponentWithHostEventThatThrows {
  @HostListener('click')
  void onClick() => throw IntentionalError();
}

class IntentionalError extends Error {}

final throwsIntentional = throwsA(const TypeMatcher<IntentionalError>());
