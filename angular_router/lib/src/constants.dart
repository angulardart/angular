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
const routerDirectives = const [RouterOutlet, RouterLink, RouterLinkActive];

/// The main [Router] providers.
///
/// The [routerProviders] should be added to the providers during the
/// main app's bootstrap.
/// ```
/// bootstrap(MyAppComponent, [routerProviders]);
/// ```
const routerProviders = const [
  const Provider(LocationStrategy, useClass: PathLocationStrategy),
  const Provider(PlatformLocation, useClass: BrowserPlatformLocation),
  const Provider(Location),
  const Provider(Router, useClass: RouterImpl)
];

/// The main [Router] providers when using hash routing.
///
/// The [routerProvidersHash] should be added to the providers during the
/// main app's bootstrap.
/// ```
/// bootstrap(MyAppComponent, [routerProvidersHash]);
/// ```
const routerProvidersHash = const [
  const Provider(LocationStrategy, useClass: HashLocationStrategy),
  const Provider(PlatformLocation, useClass: BrowserPlatformLocation),
  const Provider(Location),
  const Provider(Router, useClass: RouterImpl)
];
