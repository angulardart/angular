#!/bin/bash

# Fast fail the script on failures.
set -ev

pub run test -p vm,content-shell
