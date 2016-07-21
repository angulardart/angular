# Changelog: Angular 2 for Dart

## 2.0.0-beta.19

### API changes

* Remove existing implementation of web workers to be replaced in the
  future with Dart import override for dart:html.

### Bug Fixes and other changes
* Remove throwOnChanges parameter from all change detection calls in
  generated template.dart.
* Unused and empty assertArrayOfStrings API removed.
* Update BrowserDomAdapter from dart:js to package:js.
* Reset change detection to guard against template exception.
* Delete unused files.
* Cleanup the NgIf directive and remove facades.
* Enabled Travis-CI
* Update tests that should only run in the browser.
* Add angular transformer which deletes any pre-existing generated files
  from Bazel.
* Add DI library entrypoint to support VM tests.
* Fix the Math facade (improper annotation): @Deprecated(description).
* Clean up animation classes.
* Remove library name declarations.
* Run dart formatter on all code.
* Remove unused testing/lang_utils.dart.


## 2.0.0-beta.18

This is the first release of Angular 2 for Dart that is written directly in
Dart, instead of generated from TypeScript.

<!-- ### Breaking changes -->

### API changes

* The `Provider` constructor and `provide()` function are now more intuitive
  when they have a single argument.

  Before, `const Provider(Foo)` or `provide(Foo)`
  would provide a `null` object.
  To provide a `Foo` object, you had to use `const Provider(Foo, useClass:Foo)`
  or `provide(Foo, useClass:Foo)`.
  Now you can omit the `useClass:Foo`.
  Either of the following provides a `Foo` instance:

  ```
const Provider(Foo)
// or
provide(Foo)
```

  If you want the old behavior, change your code to specify `useValue`:

   ```
const Provider(Foo, useValue: null)
// or
provide(Foo, useValue: null)
```

### Known issues

* Some types of **dependency injection** don't work.
  (https://github.com/dart-lang/angular2/issues/10)

### Bug fixes and other changes

* Fix lower bound of pkg/build dependency.
* Fixes for dependency upper bounds: build and protobuf.
* Bumping min version of pkg/intl and pkg version.
* Remove redundant declaration of `el`.
* Security Update. Secure Contextual Escaping Implementation.
* Fix Intl number formatting.
* Enforce strong mode for angular2.dart.
* Updating README and CONTRIBUTING.md for first release.
* Enforce dartfmt for dart/angular2.
* Add //dart/angular2/build_defs with default resolved_identifiers.
* Import cleanup.
* Annotate browser-only tests.
* Include .gitignore in files sent to GitHub.
* Fix a strong mode error in angular2 (strong mode type inference miss).
* Add compiler tests.
* Delete unused libraries in lib/src.
* Updated pubspec: authors, description, homepage.
* Angular strong mode fixes for DDC support.
* Add _LoggerConsole implementation of Console for the TemplateCompiler.
* Mark Binding and bind() as deprecated. Replaced by Provider and provide().
