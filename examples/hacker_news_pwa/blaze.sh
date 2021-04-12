#!/bin/bash

# DDC development server for AngularDart Hacker New PWA
#
# This builds and serves this application internally using G3+Blaze.

source gbash.sh || exit

DEFINE_int port 8080 "Server port"

gbash::init_google "$@"

function main() {
  local path="third_party/dart_src/angular/examples/hacker_news_pwa"
  /google/data/ro/teams/acx-dev-cycle/dart-dev-runner/dart-dev-runner run \
      //${path}:hacker_news_pwa_iblaze_ddc \
      -- \
      --default-document=index.ddc.html \
      --directory=${path}/web \
      --port=${FLAGS_port}
}

gbash::main "$@"
