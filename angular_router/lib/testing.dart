import 'package:angular/angular.dart'
    show ClassProvider, ExistingProvider, Module;

import 'src/location.dart';
import 'src/location/testing/mock_location_strategy.dart';
import 'src/router/router.dart';
import 'src/router/router_impl.dart';

export 'src/location/testing/mock_location_strategy.dart';
export 'src/route_definition.dart'
    show
        DeferredRouteDefinition,
        RedirectRouteDefinition,
        ComponentRouteDefinition;

/// The main [Router] providers for testing.
///
/// Add these providers to your test bed for testing your route configuration or
/// components with dependencies on the router.
///
/// ```
/// @Component(
///   selector: '...',
///   providers: [
///     routerProvidersTest,
///   ],
/// )
/// class TestComponent {}
/// ```
const routerProvidersTest = [
  ClassProvider(MockLocationStrategy),
  ExistingProvider(LocationStrategy, MockLocationStrategy),
  ClassProvider(Location),
  ClassProvider(Router, useClass: RouterImpl),
];

/// The main [Router] DI module for testing.
///
/// Add this module to your test bed for testing your route configuration or
/// components with dependencies on the router.
///
/// ```
/// @GenerateInjector.fromModules([routerTestModule])
/// final InjectorFactory testInjector = ng.testInjector$Injector;
/// ...
/// final testBed = NgTestBed(
///     ng.TestComponentNgFactory,
///     rootInjector: testInjector);
/// ```
const routerTestModule = Module(provide: routerProvidersTest);
