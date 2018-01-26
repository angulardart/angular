import 'package:angular/angular.dart' show Provider;

import 'src/location.dart';
import 'src/location/testing/mock_location_strategy.dart';
import 'src/router/router.dart';
import 'src/router/router_impl.dart';

export 'src/location/testing/mock_location_strategy.dart';

/// The main router providers for testing.
///
/// Add this module to your test bed for testing your route configuration or
/// components with dependencies on the router.
///
/// ```
/// final testBed = new NgTestBed<TestComponent>().addProviders([
///   routerProvidersTest,
/// ]);
/// ```
const routerProvidersTest = const [
  const Provider(LocationStrategy, useClass: MockLocationStrategy),
  const Provider(Location),
  const Provider(Router, useClass: RouterImpl),
];
