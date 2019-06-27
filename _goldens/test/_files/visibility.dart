import 'package:angular/angular.dart';

abstract class Dependency {}

@Component(
  selector: 'dependent',
  template: '',
)
class Dependent {
  Dependent(Dependency _);
}

@Component(
  selector: 'dependency-with-dependent-in-view',
  template: '<dependent></dependent>',
  directives: [Dependent],
  providers: [
    Provider(Dependency, useExisting: DependencyWithDependentInView),
  ],
)
class DependencyWithDependentInView implements Dependency {}

@Component(
  selector: 'dependency-with-content',
  template: '<ng-content></ng-content>',
  providers: [
    Provider(Dependency, useExisting: DependencyWithContent),
  ],
)
class DependencyWithContent implements Dependency {}

@Component(
  selector: 'dependency-and-dependent-in-view',
  template: '''
    <dependency>
      <dependent></dependent>
    </dependency>
  ''',
  directives: [Dependent],
)
class DependencyAndDependentInView {}

@Component(
  selector: 'has-visibility-all',
  template: '',
  visibility: Visibility.all,
)
class HasVisibilityAll {}

@Component(
  selector: 'has-visibility-local',
  template: '',
)
class HasVisibilityLocal {}
