# AngularDart Golden Files

This package contains checked-in generated files ("goldens") representing the
output of the AngularDart compiler, allowing both developers and users to
compare the generated output over time - for example when updating dependencies
or the compiler itself.

All of the files are located in `test/files`. Given a `test/files/**.dart` file:

*   `*.outline.golden`: The output of the _outliner_ (API-only view)
*   `*.template.golden`: The output of the _compiler_ (actual emitted code)

# Updating goldens

> NOTE: Bazel user? You have a different workflow. See ../g3tools/goldens.dart.

In order to update the goldens, do the following:

* Change to the `_goldens` directory.
* `pub upgrade`
* `pub run build_runner build -o build`
* `dart tool/update.dart`

# Adding a new golden

*   Add `.dart` file to `test/files`.
*   Update the golden files as described above.
