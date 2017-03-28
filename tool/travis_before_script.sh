#!/bin/bash

# Fast fail the script on failures.
set -ev

# NOTE: Only needed for vm tests, but no easy way to sniff the `dart_task`
#       config from a shell script.
dart test/source_gen/template_compiler/generate.dart
