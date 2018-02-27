# Execute this from the ROOT of the repository only.
#!/bin/bash
set -e

pushd examples/hacker_news_pwa

# Deploys examples/hacker_news_pwa to Firebase!

# If we are on Travis, we expect `$FIREBASE_TOKEN` to be set.
# Otherwise you should be logged in locally with the Firebase CLI.
if [ -n "$TRAVIS_BUILD_ID" ]; then
  firebase deploy --token $FIREBASE_TOKEN --non-interactive
else
  firebase deploy --non-interactive
fi

popd
