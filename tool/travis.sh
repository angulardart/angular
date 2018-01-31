#!/bin/bash
# Created with https://github.com/dart-lang/mono_repo

# Fast fail the script on failures.
set -e

if [ -z "$PKG" ]; then
  echo -e "\033[31mPKG environment variable must be set!\033[0m"
  exit 1
elif [ -z "$TASK" ]; then
  echo -e "\033[31mTASK environment variable must be set!\033[0m"
  exit 1
fi

pushd $PKG
pub upgrade

case $PKG in
_goldens) echo
  echo -e "\033[1mPKG: _goldens\033[22m"
  echo -e "  Running `tool/travis.sh`"
  tool/travis.sh
  ;;
_tests) echo
  echo -e "\033[1mPKG: _tests\033[22m"
  echo -e "  Running `tool/travis.sh`"
  tool/travis.sh
  ;;
angular_test) echo
  echo -e "\033[1mPKG: angular_test\033[22m"
  echo -e "  Running `tool/travis.sh`"
  tool/travis.sh
  ;;
angular_router) echo
  echo -e "\033[1mPKG: angular_router\033[22m"
  echo -e "  Running `tool/travis.sh`"
  tool/travis.sh
  ;;
esac

case $TASK in
dartanalyzer) echo
  echo -e "\033[1mTASK: dartanalyzer\033[22m"
  dartanalyzer --fatal-warnings .
  ;;
dartanalyzer_1) echo
  echo -e "\033[1mTASK: dartanalyzer_1\033[22m"
  dartanalyzer --fatal-warnings lib test
  ;;
test) echo
  echo -e "\033[1mTASK: test\033[22m"
  pub run test
  ;;
test_1) echo
  echo -e "\033[1mTASK: test_1\033[22m"
  pub run test -p vm -x codegen
  ;;
test_10) echo
  echo -e "\033[1mTASK: test_10\033[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/symbol_inspector
  ;;
test_11) echo
  echo -e "\033[1mTASK: test_11\033[22m"
  pub run test -p vm
  ;;
test_12) echo
  echo -e "\033[1mTASK: test_12\033[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --timeout=4x -x skip_on_travis -j1
  ;;
test_13) echo
  echo -e "\033[1mTASK: test_13\033[22m"
  pub run test --precompiled=build --platform=chrome -j1
  ;;
test_2) echo
  echo -e "\033[1mTASK: test_2\033[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/common
  ;;
test_3) echo
  echo -e "\033[1mTASK: test_3\033[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/compiler
  ;;
test_4) echo
  echo -e "\033[1mTASK: test_4\033[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/core
  ;;
test_5) echo
  echo -e "\033[1mTASK: test_5\033[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/di
  ;;
test_6) echo
  echo -e "\033[1mTASK: test_6\033[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/integration
  ;;
test_7) echo
  echo -e "\033[1mTASK: test_7\033[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/platform
  ;;
test_8) echo
  echo -e "\033[1mTASK: test_8\033[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/security
  ;;
test_9) echo
  echo -e "\033[1mTASK: test_9\033[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/source_gen
  ;;
*) echo -e "\033[31mNot expecting TASK '${TASK}'. Error!\033[0m"
  exit 1
  ;;
esac
