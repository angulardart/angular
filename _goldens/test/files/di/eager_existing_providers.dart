import 'package:angular/angular.dart';

abstract class EagerProviderA {}

abstract class EagerProviderB {}

abstract class LazyProviderA {}

abstract class LazyProviderB {}

/// This component demonstrates how existing providers are injected eagerly.
///
/// Note that its the act of injecting a provider from the same view in which
/// its defined that makes it eager. Providers which are unused locally are
/// lazy.
@Component(
  selector: 'app',
  directives: [
    InjectsServicesComponent,
    ProvidesServicesComponent,
  ],
  template: r'''
    <provides-services>
      <injects-services></injects-services>
    </provides-services>
  ''',
)
class AppComponent {}

@Component(
  selector: 'provides-services',
  directives: [],
  providers: [
    ExistingProvider(EagerProviderA, ProvidesServicesComponent),
    ExistingProvider(EagerProviderB, ProvidesServicesComponent),
    ExistingProvider(LazyProviderA, ProvidesServicesComponent),
    ExistingProvider(LazyProviderB, ProvidesServicesComponent),
  ],
  template: '<ng-content></ng-content>',
)
class ProvidesServicesComponent
    implements EagerProviderA, EagerProviderB, LazyProviderA, LazyProviderB {}

@Component(
  selector: 'injects-services',
  template: '',
)
class InjectsServicesComponent {
  InjectsServicesComponent(this.a, this.b);

  final EagerProviderA a;
  final EagerProviderB b;
}
