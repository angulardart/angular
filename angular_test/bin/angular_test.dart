// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// Runs all tests using `pub run test` in the specified directory.
///
/// Tests that require code generation proxies through `pub serve`.
void main() {
  final command = '"pub run build_runner test"';
  stderr.writeln('No longer supported. Use $command instead');
  exitCode = 1;
}
