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
  command_0) echo
    echo -e '\033[1mTASK: command_0\033[22m'
    echo -e 'pub run build_runner build --fail-on-severe'
    pub run build_runner build --fail-on-severe
    ;;
  command_1) echo
    echo -e '\033[1mTASK: command_1\033[22m'
    echo -e 'pub run build_runner test -o build -- -p chrome'
    pub run build_runner test -o build -- -p chrome
    ;;
  command_2) echo
    echo -e '\033[1mTASK: command_2\033[22m'
    echo -e 'pub run build_runner test -o build -- -p vm'
    pub run build_runner test -o build -- -p vm
    ;;
  command_3) echo
    echo -e '\033[1mTASK: command_3\033[22m'
    echo -e 'pub run build_runner test -- -p vm'
    pub run build_runner test -- -p vm
    ;;
  command_4) echo
    echo -e '\033[1mTASK: command_4\033[22m'
    echo -e 'pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure'
    pub run build_runner test -- --platform=chrome --exclude-tags=known_pub_serve_failure
    ;;
  command_5) echo
    echo -e '\033[1mTASK: command_5\033[22m'
    echo -e 'pub run build_runner test -- --platform=chrome -j1'
    pub run build_runner test -- --platform=chrome -j1
    ;;
  command_6) echo
    echo -e '\033[1mTASK: command_6\033[22m'
    echo -e 'pub run build_runner test -- --platform=chrome --timeout=4x -x skip_on_travis -j1'
    pub run build_runner test -- --platform=chrome --timeout=4x -x skip_on_travis -j1
    ;;
  dartanalyzer_0) echo
    echo -e '\033[1mTASK: dartanalyzer_0\033[22m'
    echo -e 'dartanalyzer --fatal-warnings lib test web'
    dartanalyzer --fatal-warnings lib test web
    ;;
  dartanalyzer_1) echo
    echo -e '\033[1mTASK: dartanalyzer_1\033[22m'
    echo -e 'dartanalyzer --fatal-warnings lib test tool'
    dartanalyzer --fatal-warnings lib test tool
    ;;
  dartanalyzer_2) echo
    echo -e '\033[1mTASK: dartanalyzer_2\033[22m'
    echo -e 'dartanalyzer --fatal-warnings lib test'
    dartanalyzer --fatal-warnings lib test
    ;;
  dartanalyzer_3) echo
    echo -e '\033[1mTASK: dartanalyzer_3\033[22m'
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
