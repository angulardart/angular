This package is a micro-package for managing the development of this repository.
We used to use `mono_repo`, but we have lots of specialized requirements and
packages and its easier to implement something locally rather than try and get
it to work in an all-in-one-tool like `mono_repo`.

## Getting started

From the root (i.e. `angular`) run the following:

```bash
$ pub get
```

You now have the `dev` set of tools installed. Make sure to only run them from
the root of this repository (i.e. directly in `angular`).

## Commands

The following commands are available:

### `pubspec`

This generates and keeps elements in sync across `pubspec.yaml` files.

**Example use:**

```bash
$ pub run dev:pubspec
```

### `travis`

This generates the root `.travis.yml` from:

* `dev/tool/travis/prefix.yaml`
* then merges with configuration generated from `dev/bin/travis.dart`
* then merges with `dev/tool/travis/postfix.yaml`

**Example use:**

```bash
$ pub run dev:travis
```

For the configurable portion, _conventions_ are used over _configuration_ for
the most part (i.e. where possible).

For every package (has a `pubspec.yaml`):

* `dartanalyzer` is run.

For every package with a dependency on `build_runner`:

* the package is built using `build_runner build`.

For every package that has a `build.release.yaml`:

* the package is built using `build_runner build --config=release`.

For every package that has a `test/` folder:

* the package is tested using `build_runner test`

For every package that has a `test/` folder and `build.release.yaml`:

* the package is tested using `build_runner test --config=release`.

#### Exceptions

Any package that has a `tool/test.sh` uses a custom script _instead_ of the
following heuristics. This is often to get around temporary bugs in the
infrastructure.
