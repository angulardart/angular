// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'router/navigation_params.dart';
import 'router/router_state.dart';

/// An interface that can be extended in order to hook into a route navigation.
///
/// A class should extend this class and be injected along with the router to
/// hook into route navigations.
///
/// ```
/// @Injectable
/// class MyHook implements RouterHook {}
///
/// bootstrap(MyAppComponent, [
///   routerProviders,
///   new Provider(RouterHook, useClass: MyHook)]);
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
  /// @Injectable
  /// class MyHook implements RouterHook {
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
  /// @Injectable
  /// class MyHook implements RouterHook {
  ///   final Router _router;
  ///   MyHook(this._router);
  ///
  ///   @override
  ///   Future<NavigationParams> navigationParams(
  ///       String _, NavigationParams params) async {
  ///     // Combine the query parameters with existing ones.
  ///     return new NavigationParams(
  ///       queryParameters: new Map()
  ///         ..addAll(_router.current.queryParameters)
  ///         ..addAll(params.queryParameters));
  ///   }
  /// }
  /// ```
  Future<NavigationParams> navigationParams(
      String path, NavigationParams params) async {
    // Provided as a default if someone extends or mixes-in this interface.
    return params;
  }

  /// Called by the router programmatically indicate if a component canReuse.
  ///
  /// The client should return a future that completes with the whether the
  /// componentInstance should be reused. If the component extends the
  /// CanReuse lifecycle, that will override this behavior.
  ///
  /// You can use `async` in order to simplify when returning synchronously:
  ///
  /// ```
  /// @Injectable
  /// class MyHook implements RouterHook {
  ///   @override
  ///   Future<NavigationParams> navigationParams(
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
