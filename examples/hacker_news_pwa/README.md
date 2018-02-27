# Hacker News PWA in AngularDart 

<img width="834" src="https://user-images.githubusercontent.com/168174/36634757-57637b9a-195e-11e8-82f9-07c882f0471c.png">

## Running locally

To run and debug locally using `dartdevc`:

```bash
$ pub upgrade
$ pub run build_runner serve
```

... and then navigate to `http://localhost:8080`.

## Production build

To build and run locally using `dart2js`:

```bash
$ pub upgrade
$ pub run build_runner serve --config=release
```

## Run on Firebase

1. Install and setup [Firebase CLI](https://github.com/firebase/firebase-tools/).

2. Create a new [Firebase project](https://console.firebase.google.com/).

3. Build a release version of hacker_news_pwa:

```shell
$ pub run build_runner build --config=release --fail-on-severe --output build
```
4. Select your new Firebase project:
```shell
$ firebase use --add
```
5. Deploy:
```shell
$ firebase deploy
```

## Updating service worker cached assets

Run the following command to update the list of assets the service worker will
cache to be accessible offline.

```shell
$ pub run pwa --exclude "packages/**,*.ng_placeholder"
```
