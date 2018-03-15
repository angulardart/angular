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

Unit (sometimes called "component") tests are in `test/`.

[`preset`]: https://github.com/dart-lang/test/blob/master/doc/configuration.md#configuration-presets

```bash
$ pub run build_runner test
```

## Debugging the unit tests

You can view the tests locally. Simply start the development server:

```bash
$ pub run build_runner serve
```

And navigate to `localhost:8081/<test_name>.debug.html`. For example:

```
http://localhost:8081/issue_list_test.debug.html
```
