// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Operation to stabilize the DOM during a test failed.
class WillNeverStabilizeError extends Error {
  final int threshold;

  WillNeverStabilizeError(this.threshold);

  @override
  String toString() => 'Failed to stabilize after $threshold attempts';
}
