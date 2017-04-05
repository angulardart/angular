@Tags(const ['codegen'])
@TestOn('browser')
library angular2.test.core.linker.deferred_component_test;

import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'deferred_view.dart';

void main() {
  group('Property access', () {
    tearDown(() => disposeAnyRunningTest());
    test('should load deferred component', () async {
      var testBed = new NgTestBed<SimpleContainerTest>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement;
      Element deferredView = element.querySelector('my-deferred-view');
      expect(deferredView, isNotNull);
    });
  });
}

@Component(
    selector: 'simple-container',
    template: '<section>'
        '<my-deferred-view !deferred></my-deferred-view>'
        '</section>',
    directives: const [DeferredChildComponent])
class SimpleContainerTest {}
