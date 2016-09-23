#!/bin/bash

# Fast fail the script on failures.
set -e

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
