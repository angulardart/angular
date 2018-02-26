@TestOn('browser')
import 'dart:async';
import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/facade/exceptions.dart' show BaseException;

import 'error_integration_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('Error handling', () {
    tearDown(() => disposeAnyRunningTest());
    test('should preserve Error stack traces thrown from components', () async {
      var testBed = new NgTestBed<ContainerWithThrowingComponent>();
      await testBed.create().catchError((e) {
        expect(e.toString(), contains("MockException"));
        expect(e.toString(), contains("functionThatThrows"));
      });
    });

    test('should preserve non-Error stack traces thrown from components',
        () async {
      var testBed = new NgTestBed<ContainerWithThrowingComponent2>();
      await testBed.create().catchError((e, stack) {
        expect(e.toString(), contains("NonError"));
        expect(e.toString(), contains("functionThatThrows"));
      });
    });

    test(
        'should report a meaningful error when a directive '
        'is missing annotation', () async {
      var testBed = new NgTestBed<MyCompWithDirectiveMissingAnnotation>();
      await testBed.create().catchError((e, stack) {
        expect(e.toString(),
            'No Directive annotation found on $SomeDirectiveMissingAnnotation');
      });
    });

    test('should provide an error context when an error happens in DI',
        () async {
      var testBed = new NgTestBed<MyCompWithThrowingDirective>();
      await testBed.create().catchError((e) {
        var c = e.context;
        expect((c.renderNode as Element).tagName,
            'MY-COMP-WITH-THROWING-DIRECTIVE');
        expect((c.injector as Injector).get, isNotNull);
      });
    });

    test(
        'should provide an error context when an error happens '
        'in change detection', () async {
      bool updateFailed = false;
      var testBed = new NgTestBed<MyCompWithCdException>();
      var fixture = await testBed.create();
      await fixture.update((MyCompWithCdException c) {
        c.one = null;
      }).catchError((e) {
        updateFailed = true;
        // Intentionally less-specific, varies between Dart2JS/DDC/Dart VM.
        expect(e.toString(), contains("'two'"));
      });
      assert(updateFailed);
    });

    test(
        'should provide an error context when an error happens in '
        'change detection (text node)', () async {
      bool updateFailed = false;
      var testBed = new NgTestBed<MyCompWithCdExceptionInterpolate>();
      var fixture = await testBed.create();
      await fixture.update((MyCompWithCdExceptionInterpolate c) {
        c.one = null;
      }).catchError((e) {
        updateFailed = true;
        // Intentionally less-specific, varies between Dart2JS/DDC/Dart VM.
        expect(e.toString(), contains("'two'"));
      });
      assert(updateFailed);
    });

    test(
        'should provide an error context when an error happens in an '
        'event handler', () async {
      var testBed = new NgTestBed<MyCompWithEventException>();
      var fixture = await testBed.create();
      await fixture.update((component) {
        component.emitter.fireEvent('boom');
      }).catchError((e) {
        expect(e.toString(), contains('exceptionOnEventSample'));
      });
      expect(fixture.assertOnlyInstance.eventHandlerCalled, true);
    });
    test(
        'should specify a location of an error that happened '
        'during change detection (element property)', () async {
      bool updateFailed = false;
      var testBed = new NgTestBed<MyCompWithCdExceptionOnElement>();
      var fixture = await testBed.create();
      await fixture.update((MyCompWithCdExceptionOnElement c) {
        c.one = null;
      }).catchError((e) {
        updateFailed = true;
        // Intentionally less-specific, varies between Dart2JS/DDC/Dart VM.
        expect(e.toString(), contains("'two'"));
      });
      assert(updateFailed);
    });
    test(
        'should specify a location of an error that happened during '
        'change detection (directive property)', () async {
      bool updateFailed = false;
      var testBed = new NgTestBed<MyCompWithCdExceptionOnProperty>();
      var fixture = await testBed.create();
      await fixture.update((MyCompWithCdExceptionOnProperty c) {
        c.one = null;
      }).catchError((e) {
        updateFailed = true;
        // Intentionally less-specific, varies between Dart2JS/DDC/Dart VM.
        expect(e.toString(), contains("'two'"));
      });
      assert(updateFailed);
    });
  });
}

class SomeDirectiveMissingAnnotation {}

@Component(
  selector: 'my-comp-missing-dir-annotation',
  template: '',
  directives: const [SomeDirectiveMissingAnnotation],
)
class MyCompWithDirectiveMissingAnnotation {
  String ctxProp;
  num ctxNumProp;
  bool ctxBoolProp;
  MyComp() {
    this.ctxProp = 'initial value';
    this.ctxNumProp = 0;
    this.ctxBoolProp = false;
  }

  throwError() {
    throw new UnsupportedError('boom');
  }

  doNothing() {}
}

@Component(
  selector: 'my-comp-with-throwing-directive',
  directives: const [DirectiveThrowingAnError],
  template: '<directive-throwing-error></directive-throwing-error>',
)
class MyCompWithThrowingDirective {}

@Directive(
  selector: 'directive-throwing-error',
)
class DirectiveThrowingAnError {
  DirectiveThrowingAnError() {
    throw new BaseException('BOOM');
  }
}

class MockException implements Error {
  var message;
  var stackTrace;
}

class NonError {
  var message;
}

void functionThatThrows() {
  try {
    throw new MockException();
  } catch (e, stack) {
    // If we lose the stack trace the message will no longer match
    // the first line in the stack
    e.message = stack.toString().split('\n')[0];
    e.stackTrace = stack;
    rethrow;
  }
}

void functionThatThrowsNonError() {
  try {
    // ignore: only_throw_errors
    throw new NonError();
  } catch (e, stack) {
    // If we lose the stack trace the message will no longer match
    // the first line in the stack
    e.message = stack.toString().split('\n')[0];
    rethrow;
  }
}

@Component(
  selector: 'throwing-component',
  template: '',
)
class ThrowingComponent {
  ThrowingComponent() {
    functionThatThrows();
  }
}

@Component(
  selector: 'throwing-component2',
  template: '',
)
class ThrowingComponent2 {
  ThrowingComponent2() {
    functionThatThrowsNonError();
  }
}

@Component(
  selector: 'container-with-throwing',
  template: '<throwing-component></throwing-component>',
  directives: const [ThrowingComponent],
)
class ContainerWithThrowingComponent {
  dynamic value;
}

@Component(
  selector: 'container-with-throwing2',
  template: '<throwing-component></throwing-component>',
  directives: const [ThrowingComponent2],
)
class ContainerWithThrowingComponent2 {
  dynamic value;
}

@Component(
  selector: 'mycomp-with-cd-exception',
  template: '<input [value]="one.two" #local>',
)
class MyCompWithCdException {
  SomeModel one = new SomeModel('initial value');
}

class SomeModel {
  String two;
  SomeModel(this.two);
}

@Component(
  selector: 'mycomp-with-cd-exception-interpolation',
  template: '<div>{{one.two}}</div>',
)
class MyCompWithCdExceptionInterpolate {
  SomeModel one = new SomeModel('initial value');
}

@Component(
  selector: 'mycomp-with-cd-exception-onelement',
  template: '<div [title]="one.two"></div>',
)
class MyCompWithCdExceptionOnElement {
  SomeModel one = new SomeModel('initial value');
}

@Component(
  selector: 'mycomp-with-cd-exception-onproperty',
  template: '<mycomp-child [prop1]="one.two"></mycomp-child>',
)
class MyCompWithCdExceptionOnProperty {
  SomeModel one = new SomeModel('initial value');
}

@Component(
  selector: 'mycomp-child',
  template: '<div>{{prop1}}</div>',
)
class MyCompChild {
  String prop1 = 'defaultProp1';
}

@Component(
  selector: 'mycomp-with-event-exception',
  template: '<span emitter listener (event)="throwError()" #local>'
      '</span>',
  directives: const [DirectiveEmittingEvent, DirectiveListeningEvent],
)
class MyCompWithEventException {
  bool eventHandlerCalled = false;

  @ViewChild(DirectiveEmittingEvent)
  DirectiveEmittingEvent emitter;

  void throwError() {
    eventHandlerCalled = true;
    throw new Exception('exceptionOnEventSample');
  }
}

@Directive(
  selector: '[emitter]',
)
class DirectiveEmittingEvent {
  String msg = '';

  final _onEvent = new StreamController<String>.broadcast();

  @Output()
  Stream<String> get event => _onEvent.stream;

  void fireEvent(String msg) {
    _onEvent.add(msg);
  }
}

@Directive(
  selector: '[listener]',
  host: const {'(event)': 'onEvent(\$event)'},
)
class DirectiveListeningEvent {
  String msg = '';
  void onEvent(String value) {
    msg = value;
  }
}
