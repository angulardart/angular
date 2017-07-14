#!/bin/bash

# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

pushd $PKG
pub upgrade

dartanalyzer --fatal-warnings .

if [ "$PKG" == "_tests" ]; then
  dart test/source_gen/template_compiler/generate.dart
fi

if [ "$PKG" == "_tests" ] || [ "$PKG" == "angular_test" ]; then
  pub run test
fi

if [ "$TRAVIS_DART_VERSION" == "stable" ]; then
  echo Any unformatted files?
  dartfmt -n --set-exit-if-changed .
fi
