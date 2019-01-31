// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:angular/angular.dart';

import 'directives/router_link_active_directive.dart';
import 'directives/router_link_directive.dart';
import 'directives/router_outlet_directive.dart';
import 'location.dart';
import 'router/router.dart';
import 'router/router_impl.dart';

/// The main [Router] directives.
///
/// Attach to a @[Component]'s directives when using any other the Router
/// directives.
/// ```
/// @Component(
///   selector: 'my-app',
///   directives: [routerDirectives]
///   template: '<router-outlet></router-outlet>'
/// )
/// class MyApp {}
/// ```
const routerDirectives = [RouterOutlet, RouterLink, RouterLinkActive];

/// The main [Router] providers.
///
/// The [routerProviders] should be added to the app's root injector.
/// ```
/// @GenerateInjector([routerProviders])
/// final InjectorFactory appInjector = ng.appInjector$Injector;
/// ...
/// runApp(ng.MyAppComponentNgFactory, createInjector: appInjector);
/// ```
const routerProviders = [
  ClassProvider(LocationStrategy, useClass: PathLocationStrategy),
  ClassProvider(PlatformLocation, useClass: BrowserPlatformLocation),
  ClassProvider(Location),
  ClassProvider(Router, useClass: RouterImpl)
];

/// The main [Router] DI module.
///
/// The [routerModule] should be added to the app's root injector.
/// ```
/// @GenerateInjector.fromModules([routerModule])
/// final InjectorFactory appInjector = ng.appInjector$Injector;
/// ...
/// runApp(ng.MyAppComponentNgFactory, createInjector: appInjector);
/// ```
const routerModule = Module(provide: routerProviders);

/// The main [Router] providers when using hash routing.
///
/// The [routerProvidersHash] should be added to the app's root injector.
/// ```
/// @GenerateInjector([routerProvidersHash])
/// final InjectorFactory appInjector = ng.appInjector$Injector;
/// ...
/// runApp(ng.MyAppComponentNgFactory, createInjector: appInjector);
/// ```
const routerProvidersHash = [
  ClassProvider(LocationStrategy, useClass: HashLocationStrategy),
  ClassProvider(PlatformLocation, useClass: BrowserPlatformLocation),
  ClassProvider(Location),
  ClassProvider(Router, useClass: RouterImpl)
];

/// The main [Router] DI module when using hash routing.
///
/// The [routerHashModule] should be added to the app's root injector.
/// ```
/// @GenerateInjector.fromModules([routerHashModule])
/// final InjectorFactory appInjector = ng.appInjector$Injector;
/// ...
/// runApp(ng.MyAppComponentNgFactory, createInjector: appInjector);
/// ```
const routerHashModule = Module(provide: routerProvidersHash);
