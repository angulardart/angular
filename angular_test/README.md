# angular_test

Testing infrastructure and runner for [AngularDart][gh_angular_dart].

[gh_angular_dart]: https://github.com/dart-lang/angular2

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
$ pub run angular_test
```
