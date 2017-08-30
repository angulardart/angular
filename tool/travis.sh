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
  dartium --version
  dart test/source_gen/template_compiler/generate.dart
  pub run test -p vm -x codegen
  pub run angular_test \
      --serve-arg=--port=8080 \
      --test-arg=--platform=dartium \
      --test-arg=--tags=codegen \
      --test-arg=--exclude-tags=known_pub_serve_failure
fi

if [ "$PKG" == "angular_test" ]; then
  dartium --version
  dart test/test_on_travis.dart
fi

if [ "$PKG" == "angular" ]; then
  pushd tools/analyzer_plugin
  pub upgrade
  dartanalyzer --fatal-warnings .
fi
