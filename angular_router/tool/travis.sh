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

pub run test -p vm
dart tool/build.dart
pub run test --precompiled=build --platform=chrome -j1

