import 'package:angular/angular.dart';

/// Shows the problems with the compiler pattern of inlining child providers.
///
/// **NOTE**:
/// * [ParentComponent] itself has _no_ providers.
///
@Component(
  selector: 'parent-component',
  directives: [
    ChildComponentProvidingA$B$C,
    ChildComponentWithNgContentProviding$D,
    ChildComponentInjecting$D,
    ChildComponentWithVisibilityAll,
    DirectiveProviding$A2$D2,
  ],
  template: r'''
    <!-- 1 -->
    <child-component-providing-a-b-c></child-component-providing-a-b-c>
    <!-- 2 -->
    <child-component-providing-a-b-c></child-component-providing-a-b-c>
    <!-- 3 -->
    <child-component-with-ngcontent-providing-d>
      <child-component-injecting-d></child-component-injecting-d>
    </child-component-with-ngcontent-providing-d>
    <!-- 4 -->
    <child-component-with-visibility-all></child-component-with-visibility-all>
    <!-- 5 -->
    <child-component-providing-a-b-c directive-providing-a2-d2>
    </child-component-providing-a-b-c>
    <!-- 6 -->
    <child-component-with-ngcontent-providing-d directive-providing-a2-d2>
      <child-component-injecting-d></child-component-injecting-d>
    </child-component-with-ngcontent-providing-d>
  ''',
)
class ParentComponent {}

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
