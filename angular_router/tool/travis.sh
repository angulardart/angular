#!/bin/bash

# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

pub run build_runner build --low-resources-mode
pub run build_runner:create_merged_dir \
    --script=.dart_tool/build/entrypoint/build.dart -o build

