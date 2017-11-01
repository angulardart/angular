#!/bin/bash

# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

dartanalyzer --fatal-warnings lib test

pushd example
pub upgrade
dartanalyzer --fatal-warnings .
# TODO(alorenzen): Run angular_test here.
popd

dartium --version
pub run test -p vm
# TODO(alorenzen): Refactor the build.dart script to a more common location.
pub run angular_test \
    --experimental-serve-script=../_tests/tool/build.dart \
    --verbose \
    --port=8080 \
    --test-arg=--platform=chrome
