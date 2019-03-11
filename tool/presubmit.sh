#!/bin/bash

# #################################################################### #
#         AUTO GENERATED. This is used locally to validate.            #
# #################################################################### #

# Fast fail the script on failures.
set -e

# Remove previous output directories.
rm -rf **/build/

echo "Analyzing _benchmarks..."
PKG=_benchmarks tool/travis.sh analyze
echo "Building _benchmarks in debug mode..."
PKG=_benchmarks tool/travis.sh build
echo "Running tests in _benchmarks in debug mode"
PKG=_benchmarks tool/travis.sh test
echo "Analyzing _goldens..."
PKG=_goldens tool/travis.sh analyze
echo "Building _goldens in debug mode..."
PKG=_goldens tool/travis.sh build
echo "Running custom test script for _goldens..."
pushd _goldens
./tool/test.sh
popd

echo "Analyzing _tests..."
PKG=_tests tool/travis.sh analyze
echo "Building _tests in debug mode..."
PKG=_tests tool/travis.sh build
echo "Running tests in _tests in debug mode"
PKG=_tests tool/travis.sh test
echo "Analyzing angular..."
PKG=angular tool/travis.sh analyze
echo "Analyzing angular_analyzer_plugin..."
PKG=angular_analyzer_plugin tool/travis.sh analyze
echo "Running tests in angular_analyzer_plugin in (nobuild)"
PKG=angular_analyzer_plugin tool/travis.sh test:nobuild
echo "Analyzing angular_ast..."
PKG=angular_ast tool/travis.sh analyze
echo "Building angular_ast in debug mode..."
PKG=angular_ast tool/travis.sh build
echo "Running tests in angular_ast in debug mode"
PKG=angular_ast tool/travis.sh test
echo "Analyzing angular_compiler..."
PKG=angular_compiler tool/travis.sh analyze
echo "Building angular_compiler in debug mode..."
PKG=angular_compiler tool/travis.sh build
echo "Running tests in angular_compiler in debug mode"
PKG=angular_compiler tool/travis.sh test
echo "Analyzing angular_forms..."
PKG=angular_forms tool/travis.sh analyze
echo "Building angular_forms in debug mode..."
PKG=angular_forms tool/travis.sh build
echo "Running tests in angular_forms in debug mode"
PKG=angular_forms tool/travis.sh test
echo "Analyzing angular_router..."
PKG=angular_router tool/travis.sh analyze
echo "Building angular_router in debug mode..."
PKG=angular_router tool/travis.sh build
echo "Running tests in angular_router in debug mode"
PKG=angular_router tool/travis.sh test
echo "Analyzing angular_test..."
PKG=angular_test tool/travis.sh analyze
echo "Building angular_test in debug mode..."
PKG=angular_test tool/travis.sh build
echo "Running tests in angular_test in debug mode"
PKG=angular_test tool/travis.sh test
echo "Analyzing dev..."
PKG=dev tool/travis.sh analyze
echo "Running tests in dev in (nobuild)"
PKG=dev tool/travis.sh test:nobuild
echo "Analyzing examples/github_issues..."
PKG=examples/github_issues tool/travis.sh analyze
echo "Building examples/github_issues in debug mode..."
PKG=examples/github_issues tool/travis.sh build
echo "Running tests in examples/github_issues in debug mode"
PKG=examples/github_issues tool/travis.sh test
echo "Analyzing examples/hacker_news_pwa..."
PKG=examples/hacker_news_pwa tool/travis.sh analyze
echo "Building examples/hacker_news_pwa in debug mode..."
PKG=examples/hacker_news_pwa tool/travis.sh build
echo "Running tests in examples/hacker_news_pwa in debug mode"
PKG=examples/hacker_news_pwa tool/travis.sh test
echo "Analyzing examples/hello_world..."
PKG=examples/hello_world tool/travis.sh analyze
echo "Building examples/hello_world in debug mode..."
PKG=examples/hello_world tool/travis.sh build
echo "Analyzing examples/i18n..."
PKG=examples/i18n tool/travis.sh analyze
echo "Building examples/i18n in debug mode..."
PKG=examples/i18n tool/travis.sh build
echo "Running tests in examples/i18n in debug mode"
PKG=examples/i18n tool/travis.sh test
echo "Analyzing examples/registration_form..."
PKG=examples/registration_form tool/travis.sh analyze
echo "Building examples/registration_form in debug mode..."
PKG=examples/registration_form tool/travis.sh build