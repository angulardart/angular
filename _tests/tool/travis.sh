#!/bin/bash

# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

dartanalyzer --fatal-warnings .

pub run test -p vm -x codegen
pub run build_runner build --low-resources-mode
pub run build_runner:create_merged_dir \
    --script=.dart_tool/build/entrypoint/build.dart -o build
pub run test --precompiled=build --platform=chrome --tags=codegen \
    --exclude-tags=known_pub_serve_failure -j1 test/common
pub run test --precompiled=build --platform=chrome --tags=codegen \
    --exclude-tags=known_pub_serve_failure -j1 test/compiler
pub run test --precompiled=build --platform=chrome --tags=codegen \
    --exclude-tags=known_pub_serve_failure -j1 test/core
pub run test --precompiled=build --platform=chrome --tags=codegen \
    --exclude-tags=known_pub_serve_failure -j1 test/di
pub run test --precompiled=build --platform=chrome --tags=codegen \
    --exclude-tags=known_pub_serve_failure -j1 test/integration
pub run test --precompiled=build --platform=chrome --tags=codegen \
    --exclude-tags=known_pub_serve_failure -j1 test/platform
pub run test --precompiled=build --platform=chrome --tags=codegen \
    --exclude-tags=known_pub_serve_failure -j1 test/security
pub run test --precompiled=build --platform=chrome --tags=codegen \
    --exclude-tags=known_pub_serve_failure -j1 test/source_gen
pub run test --precompiled=build --platform=chrome --tags=codegen \
    --exclude-tags=known_pub_serve_failure -j1 test/symbol_inspector
