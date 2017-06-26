// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:angular_test/src/matchers.dart';
import 'package:test/test.dart';
import 'package:angular/src/facade/exceptions.dart';

void main() {
  test('should catch a non-wrapped exception', () {
    expect(() => throw new StateError('Test'), throwsInAngular(isStateError));
  });

  test('should catch a view-wrapped exception', () {
    expect(
      () => throw new WrappedException('', new StateError('Test'), null, null),
      throwsInAngular(isStateError),
    );
  });
}
