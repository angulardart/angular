// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'router/navigation_params.dart';
import 'router/router_state.dart';

/// An interface that can be extended in order to hook into a route navigation.
///
/// A class should extend this class and be injected along with the router to
/// hook into route navigation.
///
/// ```
/// class MyHook extends RouterHook {}
///
/// @GenerateInjector([
///   ClassProvider(RouterHook, useClass: MyHook),
///   routerProviders,
/// ])
/// final InjectorFactory injector = ng.injector$Injector;
/// ```
///
/// Some example uses could include programmatically redirecting or preserving
/// navigation params.
abstract class RouterHook {
  /// Called by the router to transform the path before a route navigation.
  ///
  /// The client should return a future that completes with the desired new
  /// path for a specified route navigation.
  ///
  /// You can use `async` in order to simplify when returning synchronously:
  ///
  /// ```
  /// class MyHook extends RouterHook {
  ///   @override
  ///   Future<String> navigationPath(String _, NavigationParams __) async {
  ///     // Maybe there is only a homepage, so redirect all to homepage.
  ///     return '';
  ///   }
  /// }
  /// ```
  Future<String> navigationPath(String path, NavigationParams params) async {
    // Provided as a default if someone extends or mixes-in this interface.
    return path;
  }

  /// Called by the router to transform the params before a route navigation.
  ///
  /// The client should return a future that completes with the desired new
  /// [NavigationParams] for a specified route navigation.
  ///
  /// You can use `async` in order to simplify when returning synchronously:
  ///
  /// ```
  /// class MyHook extends RouterHook {
  ///   MyHook(this._injector);
  ///
  ///   final Injector _injector;
  ///
  ///   // Lazily inject `Router` to avoid cyclic dependency.
  ///   Router _router;
  ///   Router get router => _router ??= _injector.provideType(Router);
  ///
  ///   @override
  ///   Future<NavigationParams> navigationParams(
  ///       String _, NavigationParams params) async {
  ///     // Combine the query parameters with existing ones.
  ///     return NavigationParams(
  ///       queryParameters: {
  ///         ...?router.current?.queryParameters,
  ///         ...params.queryParameters,
  ///       },
  ///     );
  ///   }
  /// }
  /// ```
  Future<NavigationParams> navigationParams(
      String path, NavigationParams params) async {
    // Provided as a default if someone extends or mixes-in this interface.
    return params;
  }

  /// Called by the router to indicate if a component canActivate.
  ///
  /// The client should return a future that completes with the whether the
  /// componentInstance should be activated. If the component extends the
  /// [CanActivate] lifecycle, that will override this behavior.
  ///
  /// You can use `async` in order to simplify when returning synchronously:
  ///
  /// ```
  /// class MyHook extends RouterHook {
  ///   final AuthService _authService;
  ///
  ///   @override
  ///   Future<bool> canActivate(
  ///       Object component, RouterState _, RouterState __) async {
  ///     // Make the default behavior to block all LoginRequired components
  ///     // unless logged in.
  ///     return _authService.isLoggedIn || component is! LoginRequired;
  ///   }
  /// }
  /// ```
  Future<bool> canActivate(Object componentInstance, RouterState oldState,
      RouterState newState) async {
    // Provided as a default if someone extends or mixes-in this interface.
    return true;
  }

  /// Called by the router to indicate if a component canDeactivate.
  ///
  /// The client should return a future that completes with the whether the
  /// componentInstance should be deactivated. If the component extends the
  /// [CanDeactivate] lifecycle, that will override this behavior.
  ///
  /// You can use `async` in order to simplify when returning synchronously:
  ///
  /// ```
  /// class MyHook extends RouterHook {
  ///   final Window _window;
  ///
  ///   @override
  ///   Future<bool> canDeactivate(
  ///       Object component, RouterState _, RouterState __) async {
  ///     // Always ask if the user wants to navigate away from the page.
  ///     return _window.confirm('Discard changes?');
  ///   }
  /// }
  /// ```
  Future<bool> canDeactivate(Object componentInstance, RouterState oldState,
      RouterState newState) async {
    // Provided as a default if someone extends or mixes-in this interface.
    return true;
  }

  /// Called by the router to indicate if navigation is allowed.
  ///
  /// The client should return a future that completes with the whether the
  /// navigation can happen. If the component extends the [CanNavigate]
  /// lifecycle, that will override this behavior.
  ///
  /// You can use `async` in order to simplify when returning synchronously:
  ///
  /// ```
  /// class MyHook extends RouterHook {
  ///   final Window _window;
  ///
  ///   @override
  ///   Future<bool> canNavigate() async {
  ///     // Always ask if the user wants to navigate away from the page.
  ///     return _window.confirm('Discard changes?');
  ///   }
  /// }
  /// ```
  Future<bool> canNavigate() async {
    // Provided as a default if someone extends or mixes-in this interface.
    return true;
  }

  /// Called by the router to indicate if a component canReuse.
  ///
  /// The client should return a future that completes with the whether the
  /// componentInstance should be reused. If the component extends the
  /// [CanReuse] lifecycle, that will override this behavior.
  ///
  /// You can use `async` in order to simplify when returning synchronously:
  ///
  /// ```
  /// class MyHook extends RouterHook {
  ///   @override
  ///   Future<bool> canReuse(
  ///       Object _, RouterState __, RouterState ___) async {
  ///     // Make the default behavior to always reuse the component.
  ///     return true;
  ///   }
  /// }
  /// ```
  Future<bool> canReuse(Object componentInstance, RouterState oldState,
      RouterState newState) async {
    // Provided as a default if someone extends or mixes-in this interface.
    return false;
  }
}
