#!/bin/bash

# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

# Use only one worker per task to limit resource usage on travis
export BUILD_MAX_WORKERS_PER_TASK=1

pushd $PKG
pub upgrade
./tool/travis.sh
