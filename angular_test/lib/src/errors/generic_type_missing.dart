// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This operation is not allowed without specifying a generic type parameter.
class GenericTypeMissingError extends Error {
  final String message;

  GenericTypeMissingError([this.message]);

  @override
  String toString() {
    if (message == null) {
      return 'Generic type required';
    }
    return 'Generic type required: $message';
  }
}
