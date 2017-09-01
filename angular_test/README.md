[![Pub package](https://img.shields.io/pub/v/angular_test.svg)][pub_angular_test]

Testing infrastructure and runner for [AngularDart][webdev_angular],
used with the [`test` package][pub_test].

Documentation and examples:

* [`_tests/test/`][test_folder] (tests for dart-lang/angular packages)
  <br>
  We strongly recommend that you **follow the patterns in these tests**.
* [AngularDart component testing documentation][webdev_testing]:
  * [Running Component Tests](https://webdev.dartlang.org/angular/guide/testing/component/running-tests)
  * [Component Testing: Basics](https://webdev.dartlang.org/angular/guide/testing/component/basics)
  * Pages for individual topics, such as
    [page objects](https://webdev.dartlang.org/angular/guide/testing/component/page-objects)
    and
    [user actions](https://webdev.dartlang.org/angular/guide/testing/component/simulating-user-action)

[pub_angular_test]: https://pub.dartlang.org/packages/angular_test
[pub_test]: https://pub.dartlang.org/packages/test
[test_folder]: https://github.com/dart-lang/angular/tree/master/_tests/test
[webdev_angular]: https://webdev.dartlang.org/angular
[webdev_testing]: https://webdev.dartlang.org/angular/guide/testing/component

Additional resources:

* [API reference][dartdoc]
* Community/support:
  [mailing list][],
  [Gitter chat room][]
* GitHub repo (dart-lang/angular):
  [source code](https://github.com/dart-lang/angular),
  [test issues][]
* Pub packages: [angular_test][pub_angular_test], [test][pub_test]

[dartdoc]: https://www.dartdocs.org/documentation/angular_test/latest
[Gitter chat room]: https://gitter.im/dart-lang/angular
[mailing list]: https://groups.google.com/a/dartlang.org/forum/#!forum/web
[test issues]: https://github.com/dart-lang/angular/issues?q=is%3Aopen+is%3Aissue+label%3A%22package%3A+angular_test%22
[source code]: https://github.com/dart-lang/angular


## Overview

`angular_test` is both a framework for writing tests for AngularDart components
and a test _runner_ that delegates to `pub serve` and `pub run test` to run
component tests using the AOT compiler.

**Note:** `angular_test` **does not function in reflective mode**.

Here's an example of an AngularDart test:

```dart
@Tags(const ['aot'])
@TestOn('browser')
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

@AngularEntrypoint()
void main() {
  tearDown(disposeAnyRunningTest);

  test('should render "Hello World"', () async {
    final testBed = new NgTestBed<HelloWorldComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, 'Hello World');
    await testFixture.update((c) => c.name = 'Universe');
    expect(testFixture.text, 'Hello Universe');
  });
}

@Component(selector: 'test', template: 'Hello {{name}}')
class HelloWorldComponent {
  String name = 'World';
}
```

To use `angular_test`, configure your package's `pubspec.yaml` as follows:

```yaml
transformers:
  # Run the code generator on the entire package.
  - angular/transform/codegen

  # Run the reflection remover on tests that have AOT enabled.
  - angular/transform/reflection_remover:
      $include:
          - test/test_using_angular_test.dart

  # Allow test to proxy-load files so we can run AOT tests with pub serve.
  - test/pub_serve:
      $include: test/**_test.dart

```

To run tests, use `pub run angular_test`. It automatically runs `pub serve` to
run code generation (transformers) and `pub run test` to run browser tests on
anything tagged with `'aot'`. Also declare a specific browser test platform,
as described in the [`test` package description][pub_test];
`dartium` and `content-shell` are the most common choices. Here's an example
of running tests using the content shell:

```sh
pub run angular_test --test-arg=--tags=aot --test-arg=--platform=content-shell
```

### Options

The `angular_test` script can accept the following options:

```
--package              What directory containing a pub package to run tests in
                       (defaults to CWD)

-v, --[no-]verbose     Whether to display output of "pub serve" while running tests
    --help             Show usage
    --port             What port to use for pub serve.

                       **DEPRECATED**: Use --serve-arg=--port=.... If this is
                       not specified, and --serve-arg=--port is not specified, then
                       defaults to a value of "0" (or random port).

-S, --serve-arg        Pass an additional argument=value to `pub serve`

                       Example use --serve-arg=--mode=release

-t, --run-test-flag    What flag(s) to include when running "pub run test".
                       In order to have a fast test cycle, we only want to run
                       tests that have Angular compilation required (all the ones
                       created using this package do).

                       **DEPRECATED**: Use --test-arg=--tags=... instead

-p, --platform         What platform(s) to pass to `pub run test`.

                       **DEPRECATED**: Use --test-arg=--platform=... instead

-n, --name             A substring of the name of the test to run.
                       Regular expression syntax is supported.
                       If passed multiple times, tests must match all substrings.

                       **DEPRECATED**: Use --test-arg=--name=... instead

-N, --plain-name       A plain-text substring of the name of the test to run.
                       If passed multiple times, tests must match all substrings.

                       **DEPRECATED**: Use --test-arg=--plain-name=... instead

-T, --test-arg         Pass an additional argument=value to `pub run test`

                       Example: --test-arg=--name=ngIf
```
