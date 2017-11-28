#!/bin/bash

# Custom presubmit script that executes dartanalyzer/pub run test.
#
# Keep in sync across this entire repository!
# #############################################################################

# Fast fail the script on failures.
set -e

# Fail on any analysis warnings or errors.
dartanalyzer --fatal-warnings .

# Run any tests that only run on the standalone VM.
pub run test -P compiler

# Generate code required for executing in the browser.
dart tool/build.dart

# Run any tests that only run in the browser/framework.
pub run test -P browser -P travis --precompiled=build
