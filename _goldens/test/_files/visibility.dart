import 'package:angular/angular.dart';

abstract class Dependency {}

@Component(
  selector: 'dependent',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class Dependent {
  Dependent(Dependency _);
}

@Component(
  selector: 'dependency-with-dependent-in-view',
  template: '<dependent></dependent>',
  directives: const [Dependent],
  providers: const [
    const Provider(Dependency, useExisting: DependencyWithDependentInView),
  ],
)
class DependencyWithDependentInView implements Dependency {}

@Component(
  selector: 'dependency-with-content',
  template: '<ng-content></ng-content>',
  providers: const [
    const Provider(Dependency, useExisting: DependencyWithContent),
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
  directives: const [Dependency, Dependent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DependencyAndDependentInView {}
