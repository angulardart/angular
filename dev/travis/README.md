See [../../CONTRIBUTING.md#running-travis](../../CONTRIBUTING.md#running-travis)
for details about _running_ travis tests.

This package is a micro-package for generating travis configuration. We used to
use `mono_repo`, but we have lots of specialized requirements and packages and
its easier to implement something locally rather than try and get it to work in
an all-in-one-tool like `mono_repo`.

Basically, this script (`dart dev/travis/config.dart`) generates `.travis.yml`
from:

* `prefix.yaml`
* then configuration generated from `config.dart`
* then `postfix.yaml`

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

## Exceptions

Any package that has a `tool/test.sh` uses a custom script _instead_ of the
following heuristics. This is often to get around temporary bugs in the
infrastructure.
