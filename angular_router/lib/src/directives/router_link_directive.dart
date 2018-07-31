// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html'
    show AnchorElement, Element, Event, KeyboardEvent, KeyCode, MouseEvent;

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
@Directive(
  selector: '[routerLink]',
)
class RouterLink implements OnDestroy {
  final Router _router;
  final Location _location;
  final String _target;

  StreamSubscription<KeyboardEvent> _keyPressSubscription;
  String _routerLink;
  String _cachedVisibleHref;
  Url _cachedUrl;

  RouterLink(this._router, this._location, @Attribute('target') this._target,
      Element element) {
    // The browser will synthesize a click event for anchor elements when they
    // receive an Enter key press. For other elements, we must manually add a
    // key press listener to ensure the link remains keyboard accessible.
    if (element is! AnchorElement) {
      _keyPressSubscription = element.onKeyPress.listen(_onKeyPress);
    }
  }

  @Input()
  set routerLink(String routerLink) {
    _routerLink = routerLink;
    _cachedVisibleHref = null;
    _cachedUrl = null;
  }

  Url get url {
    if (_cachedUrl == null) {
      final parsedUrl = Url.parse(_routerLink);
      _cachedUrl = Url(
        _location.normalizePath(parsedUrl.path),
        fragment: parsedUrl.fragment,
        queryParameters: parsedUrl.queryParameters,
      );
    }
    return _cachedUrl;
  }

  /// Indicates the URL when the hovering on the link.
  @HostBinding('attr.href')
  String get visibleHref {
    // Memoize invoking this external function.
    return _cachedVisibleHref ??= _location.prepareExternalUrl(_routerLink);
  }

  @override
  void ngOnDestroy() {
    _keyPressSubscription?.cancel();
  }

  @HostListener('click')
  void onClick(MouseEvent event) {
    // Control-click (or Command-click) opens link in new tab.
    if (event.ctrlKey || event.metaKey) return;
    _trigger(event);
  }

  void _onKeyPress(KeyboardEvent event) {
    // Control-click (or Command-click) opens link in new tab.
    if (event.keyCode != KeyCode.ENTER || event.ctrlKey || event.metaKey) {
      return;
    }
    _trigger(event);
  }

  void _trigger(Event event) {
    // The presence of target="_blank" opens link in new tab.
    if (_target == null || _target == '_self') {
      event.preventDefault();
      _router.navigate(
          url.path,
          NavigationParams(
              queryParameters: url.queryParameters, fragment: url.fragment));
    }
  }
}
