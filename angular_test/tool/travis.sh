#!/bin/bash

# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

dartanalyzer --fatal-warnings .

pub run test -p vm -x codegen
dart tool/build.dart
pub run build_runner:create_merged_dir --script=tool/build.dart -o build
pub run test \
    --precompiled=build \
    --platform=chrome \
    --tags=codegen \
    --timeout=4x \
    -x skip_on_travis \
    -j1
