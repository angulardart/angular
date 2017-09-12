#!/bin/bash

# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

# Analyze the lib directory seperately...
dartanalyzer --fatal-warnings lib

# ...from the tool directory
pushd tools/analyzer_plugin
pub upgrade
dartanalyzer --fatal-warnings .
