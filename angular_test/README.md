# angular_test

Testing infrastructure and runner for [AngularDart][gh_angular_dart].

[gh_angular_dart]: https://github.com/dart-lang/angular2

It's **strongly recommended** to view the `test/` folder for examples and recommended patterns.

## Usage

`angular_test` is both a framework for writing tests for AngularDart components _and_ a
test _runner_ that delegates to both `pub serve` and `pub run test` to run component tests
using the AOT-compiler - `angular_test` **does not function in reflective mode**.

Example use:

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

You will need to also configure in `pubspec.yaml` to run code generation:

```yaml
transformers:
  # Run the code generator on the entire package.
  - angular2/transform/codegen

  # Run the reflection remover on tests that have AoT enabled.
  - angular2/transform/reflection_remover:
      $include:
          - test/test_using_angular_test.dart

  # Allow test to proxy-load files so we can run AoT tests w/ pub serve.
  - test/pub_serve:
      $include: test/**_test.dart

```

## Running

Use `pub run angular_test` - it will automatically run `pub serve` to run code generation
(transformers) and `pub run test` to run browser tests on anything tagged with `'aot'`.:

```sh
$ pub run angular_test --test-arg=--tags=aot
```

You can use `--test-arg` to pass arbitrary arguments to `pub run test` and
`--serve-arg` to pass arbitrary arguments to `pub serve`.

### Usage

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
