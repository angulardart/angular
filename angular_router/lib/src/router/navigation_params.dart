// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:angular/src/runtime.dart';
import 'package:meta/meta.dart';

/// Additional parameters for [Router.navigate].
class NavigationParams {
  /// A map of parameters for the querystring of a URL.
  ///
  /// For example: /url?name=john has queryParameters of {'name': 'john'}
  final Map<String, String> queryParameters;

  /// The hash fragment for a URL.
  final String fragment;

  /// Whether to force the router to navigate.
  ///
  /// Normally the router won't navigate if the path, query parameters, and
  /// fragment identifier are the same as those of the current route. Setting
  /// this to true overrides that check and navigates regardless.
  final bool reload;

  /// Whether to replace the current history entry or create a new one.
  ///
  /// This can be used to replace the current route upon navigation and prevent
  /// it from being navigated to again when manipulating browser history.
  final bool replace;

  /// Navigate and push the new state into history.
  final bool updateUrl;

  const NavigationParams({
    this.queryParameters = const {},
    this.fragment = '',
    this.reload = false,
    this.replace = false,
    this.updateUrl = true,
  });

  /// Runs a dev-mode assertion that the definition is valid.
  ///
  /// When assertions are enabled, throws [StateError]. Otherwise does nothing.
  @mustCallSuper
  void assertValid() {
    if (!isDevMode) {
      return;
    }
    if (fragment == null) {
      throw StateError('Must have a non-null `fragment` type');
    }
    if (queryParameters == null) {
      throw StateError('Must have a non-null `query` type');
    }
  }
}
