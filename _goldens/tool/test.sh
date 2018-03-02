#!/bin/bash

# TODO(https://github.com/dart-lang/build/issues/1079):
# Can be removed once the standard PBR test can be used.

# Fast fail the script on failures.
set -e

pub upgrade
pub run build_runner build -o build
pub run test
