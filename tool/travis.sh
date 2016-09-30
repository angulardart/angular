#!/bin/bash

# Fast fail the script on failures.
set -e

if [ -z "$TEST_PLATFORM" ]; then
  echo "TEST_PLATFORM must be set"
  exit 1
fi

# Run a trivial travis-only test to see if the browser platform is even working
pub run test -p $TEST_PLATFORM tool/travis_sniff_test.dart

if [ $TEST_PLATFORM == 'firefox' ]; then
  # firefox tests don't run well on travis unless one-at-a-time
  THE_COMMAND="pub run test -P safe_firefox -j 1"
else
  THE_COMMAND="pub run test -p $TEST_PLATFORM"
fi
echo $THE_COMMAND
exec $THE_COMMAND
