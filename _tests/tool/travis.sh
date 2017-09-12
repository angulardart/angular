#!/bin/bash

# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

dartanalyzer --fatal-warnings .

dartium --version
dart test/source_gen/template_compiler/generate.dart
pub run test -p vm -x codegen
pub run angular_test \
    --serve-arg=--port=8080 \
    --test-arg=--platform=dartium \
    --test-arg=--tags=codegen \
    --test-arg=--exclude-tags=known_pub_serve_failure
