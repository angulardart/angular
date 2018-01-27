#!/bin/bash
# Created with https://github.com/dart-lang/mono_repo

# Fast fail the script on failures.
set -e

if [ -z "$PKG" ]; then
  echo -e "[31mPKG environment variable must be set![0m"
  exit 1
elif [ -z "$TASK" ]; then
  echo -e "[31mTASK environment variable must be set![0m"
  exit 1
fi

pushd $PKG
pub upgrade

case $PKG in
_goldens) echo
  echo -e "[1mPKG: _goldens[22m"
  tool/travis.sh
  ;;
_tests) echo
  echo -e "[1mPKG: _tests[22m"
  tool/travis.sh
  ;;
angular_test) echo
  echo -e "[1mPKG: angular_test[22m"
  tool/travis.sh
  ;;
angular_router) echo
  echo -e "[1mPKG: angular_router[22m"
  tool/travis.sh
  ;;
*) echo -e "No before_script specified for PKG '${PKG}'."
  ;;
esac

case $TASK in
dartanalyzer) echo
  echo -e "[1mTASK: dartanalyzer[22m"
  dartanalyzer --fatal-warnings .
  ;;
dartanalyzer_1) echo
  echo -e "[1mTASK: dartanalyzer_1[22m"
  dartanalyzer --fatal-warnings lib test
  ;;
test) echo
  echo -e "[1mTASK: test[22m"
  pub run test
  ;;
test_1) echo
  echo -e "[1mTASK: test_1[22m"
  pub run test -p vm -x codegen
  ;;
test_10) echo
  echo -e "[1mTASK: test_10[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/symbol_inspector
  ;;
test_11) echo
  echo -e "[1mTASK: test_11[22m"
  pub run test -p vm
  ;;
test_12) echo
  echo -e "[1mTASK: test_12[22m"
  pub run test --precompiled=build --platform=chrome -j1
  ;;
test_2) echo
  echo -e "[1mTASK: test_2[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/common
  ;;
test_3) echo
  echo -e "[1mTASK: test_3[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/compiler
  ;;
test_4) echo
  echo -e "[1mTASK: test_4[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/core
  ;;
test_5) echo
  echo -e "[1mTASK: test_5[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/di
  ;;
test_6) echo
  echo -e "[1mTASK: test_6[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/integration
  ;;
test_7) echo
  echo -e "[1mTASK: test_7[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/platform
  ;;
test_8) echo
  echo -e "[1mTASK: test_8[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/security
  ;;
test_9) echo
  echo -e "[1mTASK: test_9[22m"
  pub run test --precompiled=build --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/source_gen
  ;;
*) echo -e "[31mNot expecting TASK '${TASK}'. Error![0m"
  exit 1
  ;;
esac
