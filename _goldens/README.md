# Angular Golden Files

This package contains golden files for the Angular compiler. It allows both
angular developers and users to see the generated output of the angular compiler
for various features.

All of the files are located in `test_files`. Alongside each `.dart` file are
three `.golden` files, one for the `debug` and `release` versions, as well as an
`outline` version used to optimize bazel-based builds.

# Updating goldens

In order to update the goldens, do the following: * Change to the `_goldens`
directory. * `pub get` * `dart generator/bin/generate.dart --update-goldens`

# Adding a new golden

*   Add `.dart` file to `test_files`.
*   Add file name to `test/generate_template_test.dart`.
*   Update the golden files as described above.
