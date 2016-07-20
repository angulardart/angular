@TestOn('browser')
library angular2.test.di.integration_dart_test;

import 'package:angular2/angular2.dart';
import 'package:angular2/core.dart';
import 'package:angular2/src/core/change_detection/change_detection.dart';
import 'package:angular2/src/core/change_detection/differs/default_iterable_differ.dart';
import 'package:angular2/src/core/debug/debug_node.dart';
import 'package:angular2/testing_internal.dart';
import 'package:observe/observe.dart';
import 'package:test/test.dart';

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
    throw new NonError();
  } catch (e, stack) {
    // If we lose the stack trace the message will no longer match
    // the first line in the stack
    e.message = stack.toString().split('\n')[0];
    rethrow;
  }
}

main() {
  group('Error handling', () {
    test('should preserve Error stack traces thrown from components', () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (tb, AsyncTestCompleter completer) {
        tb
            .overrideView(
                Dummy,
                new ViewMetadata(
                    template: '<throwing-component></throwing-component>',
                    directives: [ThrowingComponent]))
            .createAsync(Dummy)
            .catchError((e) {
          expect(e.toString(), contains("MockException"));
          expect(e.toString(), contains("functionThatThrows"));
          completer.done();
        });
      });
    });

    test('should preserve non-Error stack traces thrown from components',
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (tb, AsyncTestCompleter completer) {
        tb
            .overrideView(
                Dummy,
                new ViewMetadata(
                    template: '<throwing-component2></throwing-component2>',
                    directives: [ThrowingComponent2]))
            .createAsync(Dummy)
            .catchError((e, stack) {
          expect(e.toString(), contains("NonError"));
          expect(e.toString(), contains("functionThatThrows"));
          completer.done();
        });
      });
    });
  });

  group('Property access', () {
    test('should distinguish between map and property access', () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (tb, AsyncTestCompleter completer) {
        tb
            .overrideView(
                Dummy,
                new ViewMetadata(
                    template: '<property-access></property-access>',
                    directives: [PropertyAccess]))
            .createAsync(Dummy)
            .then((tc) {
          tc.detectChanges();
          expect(asNativeElements(tc.debugElement.children),
              hasTextContent('prop:foo-prop;map:foo-map'));
          completer.done();
        });
      });
    });

    test('should not fallback on map access if property missing', () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (tb, AsyncTestCompleter completer) {
        tb
            .overrideView(
                Dummy,
                new ViewMetadata(
                    template: '<no-property-access></no-property-access>',
                    directives: [NoPropertyAccess]))
            .createAsync(Dummy)
            .then((tc) {
          expect(() => tc.detectChanges(),
              throwsWith(new RegExp('property not found')));
          completer.done();
        });
      });
    });
  });

  group('OnChange', () {
    test('should be notified of changes', () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (tb, AsyncTestCompleter completer) {
        tb
            .overrideView(
                Dummy,
                new ViewMetadata(
                    template: '''<on-change [prop]="'hello'"></on-change>''',
                    directives: [OnChangeComponent]))
            .createAsync(Dummy)
            .then((tc) {
          tc.detectChanges();
          var cmp = tc.debugElement.children[0].inject(OnChangeComponent);
          expect(cmp.prop, 'hello');
          expect(cmp.changes.containsKey('prop'), true);
          completer.done();
        });
      });
    });
  });

  group("ObservableListDiff", () {
    test('should be notified of changes', fakeAsync(() {
      inject([TestComponentBuilder, Log], (TestComponentBuilder tcb, Log log) {
        tcb
            .overrideView(
                Dummy,
                new ViewMetadata(
                    template:
                        '''<component-with-observable-list [list]="value"></component-with-observable-list>''',
                    directives: [ComponentWithObservableList]))
            .createAsync(Dummy)
            .then((tc) {
          tc.debugElement.componentInstance.value =
              new ObservableList.from([1, 2]);

          tc.detectChanges();

          expect(log.result(), "check");
          expect(
              asNativeElements(tc.debugElement.children), hasTextContent('12'));

          tc.detectChanges();

          // we did not change the list => no checks
          expect(log.result(), "check");

          tc.debugElement.componentInstance.value.add(3);

          flushMicrotasks();

          tc.detectChanges();

          // we changed the list => a check
          expect(log.result(), "check; check");
          expect(asNativeElements(tc.debugElement.children),
              hasTextContent('123'));

          // we replaced the list => a check
          tc.debugElement.componentInstance.value =
              new ObservableList.from([5, 6, 7]);

          tc.detectChanges();

          expect(log.result(), "check; check; check");
          expect(asNativeElements(tc.debugElement.children),
              hasTextContent('567'));
        });
      });
    }));
  });
}

@Component(selector: 'dummy')
class Dummy {
  dynamic value;
}

@Component(selector: 'throwing-component')
@View(template: '')
class ThrowingComponent {
  ThrowingComponent() {
    functionThatThrows();
  }
}

@Component(selector: 'throwing-component2')
@View(template: '')
class ThrowingComponent2 {
  ThrowingComponent2() {
    functionThatThrowsNonError();
  }
}

@proxy
class PropModel implements Map {
  final String foo = 'foo-prop';

  operator [](_) => 'foo-map';

  noSuchMethod(_) {
    throw 'property not found';
  }
}

@Component(selector: 'property-access')
@View(template: '''prop:{{model.foo}};map:{{model['foo']}}''')
class PropertyAccess {
  final model = new PropModel();
}

@Component(selector: 'no-property-access')
@View(template: '''{{model.doesNotExist}}''')
class NoPropertyAccess {
  final model = new PropModel();
}

@Component(selector: 'on-change', inputs: const ['prop'])
@View(template: '')
class OnChangeComponent implements OnChanges {
  Map changes;
  String prop;

  @override
  void ngOnChanges(Map changes) {
    this.changes = changes;
  }
}

@Component(
    selector: 'component-with-observable-list',
    changeDetection: ChangeDetectionStrategy.OnPush,
    inputs: const [
      'list'
    ],
    providers: const [
      const Provider(IterableDiffers,
          useValue: const IterableDiffers(const [
            const ObservableListDiffFactory(),
            const DefaultIterableDifferFactory()
          ]))
    ])
@View(
    template:
        '<span *ngFor="let item of list">{{item}}</span><directive-logging-checks></directive-logging-checks>',
    directives: const [NgFor, DirectiveLoggingChecks])
class ComponentWithObservableList {
  Iterable list;
}

@Directive(selector: 'directive-logging-checks')
class DirectiveLoggingChecks implements DoCheck {
  Log log;

  DirectiveLoggingChecks(this.log);

  ngDoCheck() => log.add("check");
}
