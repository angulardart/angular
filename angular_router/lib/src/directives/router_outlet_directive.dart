// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:angular/angular.dart';

import '../lifecycle.dart';
import '../route_definition.dart';
import '../router/router.dart';
import '../router/router_impl.dart';
import '../router/router_outlet_token.dart';
import '../router/router_state.dart';

/// Reserves a location in the DOM as an outlet for the AngularDart [Router].
///
/// A router outlet renders part of the current route in a hierarchical fashion;
/// that is, multiple router outlets may be embedded inside of each-other, with
/// each outlet responsible for rendering a part of the URL:
/// ```html
/// <!-- Imagine "/users/bob" is being rendered -->
///
/// <template router-outlet>
///   <!-- view of "UsersShellComponent" -->
///   <template router-outlet>
///     <!-- view of "UserViewComponent" -->
///   </template>
/// </template>
/// ```
@Directive(
  selector: 'router-outlet',
)
class RouterOutlet implements OnInit, OnDestroy {
  final ViewContainerRef _viewContainerRef;
  final ComponentResolver _componentResolver;
  final Router _router;
  final bool isRootOutlet;

  // A mapping of {ComponentFactory} -> created {ComponentRef}.
  final _loadedComponents = <ComponentFactory, ComponentRef>{};

  // Factory that was used to create the active component.
  ComponentFactory _activeComponentFactory;

  // Route definitions registered with this outlet.
  List<RouteDefinition> _routes = const [];

  RouterOutlet(
    @Optional() @SkipSelf() RouterOutlet parentOutlet,
    @Optional() RouterOutletToken token,
    this._viewContainerRef,
    this._componentResolver,
    this._router,
  )
      : isRootOutlet = parentOutlet == null {
    token?.routerOutlet = this;
  }

  ComponentRef get _activeComponent {
    return _loadedComponents[_activeComponentFactory];
  }

  @Input()
  set routes(List<RouteDefinition> routes) {
    assert(() {
      for (final route in routes) {
        route.assertValid();
      }
      var hasDefault = false;
      for (final route in routes) {
        if (route.useAsDefault) {
          if (hasDefault) {
            throw new StateError('Only one route can be used as default');
          }
          hasDefault = true;
        }
      }
      return true;
    });
    _routes = routes;
  }

  /// Route definitions registered with this outlet.
  List<RouteDefinition> get routes => _routes ?? [];

  @override
  void ngOnInit() {
    if (isRootOutlet) {
      (_router as RouterImpl).registerRootOutlet(this);
    }
  }

  @override
  void ngOnDestroy() {
    _activeComponent?.destroy();
    _viewContainerRef.clear();
    if (isRootOutlet) {
      (_router as RouterImpl).unregisterRootOutlet(this);
    }
  }

  Future<ComponentFactory> _coerceFactory(Object typeOrFactory) async {
    if (typeOrFactory is ComponentFactory) {
      return typeOrFactory;
    }
    if (typeOrFactory is Type) {
      return _componentResolver.resolveComponent(typeOrFactory);
    }
    throw new ArgumentError('Invalid type: $typeOrFactory.');
  }

  /// Instantiates a component [typeOrFactory] to prepare it for rendering.
  ///
  /// Internally maintains a cache of created components.
  Future<ComponentRef> prepare(ComponentFactory component) async {
    return _loadedComponents.putIfAbsent(component, () {
      final componentRef = component.create(new Injector.map({
        RouterOutletToken: new RouterOutletToken(),
      }, _viewContainerRef.injector));
      componentRef.changeDetectorRef.detectChanges();
      return componentRef;
    });
  }

  /// Activates and renders [component] within the outlet.
  ///
  /// Show a component of the given type into the outlet. If that type of
  /// component hasn't already been created, creates one.
  Future<Null> activate(
    Object typeOrFactory,
    RouterState oldState,
    RouterState newState,
  ) async {
    // Canonical factory for creating an instance of the component.
    final component = await _coerceFactory(typeOrFactory);
    var activeInstance = _activeComponent;

    if (activeInstance != null) {
      if (!await _shouldReuse(activeInstance.instance, oldState, newState)) {
        _loadedComponents.remove(_activeComponentFactory);
        activeInstance.destroy();
        // Clear will the detach and destroy all views.
        _viewContainerRef.clear();
      } else {
        for (int i = _viewContainerRef.length - 1; i >= 0; i--) {
          _viewContainerRef.detach(i);
        }
      }
    }

    // Clear and re-insert the component view.
    _activeComponentFactory = component;
    activeInstance = await prepare(component);
    _viewContainerRef.insert(activeInstance.hostView);
    activeInstance.changeDetectorRef.detectChanges();
  }

  Future<bool> _shouldReuse(
    Object instance,
    RouterState oldState,
    RouterState newState,
  ) async =>
      instance is CanReuse && await instance.canReuse(oldState, newState);
}
