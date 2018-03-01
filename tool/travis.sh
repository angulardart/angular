#!/bin/bash

# #################################################################### #
# See ../CONTRIBUTING.md#running-travis for details and documentation. #
# #################################################################### #

# Fast fail the script on failures.
set -e

# Check environment variables.
if [ -z "$PKG" ]; then
  echo -e '\033[31mPKG environment variable must be set!\033[0m'
  exit 1
fi

if [ -z "$TASK" ]; then
  echo -e '\033[31mTASK environment variable must be set!\033[0m'
  exit 1
fi

# Navigate to the correct sub-directory, and run "pub upgrade".
pushd $PKG
pub upgrade
EXIT_CODE=1

# Run the correct task type.
case $TASK in
  analyzer)
    echo -e '\033[1mTASK: Dart Analyzer [analyzer]\033[22m'
    echo -e 'dartanalyzer --fatal-warnings .'
    dartanalyzer --fatal-warnings . || EXIT_CODE=$?
    ;;

  dartdevc)
    echo -e '\033[1mTASK: Testing with DartDevCompiler [dartdevc]\033[22m'
    echo -e 'pub run build_runner test -- -p chrome -r expanded -x fails-on-travis'
    pub run build_runner test -- -p chrome -r expanded -x fails-on-travis || EXIT_CODE=$?
    ;;

  dart2js)
    echo -e '\033[1mTASK: Testing with Dart2JS [dart2js]\033[22m'
    echo -e 'pub run build_runner test -- -p chrome -r expanded -x fails-on-travis'
    pub run build_runner test --config release -- -p chrome -r expanded -x fails-on-travis || EXIT_CODE=$?
    ;;

  dartvm)
    echo -e '\033[1mTASK: Testing with Dart VM [dartvm]\033[22m'
    echo -e 'pub run test -p vm -r expanded -x fails-on-travis'
    pub run build_runner test -- -p vm -r expanded -x fails-on-travis || EXIT_CODE=$?
    ;;

  *)
    echo -e "\033[31mNot expecting TASK '${TASK}'. Error!\033[0m"
    exit 1
    ;;
esac

exit $EXIT_CODE
