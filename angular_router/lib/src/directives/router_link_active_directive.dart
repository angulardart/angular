// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:collection/collection.dart';
import 'package:angular/angular.dart';

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
@Directive(selector: '[routerLinkActive]', visibility: Visibility.none)
class RouterLinkActive implements AfterViewInit, OnDestroy {
  final Element _element;
  final Router _router;

  StreamSubscription _routeChanged;
  List<String> _classes;

  @ContentChildren(RouterLink)
  QueryList<RouterLink> links;

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
    } else {
      // Only throw in production.
      assert(() {
        throw new ArgumentError(
          'Expected a string or list of strings. Got $classes.',
        );
      });
    }
  }

  void _update(RouterState routerState) {
    if (routerState != null &&
        links.isNotEmpty &&
        links.any((link) {
          if (link.url.path != routerState.path) {
            return false;
          }
          // Only check queryParameter/fragment if included in the [routerLink].
          if (link.url.queryParameters.length > 0 &&
              !const MapEquality().equals(
                  link.url.queryParameters, routerState.queryParameters)) {
            return false;
          }
          if (link.url.fragment.length > 0 &&
              link.url.fragment != routerState.fragment) {
            return false;
          }

          return true;
        })) {
      _element.classes.addAll(_classes);
    } else {
      _element.classes.removeAll(_classes);
    }
  }
}
