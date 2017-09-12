// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// Additional parameters for [Router.navigate].
class NavigationParams {
  /// A map of parameters for the querystring of a URL.
  ///
  /// For example: /url?name=john has queryParameters of {'name': 'john'}
  final Map<String, String> queryParameters;

  /// The hash fragment for a URL.
  final String fragment;

  /// Navigate and push the new state into history.
  final bool updateUrl;

  const NavigationParams(
      {this.queryParameters: const {},
      this.fragment: '',
      this.updateUrl: true});

  /// Runs a dev-mode assertion that the definition is valid.
  ///
  /// When assertions are enabled, throws [StateError]. Otherwise does nothing.
  @mustCallSuper
  @visibleForTesting
  void assertValid() {
    assert(() {
      if (fragment == null) {
        throw new StateError('Must have a non-null `fragment` type');
      }
      if (queryParameters == null) {
        throw new StateError('Must have a non-null `query` type');
      }
      return true;
    });
  }
}
