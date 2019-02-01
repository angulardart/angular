// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'router/router_state.dart';

// Interfaces that can be implemented/extended/mixed-in in order to inform
// behavior of the router. It's assumed that all of these interfaces are applied
// directly on `@Component` annotated classes that are created by a router
// outlet during SPA (single-page application) navigation.

/// A lifecycle interface that allows conditionally activating a new route.
///
/// Component classes should `implement` this if they will be navigated to as
/// part of a route definition and would like to determine if the route should
/// be allowed.
///
/// Some example uses could include only allowing logged in users access to a
/// "profile editor" component (not as a security measure) or to record what
/// the previous route is for analytics before navigating.
abstract class CanActivate {
  /// Called by the router when a transition is requested from router states.
  ///
  /// The client should return a future that completes with `true` in order to
  /// accept the transition, or completes with `false` in order to reject it
  /// (and prevent the routing from occurring).
  ///
  /// You can use `async` in order to simplify when returning synchronously:
  ///
  /// ```
  /// class MyComponent implements CanActivate {
  ///   @override
  ///   Future<bool> canActivate(RouterState _, RouterState __) async {
  ///     // Maybe this page isn't ready yet for production, so always reject.
  ///     return false;
  ///   }
  /// }
  /// ```
  ///
  /// This lifecycle occurs *after* `CanDeactivate.canDeactivate`.
  Future<bool> canActivate(RouterState current, RouterState next) async {
    // Provided as a default if someone extends or mixes-in this interface.
    return true;
  }
}

/// A lifecycle interface that allows conditionally deactivating a route.
///
/// Routed components should implement this to prevent deactivation based on the
/// next [RouterState]. Prefer [CanNavigate] if the next [RouterState] isn't
/// needed.
///
/// This interface is checked after constructing the components necessary to
/// resolve the next [RouterState].
///
/// An example use case is preventing deactivation if the current and next route
/// haven't changed, but navigation was triggered for another reason such as an
/// added query parameter.
abstract class CanDeactivate {
  /// Called by the router when a transition is requested between router states.
  ///
  /// The client should return a future that completes with `true` in order to
  /// accept the transition, or completes with `false` in order to reject it
  /// (and prevent the routing from occurring).
  ///
  /// ```
  /// class MyComponent implements CanDeactivate {
  ///   @override
  ///   Future<bool> canDeactivate(
  ///     RouterState current,
  ///     RouterState next,
  ///   ) async =>
  ///       current.parameters['id'] != next.parameters['id'];
  /// }
  /// ```
  ///
  /// This lifecycle occurs *before* `CanActivate.canActivate`.
  Future<bool> canDeactivate(RouterState current, RouterState next) async {
    // Provided as a default if someone extends or mixes-in this interface.
    return true;
  }
}

/// A lifecycle interface that allows conditionally preventing navigation.
///
/// Routed components should implement this to prevent navigation regardless of
/// the next [RouterState]. This interface is preferable to [CanDeactivate],
/// which can be used if the next [RouterState] is necessary.
///
/// This interface is checked immediately upon navigation, before constructing
/// the components necessary to resolve the next [RouterState].
///
/// An example use case is preventing navigation if a form has unsaved changes.
abstract class CanNavigate {
  /// Called by the router upon navigation.
  ///
  /// The client should return a future that completes with a boolean indicating
  /// whether the router is allowed to navigate.
  ///
  /// ```
  /// class MyComponent implements CanNavigate {
  ///   bool get _hasFormBeenSaved => ...;
  ///
  ///   @override
  ///   Future<bool> canNavigate() async => _hasFormBeenSaved;
  /// }
  /// ```
  ///
  /// This lifecycle occurs *before* any others during navigation.
  Future<bool> canNavigate();
}

/// A lifecycle interface that allows re-using an existing component instance.
///
/// Component classes should `implement` this if they will be navigated to as
/// part of a route definition and would like to determine whether an instance
/// should be cached for reuse between activations.
abstract class CanReuse {
  /// Called by the router before the route is deactivated, so that the
  /// component instance can notify the router if it should be cached for reuse.
  ///
  /// If this interface is _not_ implemented, the component is always destroyed
  /// and re-created; otherwise the client should return a future that completes
  /// with `true` in order to re-use this instance of the component, or
  /// completes with `false` in order to destroy and re-create a new instance.
  ///
  /// You can use `async` in order to simplify when returning synchronously:
  ///
  /// ```
  /// class MyComponent implements CanReuse {
  ///   @override
  ///   Future<bool> canReuse(RouterState current, RouterState next) async {
  ///     // Always re-use this instance.
  ///     return true;
  ///   }
  /// }
  /// ```
  ///
  /// Or simply mixin or extend this class:
  ///
  /// ```
  /// class MyComponent extends CanReuse {}
  /// ```
  Future<bool> canReuse(RouterState current, RouterState next) async {
    // Provided as a default if someone extends or mixes-in this interface.
    return true;
  }
}

/// A lifecycle interface to notify when a component is activated by a route.
///
/// Component classes should `implement` this if they will be navigated to as
/// part of a route definition and would like to be notified if they were
/// activated due to routing.
abstract class OnActivate {
  /// Called after component is inserted by a router outlet.
  ///
  /// This will occur *after* initial change detection.
  ///
  /// **NOTE**: If the component also extends [CanReuse] and is reused, this
  /// will be called again on the same instance.
  ///
  /// ```dart
  /// class MyComponent extends CanReuse implements OnActivate {
  ///   User user;
  ///
  ///   @override
  ///   void onActivate(_, RouterState current) {
  ///     var userId = current.getParameter('userId');
  ///     getUserById(userId).then((user) => this.user = user);
  ///   }
  /// }
  /// ```
  void onActivate(RouterState previous, RouterState current);
}

/// A lifecycle interface to notify when a component is deactivated by a route.
///
/// Component classes should `implement` this if they will be navigated to as
/// part of a route definition and would like to be notified if they are being
/// deactivated due to routing.
abstract class OnDeactivate {
  /// Called before component deactivation when routing.
  ///
  /// **NOTE**: This is still called even if the component also extends
  /// [CanReuse] and is reused.
  void onDeactivate(RouterState current, RouterState next);
}
