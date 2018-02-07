#!/bin/bash
# Hand Written for now, should update to mono_repo once it supports build stages

# Fast fail the script on failures.
set -e

if [ -z "$PKG" ]; then
  echo -e '\033[31mPKG environment variable must be set!\033[0m'
  exit 1
fi

if [ "$#" == "0" ]; then
  echo -e "\033[31mExpected a task!\033[0m"
  exit 1
fi
TASK=$1

pushd $PKG
pub upgrade

case $PKG in
_goldens) echo
  echo -e '\033[1m_goldens: before_script\033[22m'
  echo -e 'tool/travis.sh'
  tool/travis.sh
  ;;
esac

case $TASK in
build) echo
  echo -e '\033[1mTASK: build\033[22m'
  echo -e 'pub run build_runner build'
  pub run build_runner build
  ;;
dartanalyzer_0) echo
  echo -e '\033[1mTASK: dartanalyzer_0\033[22m'
  echo -e 'dartanalyzer --fatal-warnings .'
  dartanalyzer --fatal-warnings .
  ;;
dartanalyzer_1) echo
  echo -e '\033[1mTASK: dartanalyzer_1\033[22m'
  echo -e 'dartanalyzer --fatal-warnings lib test'
  dartanalyzer --fatal-warnings lib test
  ;;
test_00) echo
  echo -e '\033[1mTASK: test_00\033[22m'
  echo -e 'pub run test'
  pub run test
  ;;
test_01) echo
  echo -e '\033[1mTASK: test_01\033[22m'
  echo -e 'pub run test -p vm'
  pub run test -p vm
  ;;
test_02) echo
  echo -e '\033[1mTASK: test_02\033[22m'
  echo -e 'pub run build_runner test -- --platform=chrome -j1'
  pub run build_runner test -- --platform=chrome -j1
  ;;
test_03) echo
  echo -e '\033[1mTASK: test_03\033[22m'
  echo -e 'pub run build_runner test -- --platform=chrome --tags=codegen --timeout=4x -x skip_on_travis -j1'
  pub run build_runner test -- --platform=chrome --tags=codegen --timeout=4x -x skip_on_travis -j1
  ;;
test_04) echo
  echo -e '\033[1mTASK: test_04\033[22m'
  echo -e 'pub run test -p vm -x codegen'
  pub run test -p vm -x codegen
  ;;
test_05) echo
  echo -e '\033[1mTASK: test_05\033[22m'
  echo -e 'pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/common'
  pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/common
  ;;
test_06) echo
  echo -e '\033[1mTASK: test_06\033[22m'
  echo -e 'pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/compiler'
  pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/compiler
  ;;
test_07) echo
  echo -e '\033[1mTASK: test_07\033[22m'
  echo -e 'pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/core'
  pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/core
  ;;
test_08) echo
  echo -e '\033[1mTASK: test_08\033[22m'
  echo -e 'pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/di'
  pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/di
  ;;
test_09) echo
  echo -e '\033[1mTASK: test_09\033[22m'
  echo -e 'pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/integration'
  pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/integration
  ;;
test_10) echo
  echo -e '\033[1mTASK: test_10\033[22m'
  echo -e 'pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/platform'
  pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/platform
  ;;
test_11) echo
  echo -e '\033[1mTASK: test_11\033[22m'
  echo -e 'pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/security'
  pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/security
  ;;
test_12) echo
  echo -e '\033[1mTASK: test_12\033[22m'
  echo -e 'pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/source_gen'
  pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/source_gen
  ;;
test_13) echo
  echo -e '\033[1mTASK: test_13\033[22m'
  echo -e 'pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/symbol_inspector'
  pub run build_runner test -- --platform=chrome --tags=codegen --exclude-tags=known_pub_serve_failure -j1 test/symbol_inspector
  ;;
*) echo -e "\033[31mNot expecting TASK '${TASK}'. Error!\033[0m"
  exit 1
  ;;
esac
