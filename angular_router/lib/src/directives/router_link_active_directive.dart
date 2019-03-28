// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:collection/collection.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/runtime.dart';

import '../router/router.dart';
import '../router/router_state.dart';
import 'router_link_directive.dart';

/// Adds a CSS class to the bound element when the link's route becomes active.
///
/// ```html
/// <a routerLink="/user/bob" routerLinkActive="active-link">Bob</a>
/// ```
///
/// May also be used on an element containing a [RouterLink].
/// ```html
/// <div routerLinkActive="active-link">
///   <a routerLink="/user/bob">Bob</a>
/// </div>
/// ```
@Directive(
  selector: '[routerLinkActive]',
)
class RouterLinkActive implements AfterViewInit, OnDestroy {
  final Element _element;
  final Router _router;

  StreamSubscription<RouterState> _routeChanged;
  List<String> _classes;

  @ContentChildren(RouterLink)
  List<RouterLink> links;

  RouterLinkActive(this._element, this._router);

  @override
  void ngOnDestroy() => _routeChanged?.cancel();

  @override
  void ngAfterViewInit() {
    _routeChanged = _router.stream.listen(_update);
    _update(_router.current);
  }

  @Input()
  set routerLinkActive(Object classes) {
    if (classes is String) {
      _classes = [classes];
    } else if (classes is List<String>) {
      _classes = classes;
    } else if (isDevMode) {
      throw ArgumentError(
        'Expected a string or list of strings. Got $classes.',
      );
    }
  }

  void _update(RouterState routerState) {
    var isActive = false;
    if (routerState != null) {
      for (var link in links) {
        final url = link.url;
        if (url.path != routerState.path) continue;
        // Only compare query parameters if specified in the [routerLink].
        if (url.queryParameters.isNotEmpty &&
            !const MapEquality<String, String>()
                .equals(url.queryParameters, routerState.queryParameters)) {
          continue;
        }
        // Only compare fragment identifier if specified in the [routerLink].
        if (url.fragment.isNotEmpty && url.fragment != routerState.fragment) {
          continue;
        }
        // The link matches the current router state and should be activated.
        isActive = true;
        break;
      }
    }
    _element.classes.toggleAll(_classes, isActive);
  }
}
