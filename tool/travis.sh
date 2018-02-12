#!/bin/bash
# Created with https://github.com/dart-lang/mono_repo

# Fast fail the script on failures.
set -e

if [ -z "$PKG" ]; then
  echo -e '\033[31mPKG environment variable must be set!\033[0m'
  exit 1
fi

if [ "$#" == "0" ]; then
  echo -e '\033[31mAt least one task argument must be provided!\033[0m'
  exit 1
fi

pushd $PKG
pub upgrade

while (( "$#" )); do
  TASK=$1
  case $TASK in
  command_00) echo
    echo -e '\033[1mTASK: command_00\033[22m'
    echo -e 'pub run build_runner build --fail-on-severe'
    pub run build_runner build --fail-on-severe
    ;;
  command_01) echo
    echo -e '\033[1mTASK: command_01\033[22m'
    echo -e 'pub run build_runner test -o build -- -p vm'
    pub run build_runner test -o build -- -p vm
    ;;
  command_02) echo
    echo -e '\033[1mTASK: command_02\033[22m'
    echo -e 'pub run build_runner test -- -p vm'
    pub run build_runner test -- -p vm
    ;;
  command_03) echo
    echo -e '\033[1mTASK: command_03\033[22m'
    echo -e 'pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/common'
    pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/common
    ;;
  command_04) echo
    echo -e '\033[1mTASK: command_04\033[22m'
    echo -e 'pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/compiler'
    pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/compiler
    ;;
  command_05) echo
    echo -e '\033[1mTASK: command_05\033[22m'
    echo -e 'pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/core'
    pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/core
    ;;
  command_06) echo
    echo -e '\033[1mTASK: command_06\033[22m'
    echo -e 'pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/di'
    pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/di
    ;;
  command_07) echo
    echo -e '\033[1mTASK: command_07\033[22m'
    echo -e 'pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/integration'
    pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/integration
    ;;
  command_08) echo
    echo -e '\033[1mTASK: command_08\033[22m'
    echo -e 'pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/platform'
    pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/platform
    ;;
  command_09) echo
    echo -e '\033[1mTASK: command_09\033[22m'
    echo -e 'pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/security'
    pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/security
    ;;
  command_10) echo
    echo -e '\033[1mTASK: command_10\033[22m'
    echo -e 'pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/source_gen'
    pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/source_gen
    ;;
  command_11) echo
    echo -e '\033[1mTASK: command_11\033[22m'
    echo -e 'pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/symbol_inspector'
    pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure -j1 test/symbol_inspector
    ;;
  command_12) echo
    echo -e '\033[1mTASK: command_12\033[22m'
    echo -e 'pub run build_runner test -- --platform=chrome -j1'
    pub run build_runner test -- --platform=chrome -j1
    ;;
  command_13) echo
    echo -e '\033[1mTASK: command_13\033[22m'
    echo -e 'pub run build_runner test -- --platform=chrome --timeout=4x -x skip_on_travis -j1'
    pub run build_runner test -- --platform=chrome --timeout=4x -x skip_on_travis -j1
    ;;
  dartanalyzer_0) echo
    echo -e '\033[1mTASK: dartanalyzer_0\033[22m'
    echo -e 'dartanalyzer --fatal-warnings lib test tool'
    dartanalyzer --fatal-warnings lib test tool
    ;;
  dartanalyzer_1) echo
    echo -e '\033[1mTASK: dartanalyzer_1\033[22m'
    echo -e 'dartanalyzer --fatal-warnings lib test'
    dartanalyzer --fatal-warnings lib test
    ;;
  dartanalyzer_2) echo
    echo -e '\033[1mTASK: dartanalyzer_2\033[22m'
    echo -e 'dartanalyzer --fatal-warnings .'
    dartanalyzer --fatal-warnings .
    ;;
  test_0) echo
    echo -e '\033[1mTASK: test_0\033[22m'
    echo -e 'pub run test'
    pub run test
    ;;
  test_1) echo
    echo -e '\033[1mTASK: test_1\033[22m'
    echo -e 'pub run test -p vm'
    pub run test -p vm
    ;;
  *) echo -e "\033[31mNot expecting TASK '${TASK}'. Error!\033[0m"
    exit 1
    ;;
  esac

  shift
done
