# AngularDart Hacker News PWA

## Run locally

```shell
$ pub run build_runner serve
```

## Run on Firebase

1. Install and setup [Firebase CLI](https://github.com/firebase/firebase-tools/).

2. Create a new [Firebase project](https://console.firebase.google.com/).

3. Build a release version of hacker_news_pwa.

```shell
$ pub run build_runner build --config=release --fail-on-severe --output build
```
4. Select your new Firebase project.
```shell
$ firebase use --add
```
5. Deploy.
```shell
$ firebase deploy
```

## Service Worker

### Updating Cached Assets

Run the following command to update the list of assets the service worker will
cache to be accessible offline.

```shell
$ pub run pwa --exclude "packages/**,*.ng_placeholder"
```
