@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'inlined_providers.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

/// Shows the issues with inlining providers into a parent component.
void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    ChildComponentProvidingA$B$C,
    ChildComponentWithNgContentProviding$D,
    ChildComponentInjecting$D,
    ChildComponentWithVisibilityAll,
    DirectiveProviding$A2$D2,
  ],
  template: '''
    <child-component-providing-a-b-c></child-component-providing-a-b-c>

    <child-component-providing-a-b-c></child-component-providing-a-b-c>

    <child-component-with-ngcontent-providing-d>
      <child-component-injecting-d></child-component-injecting-d>
    </child-component-with-ngcontent-providing-d>

    <child-component-with-visibility-all></child-component-with-visibility-all>

    <child-component-providing-a-b-c directive-providing-a2-d2>
    </child-component-providing-a-b-c>

    <child-component-with-ngcontent-providing-d directive-providing-a2-d2>
      <child-component-injecting-d></child-component-injecting-d>
    </child-component-with-ngcontent-providing-d>
  ''',
)
class GoldenComponent {
  GoldenComponent(Injector i) {
    deopt(i.get);
  }
}

class A {}

class B {}

class C {}

@Component(
  selector: 'child-component-providing-a-b-c',
  template: '',
  providers: [
    A,
    B,
    C,
  ],
)
class ChildComponentProvidingA$B$C {}

class D {}

@Component(
  selector: 'child-component-with-ngcontent-providing-d',
  template: '<ng-content></ng-content>',
  providers: [
    D,
  ],
)
class ChildComponentWithNgContentProviding$D {}

@Component(
  selector: 'child-component-injecting-d',
  template: '',
)
class ChildComponentInjecting$D {
  ChildComponentInjecting$D(D _);
}

class A2 implements A {}

class D2 implements D {}

@Component(
  selector: 'child-component-with-visibility-all',
  template: '',
  visibility: Visibility.all,
)
class ChildComponentWithVisibilityAll {}

@Directive(
  selector: '[directive-providing-a2-d2]',
  providers: [
    ClassProvider(A, useClass: A2),
    ClassProvider(D, useClass: D2),
  ],
)
class DirectiveProviding$A2$D2 {}
