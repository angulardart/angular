#!/bin/bash

PUB_PORT=8283

# Kill any existing pub instance.
pid=$(lsof -i:$PUB_PORT -t); kill -TERM $pid || kill -KILL $pid

# Fail fast.
set -e

# Run pub serve on directories that have codegen tests.
# Some errors will occur on other tests that don't use codegen yet; ignore.
exec 3< <(pub serve test --port $PUB_PORT)

# Block until we see this message.
sed '/Build completed/q' <&3 ; cat <&3 &

# Run the codegen tests only.
pub run test --pub-serve=$PUB_PORT -t codegen -p content-shell \
    test/security \

# Kill pub since we succeeded.
pid=$(lsof -i:$PUB_PORT -t); kill -TERM $pid || kill -KILL $pid
