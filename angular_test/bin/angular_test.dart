// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:angular_test/src/bin/runner.dart';

/// Runs all tests using `pub run test` in the specified directory.
///
/// Tests that require code generation proxies through `pub serve`.
Future<Null> main(List<String> args) => run(args);
