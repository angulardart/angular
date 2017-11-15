#!/bin/bash

# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

dartanalyzer --fatal-warnings .

pub run test -p vm -x codegen
pub run angular_test \
    --experimental-serve-script=tool/build.dart \
    --verbose \
    --serve-arg=--port=8080 \
    --test-arg=--platform=chrome \
    --test-arg=--tags=codegen \
    --test-arg=--timeout=4x
