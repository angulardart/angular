# Dart Hacker News PWA

The application is deployed at [hnpwa.dartlang.org](https://hnpwa.dartlang.org).

It was built as an example for [hnpwa.com](https://hnpwa.com/).

<img width="834" src="https://user-images.githubusercontent.com/168174/36634757-57637b9a-195e-11e8-82f9-07c882f0471c.png">

## Running locally

To run and debug locally using `dartdevc`:

```console
$ webdev serve
```

Then navigate to `http://localhost:8080`.

## Running locally with release configuration

To run locally using `dart2js`, add the `--release` flag.

```console
$ webdev serve --release
```

## Deploy to Firebase

1. Install and setup [Firebase CLI][firebase-cli].

2. Create a new [Firebase project][firebase-project].

3. Select your new Firebase project:

    ```console
    $ firebase use --add
    ```

    This will create a `.firebaserc` file to store your project configuration.

4. Update the offline URL cache [timestamp][offline-urls-timestamp] to the
   current date. Automation of this step has temporarily been disabled due to
   [#1369][issue-1369].

5. Deploy:

    The `firebase.json` file has the build command configured via the `predeploy`
    setting, so you just have to run `deploy`.

    ```console
    $ firebase deploy
    ```

[firebase-cli]: https://github.com/firebase/firebase-tools
[firebase-project]: https://console.firebase.google.com
[issue-1369]: https://github.com/dart-lang/angular/issues/1369
[offline-urls-timestamp]: https://github.com/dart-lang/angular/blob/master/examples/hacker_news_pwa/lib/pwa/offline_urls.g.dart#L11
