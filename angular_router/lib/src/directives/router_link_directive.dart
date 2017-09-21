// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html' show MouseEvent;

import 'package:angular/angular.dart';

import '../location.dart' show Location;
import '../router/navigation_params.dart';
import '../router/router.dart';
import '../url.dart';

/// Creates a listener on the target element that routes to a specified link.
///
/// ```html
/// <a routerLink="/heroes">Heroes</a>
/// ```
/// Can also be used with [RouterPath].
/// ```html
/// <a [routerLink]="heroPath.toUrl()">Heroes</a>
/// ```
///
/// The [routerLink] can contain queryParameters or a fragment, ie: /heroes?a=1.
@Directive(selector: "[routerLink]", visibility: Visibility.none)
class RouterLink {
  final Router _router;
  final Location _location;
  final String _target;

  RouterLink(this._router, this._location, @Attribute('target') this._target);

  @Input()
  set routerLink(String routerLink) {
    _routerLink = routerLink;
    _cachedVisibleHref = null;
    _cachedUrl = null;
  }

  String _routerLink;
  String _cachedVisibleHref;
  Url _cachedUrl;

  Url get url {
    return _cachedUrl ??= Url.parse(_routerLink);
  }

  /// Indicates the URL when the hovering on the link.
  @HostBinding('attr.href')
  String get visibleHref {
    // Memoize invoking this external function.
    return _cachedVisibleHref ??= _location.prepareExternalUrl(_routerLink);
  }

  @HostListener('click', const [r'$event'])
  void onClick(MouseEvent event) {
    if (_target == null || _target == '_self') {
      event.preventDefault();
      _router.navigate(
          url.path,
          new NavigationParams(
              queryParameters: url.queryParameters, fragment: url.fragment));
    }
  }
}
