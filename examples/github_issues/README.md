# Github Issues Viewer

The following is a canonical example of using the `angular_test` package to test
your AngularDart applications and components, and otherwise is "just for fun".

## Getting started

You'll need to `git clone` and `pub get` to see this package in action:

```bash
$ git clone https://github.com/dart-lang/angular.git
$ cd angular/examples/github_issues
$ pub get
```

If you'd like to play around with the application yourself:

```bash
$ pub run build_runner serve
```

## Running the unit tests

Unit (sometimes called "component") tests are in `test/unit`.

Using `build_runner` for our build tool, we can run them using a [`preset`][]
in our `dart_test.yaml`, `unit`:

[`preset`]: https://github.com/dart-lang/test/blob/master/doc/configuration.md#configuration-presets

```bash
$ pub run build_runner test -- -P unit
```

_**NOTE**: Arguments after `--` are to `package:test`._

## Running the end-to-end tests

_WORK IN PROGRESS: There currently are no integration tests._
