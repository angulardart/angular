#!/bin/bash

# Kill any existing pub instance.
pid=$(lsof -i:8080 -t); kill -TERM $pid || kill -KILL $pid

# Fail fast.
set -e

# Run pub serve on directories that have codegen tests.
# Some errors will occur on other tests that don't use codegen yet; ignore.
exec 3< <(pub serve test)

# Block until we see this message.
sed '/Build completed/q' <&3 ; cat <&3 &

# Run the codegen tests only.
pub run test --pub-serve=8080 -t codegen -p content-shell,vm \
    test/testing \
    test/security \

# Kill pub since we succeeded.
pid=$(lsof -i:8080 -t); kill -TERM $pid || kill -KILL $pid
