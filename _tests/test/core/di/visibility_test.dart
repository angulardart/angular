@Tags(const ['codegen'])
@TestOn('browser')

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

// TODO(leonsenft): expect specific DI error when introduced; b/64980526.
void main() {
  tearDown(disposeAnyRunningTest);

  group('Visibility.none', () {
    test('component should not be injectable by child component', () async {
      final testBed = new NgTestBed<ShouldFailToInjectParentComponent>();
      expect(testBed.create(), throwsInAngular(anything));
    });

    test('directive should not be injectable on same element', () async {
      final testBed = new NgTestBed<ShouldFailToInjectFromElement>();
      expect(testBed.create(), throwsInAngular(anything));
    });

    test('directive should not be injectable in same view', () async {
      final testBed = new NgTestBed<ShouldFailToInjectFromView>();
      expect(testBed.create(), throwsInAngular(anything));
    });

    test('directive should not be injectable in child view', () async {
      final testBed = new NgTestBed<ShouldFailToInjectFromParentView>();
      expect(testBed.create(), throwsInAngular(anything));
    });
  });
}

@Component(
  selector: 'injects-parent',
  template: '',
)
class InjectsParentComponent {
  ShouldFailToInjectParentComponent parent;
  InjectsParentComponent(this.parent);
}

@Component(
  selector: 'should-fail-to-inject-parent-component',
  template: '<injects-parent></injects-parent>',
  directives: const [InjectsParentComponent],
  visibility: Visibility.none,
)
class ShouldFailToInjectParentComponent {}

@Directive(selector: '[visibility-none]', visibility: Visibility.none)
class VisibilityNoneDirective {}

@Component(
  selector: 'injects-directive',
  template: '',
)
class InjectsDirectiveComponent {
  VisibilityNoneDirective directive;
  InjectsDirectiveComponent(this.directive);
}

@Component(
  selector: 'should-fail-to-inject-from-element',
  template: '<injects-directive visibility-none></injects-directive>',
  directives: const [InjectsDirectiveComponent, VisibilityNoneDirective],
)
class ShouldFailToInjectFromElement {}

@Component(
  selector: 'should-fail-to-inject-from-view',
  template: '''
  <div visibility-none>
    <injects-directive></injects-directive>
  </div>
  ''',
  directives: const [InjectsDirectiveComponent, VisibilityNoneDirective],
)
class ShouldFailToInjectFromView {}

@Component(
  selector: 'injects-directive-host',
  template: '<injects-directive></injects-directive>',
  directives: const [InjectsDirectiveComponent],
)
class InjectsDirectiveHostComponent {}

@Component(
  selector: 'should-fail-to-inject-from-parent-view',
  template: '''
  <div visibility-none>
    <injects-directive-host></injects-directive-host>
  </div>
  ''',
  directives: const [
    InjectsDirectiveHostComponent,
    VisibilityNoneDirective,
  ],
)
class ShouldFailToInjectFromParentView {}
