@TestOn('browser')
import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'host_annotation_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  /// Returns the root [Element] created by initializing [component].
  Future<Element> rootElementOf<T>(ComponentFactory<T> component) {
    final testBed = NgTestBed.forComponent<T>(component);
    return testBed.create().then((fixture) => fixture.rootElement);
  }

  group('@HostBinding', () {
    test('should assign "title" based on a static', () async {
      final element = await rootElementOf(
        ng.HostBindingStaticTitleNgFactory,
      );
      expect(element.title, 'Hello World');
    });

    test('should *not* assign "title" based on an inherited static', () async {
      // The language does not inherit static members, so AngularDart inheriting
      // them would (a) seem out of place and (b) make the compilation process
      // for these bindings considerably more complex.
      //
      // This test verifies that nothing is inherited. A user can always use an
      // instance getter or field and everything would work exactly as intended.
      //
      // https://github.com/dart-lang/angular/issues/1272
      final element = await rootElementOf(
        ng.HostBindingStaticTitleNotInheritedNgFactory,
      );
      expect(element.title, isEmpty);
    });

    // TODO: Add additional tests for @HostBinding.
  });

  group('@HostListener', () {
    // TODO: Add tests for @HostListener.
  });
}

@Component(
  selector: 'host-binding-static',
  template: '',
)
class HostBindingStaticTitle {
  @HostBinding('title')
  static const hostTitle = 'Hello World';
}

@Component(
  selector: 'host-binding-static-inherited',
  template: '',
)
class HostBindingStaticTitleNotInherited extends HostBindingStaticTitle {}
