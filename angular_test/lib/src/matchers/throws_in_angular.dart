// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:matcher/matcher.dart';
import 'package:test/test.dart';
import 'package:angular/src/facade/exceptions.dart';

/// Returns a matcher that will match a caught exception that matches [matcher].
///
/// Unlike the normal `throws` matcher, it will automatically un-wrap internal
/// Angular exceptions and check the underlying (base) exception against
/// [matcher].
///
/// ## Example use:
/// ```dart
/// expect(createComponent(), throwsInAngular(isStateError));
/// ```
Matcher throwsInAngular(Matcher matcher) => throwsA(new _OrWrapped(matcher));

class _OrWrapped extends Matcher {
  final Matcher _typeMatcher;

  _OrWrapped(this._typeMatcher);

  @override
  Description describe(Description description) => description
      .add('Matches ')
      .addDescriptionOf(_typeMatcher)
      .add(' or an Angular exception that wraps another exception');

  @override
  bool matches(item, _) {
    while (item is WrappedException) {
      item = item.originalException;
    }
    return _typeMatcher.matches(item, _);
  }
}
