@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular/experimental.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'expect_no_changes_dev_mode_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should throw during change detection', () async {
    final testBed = NgTestBed.forComponent(
      ng.IllegalChangeDetectionComponentNgFactory,
    );
    expect(
      testBed.create(),
      throwsA(predicate(
        (e) => '$e'.contains(
          'Expression has changed after it was checked',
        ),
      )),
    );
  });

  test('misses throwing on a non-primitive expression', () {
    final testBed = NgTestBed.forComponent(
      ng.NonPrimitiveBindingNgFactory,
    );
    expect(testBed.create(), completes);
  });

  group('debugCheckBindings', () {
    setUpAll(() {
      debugCheckBindings(true);
    });

    tearDownAll(() {
      debugCheckBindings(false);
    });

    test('should throw during change detection of a primitive', () async {
      final testBed = NgTestBed.forComponent(
        ng.IllegalChangeDetectionComponentNgFactory,
      );
      expect(
        testBed.create(),
        throwsA(predicate(
          (e) => '$e'.contains(
            'An expression bound in an AngularDart template',
          ),
        )),
      );
    });

    test('should throw during change detection of a non-primitive', () async {
      final testBed = NgTestBed.forComponent(
        ng.NonPrimitiveBindingNgFactory,
      );
      expect(
        testBed.create(),
        throwsA(predicate(
          (e) => '$e'.contains(
            'An expression bound in an AngularDart template',
          ),
        )),
      );
    });

    // TODO(b/128999811): Add more tests for various binding types.
    //
    // As of right now, virtually all bindings will have an omitted (UNKNOWN)
    // expression and context, both because TextBinding(...) is missing the
    // context itself and because some types of expressions in the AST do not
    // have source information.
    //
    // We should add various binding types, and track which ones do and do not
    // have source information in order to make this problem more tractable.
  });
}

@Component(
  selector: 'illegal-change-detection',
  template: r'''
    <div>{{counter}}</div>
  ''',
)
class IllegalChangeDetectionComponent {
  var _counter = 0;
  int get counter => _counter++;
}

@Component(
  selector: 'non-primitive-bindings',
  directives: [BindAnythingComponent],
  template: r'''
    <bind-anything [value]="value"></bind-anything>
  ''',
)
class NonPrimitiveBinding {
  var _value = Duration(seconds: 1);

  // This is an illegal binding, but it does not use primitives.
  Duration get value => _value = Duration(seconds: _value.inSeconds + 1);
}

@Component(
  selector: 'bind-anything',
  template: '',
)
class BindAnythingComponent {
  @Input()
  Object value;
}
