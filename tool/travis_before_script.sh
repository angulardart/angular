#!/bin/bash

# Fast fail the script on failures.
set -ev

# TODO(kevmoo) I'd love to only execute this when running VM tests
# ...but it seems the only option to do that is to do a hacky grep over
#  /home/travis/build.sh
# ...which I don't feel like doing yet
dart test/source_gen/template_compiler/generate.dart
