# Angular Golden Files

This package contains golden files for the AngularDart compiler. It allows both
Angular developers and users to see the generated output of the angular compiler
for various features, as well be notified (via testing) if the files would
change.

All of the files are located in `test/_files`. Alongside each `.dart` file are
three `.golden` files, one for the `debug` and `release` versions, as well as an
`outline` version used to optimize bazel-based builds.

# Updating goldens

> NOTE: Bazel user? You have a different workflow. See ../g3tools/goldens.dart.

In order to update the goldens, do the following:

* Change to the `_goldens` directory.
* `pub upgrade`
* `pub run build_runner build -o build`
* `dart tool/update.dart`

# Adding a new golden

* Add `.dart` file to `test/_files`.
* Update the golden files as described above.
