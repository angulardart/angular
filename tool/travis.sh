#!/bin/bash

# #################################################################### #
# See ../CONTRIBUTING.md#running-travis for details and documentation. #
# #################################################################### #

# Fast fail the script on failures.
set -e

# Check arguments.
TASK=$1

if [ -z "$PKG" ]; then
  echo -e '\033[31mPKG variable must be set!\033[0m'
  echo -e '\033[31mExample: PKG=angular tool/travis.sh analyze\033[0m'
  exit 1
fi

if [ -z "$TASK" ]; then
  echo -e '\033[31mTASK argument must be set!\033[0m'
  echo -e '\033[31mExample: PKG=angular tool/travis.sh analyze\033[0m'
  exit 1
fi

# Navigate to the correct sub-directory, and run "pub upgrade".
pushd $PKG
PUB_ALLOW_PRERELEASE_SDK=quiet pub upgrade
EXIT_CODE=1

# Run the correct task type.
case $TASK in
  analyze)
    echo -e '\033[1mTASK: Dart Analyzer [analyzer]\033[22m'
    echo -e 'dartanalyzer --fatal-warnings .'
    dartanalyzer --fatal-warnings .
    ;;

  build)
    echo -e '\033[1mTASK: Building Only [build]\033[22m'
    echo -e 'pub run build_runner build --fail-on-severe'
    pub run build_runner build --fail-on-severe
    ;;

  build:release)
    echo -e '\033[1mTASK: Building Only [build:release]\033[22m'
    echo -e 'pub run build_runner build --config=release --fail-on-severe'
    pub run build_runner build --config=release --fail-on-severe
    ;;

  test)
    echo -e '\033[1mTASK: Testing [test]\033[22m'
    echo -e 'pub run build_runner test --fail-on-severe -- -P travis'
    pub run build_runner test --fail-on-severe -- -P travis
    ;;

  test:nobuild)
    echo -e '\033[1mTASK: Testing [test]\033[22m'
    echo -e 'pub run test -P travis'
    pub run test -P travis
    ;;

  test:release)
    echo -e '\033[1mTASK: Testing [test:release]\033[22m'
    echo -e 'pub run build_runner test --config=release --fail-on-severe -- -P travis'
    pub run build_runner test --config=release --fail-on-severe -- -P travis
    ;;

  *)
    echo -e "\033[31mNot expecting TASK '${TASK}'. Error!\033[0m"
    exit 1
    ;;
esac
