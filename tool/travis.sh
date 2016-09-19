#!/bin/bash

# Fast fail the script on failures.
set -e

THE_COMMAND="pub run test -p $TEST_PLATFORM --pub-serve=8080"
if [ $TEST_PLATFORM == 'firefox' ] || [ $TEST_PLATFORM == 'content-shell' ]; then
    # browser tests don't run well on travis unless one-at-a-time
    THE_COMMAND="$THE_COMMAND -j 1"
fi
echo $THE_COMMAND
exec $THE_COMMAND
