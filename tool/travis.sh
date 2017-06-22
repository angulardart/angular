#!/bin/bash

# Fast fail the script on failures.
set -e

pushd angular
pub upgrade
dartanalyzer --fatal-warnings .
popd

pushd _tests
pub upgrade
dartanalyzer --fatal-warnings .
dart test/source_gen/template_compiler/generate.dart
pub run test
popd
