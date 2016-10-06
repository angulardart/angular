#!/bin/bash

# Fast fail the script on failures.
set -e

if [ -z "$TEST_PLATFORM" ]; then
  echo "TEST_PLATFORM must be set"
  exit 1
fi

echo "** Run a trivial travis-only test to see if the current platform works"
pub run test -p $TEST_PLATFORM tool/travis_sniff_test.dart

echo "** Running main tests – no codegen"
# Run tests that don't require codegen.
if [ $TEST_PLATFORM == 'firefox' ]; then
  THE_COMMAND="pub run test -x codegen -P safe_firefox -j 1"
else
  THE_COMMAND="pub run test -x codegen -p $TEST_PLATFORM"
fi

echo $THE_COMMAND
$THE_COMMAND

if [ $TEST_PLATFORM == 'content-shell' ]; then
  echo "** Running pub tests – with codegen"
  "$(dirname "$0")/run_codegen_tests.sh"
fi

echo "** Done!!"
