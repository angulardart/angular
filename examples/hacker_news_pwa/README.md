# Hacker News PWA in AngularDart

The application is deployed at [hnpwa.dartlang.org](https://hnpwa.dartlang.org).

It was built as an example for [hnpwa.com](https://hnpwa.com/).

<img width="834" src="https://user-images.githubusercontent.com/168174/36634757-57637b9a-195e-11e8-82f9-07c882f0471c.png">

## Running locally

To run and debug locally using `dartdevc`:

```console
$ pub run build_runner serve
```

Then navigate to `http://localhost:8080`.

## Running locally with release configuration

To run locally using `dart2js`, add the `--release` flag.

```console
$ pub run build_runner serve --release
```

## Deploy to Firebase

1. Install and setup [Firebase CLI](https://github.com/firebase/firebase-tools/).

2. Create a new [Firebase project](https://console.firebase.google.com/).

3. Build a release version of hacker_news_pwa:

4. Select your new Firebase project:

  ```console
  $ firebase use --add
  ```

  This will create a `.firebaserc` file to store your project configuration.

5. Build and deploy:

  The `firebase.json` file has the build command configured via the `predeploy`
  setting, so you just have to run `deploy`.

  ```console
  $ firebase deploy
  ```

<!--
Add back details about updating the cached assets once
https://github.com/isoos/pwa/issues/21 is fixed

## Updating service worker cached assets

Run the following commands to update the list of assets the service worker will
cache to be accessible offline.

```shell
$ pub run build_runner build --config=release --output build
$ pub run pwa --exclude "packages/**,.packages,*.dart,*.js.deps,*.js.info.json,*.js.map,*.js.tar.gz,*.module"
```
-->
