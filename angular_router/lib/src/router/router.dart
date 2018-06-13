// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../directives/router_outlet_directive.dart';
import 'navigation_params.dart';
import 'router_state.dart';

/// Result of the Navigation when calling Router.navigate.
enum NavigationResult { SUCCESS, BLOCKED_BY_GUARD, INVALID_ROUTE }

/// The Angular router, which is represented as a stream of state changes.
///
/// In order to be notified when navigation is occurring listen to the stream:
/// ```
/// class MyComponent implements OnInit {
///   final Router _router;
///
///   MyComponent(this._router);
///
///   @override
///   void ngOnInit() {
///     _router.onRouteActivated.listen((newState) {
///       print('Navigating from ${_router.current} to $newState');
///     });
///   }
/// }
/// ```
abstract class Router {
  /// Current state of the router.
  ///
  /// Note this isn't updated until after all `onActivate` implementations are
  /// invoked, and [onRouteActivated] fires.
  RouterState get current;

  /// Emits the requested path when navigation starts.
  ///
  /// This occurs after all active [CanNavigate] implementations permit
  /// navigation, but before any other router lifecycle method are invoked. Note
  /// that this does not necessary indicate the start of a successful
  /// navigation, as it could be blocked by another lifecycle implementation or
  /// be an invalid request.
  ///
  /// Note that for redirected routes, the requested path, not the path it
  /// redirects to, is emitted.
  Stream<String> get onNavigationStart;

  /// Emits the next router state after a new route is activated.
  ///
  /// Note, this should occur before [current] is updated.
  Stream<RouterState> get onRouteActivated => stream;

  @Deprecated("Renamed to 'onRouteActivated'")
  Stream<RouterState> get stream;

  /// Attempts to navigate to a route that matches [path].
  ///
  /// Query parameters and a fragment identifier can be specified in
  /// [navigationParams]. If you wish to navigate to a URL that already encodes
  /// these values, see [navigateByUrl] instead.
  ///
  /// Returns a future which completes after navigation indicating whether
  /// navigation completed successfully, failed because no route matched [path],
  /// or was blocked by a router lifecycle implementor.
  Future<NavigationResult> navigate(
    String path, [
    NavigationParams navigationParams,
  ]);

  /// Attempts to navigate to a route that matches [url].
  ///
  /// This method is the same as [navigate], except that query parameters and
  /// the fragment identifier are de-serialized from [url].
  ///
  /// See [NavigationParams] for documentation on [reload] and [replace] which
  /// serve the same purpose.
  Future<NavigationResult> navigateByUrl(
    String url, {
    bool reload = false,
    bool replace = false,
  });

  /// Registers the root [routerOutlet] and navigates to the current route.
  ///
  /// The root outlet is where the router begins to resolve routes upon
  /// navigation. Does nothing if the root outlet is already set.
  void registerRootOutlet(RouterOutlet routerOutlet);

  /// Unregisters the root [routerOutlet].
  ///
  /// Does nothing if [routerOutlet] isn't the current root outlet.
  void unregisterRootOutlet(RouterOutlet routerOutlet);
}
