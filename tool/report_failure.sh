#!/bin/bash
if [ "$TRAVIS_EVENT_TYPE" != "pull_request" ] && [ "$TRAVIS_ALLOW_FAILURE" != "true" ]; then
  curl -H "Content-Type: application/json" -X POST -d \
    "{'text':'Build failed! ${TRAVIS_BUILD_WEB_URL}'}" \
    "${CHAT_HOOK_URI}"
fi
