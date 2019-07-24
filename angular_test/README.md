# angular_test

[![Pub package](https://img.shields.io/pub/v/angular_test.svg)][pub_angular_test]

Testing infrastructure [AngularDart][webdev_angular],
used with the [`build_runner` package][build_runner].

Documentation and examples:

* [`_tests/test/`][test_folder] (tests for the main dart-lang/angular package)
* [AngularDart component testing documentation][webdev_testing]:
  * [Running Component Tests](https://angulardart.dev/guide/testing/component/running-tests)
  * [Component Testing: Basics](https://angulardart.dev/guide/testing/component/basics)
  * Pages for individual topics, such as
    [page objects](https://angulardart.dev/guide/testing/component/page-objects)
    and
    [user actions](https://angulardart.dev/guide/testing/component/simulating-user-action)

**NOTE**: Some of the guides above are out of date the for the latest `angular_test` versions.

[pub_angular_test]: https://pub.dev/packages/angular_test
[pub_test]: https://pub.dev/packages/test
[build_runner]: https://pub.dev/packages/build_runner
[test_folder]: https://github.com/dart-lang/angular/tree/master/_tests/test
[webdev_angular]: https://angulardart.dev/
[webdev_testing]: https://angulardart.dev/guide/testing/component

Additional resources:

* [API reference][dartdoc]
* Community/support:
  [mailing list][],
  [Gitter chat room][]
* GitHub repo (dart-lang/angular):
  [source code](https://github.com/dart-lang/angular),
  [test issues][]
* Pub packages: [angular_test][pub_angular_test], [build_runner][build_runner], [test][pub_test]

[dartdoc]: https://www.dartdocs.org/documentation/angular_test/latest
[Gitter chat room]: https://gitter.im/dart-lang/angular
[mailing list]: https://groups.google.com/a/dartlang.org/forum/#!forum/web
[test issues]: https://github.com/dart-lang/angular/issues?q=is%3Aopen+is%3Aissue+label%3A%22package%3A+angular_test%22
[source code]: https://github.com/dart-lang/angular

## Overview

`angular_test` is a library for writing tests for AngularDart components.

```dart
// Assume this is 'my_test.dart'.
import 'my_test.template.dart' as ng;

void main() {
  ng.initReflector();
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
dev_dependencies:
  build_runner: ^1.0.0
  build_test: ^0.10.0
  build_web_compilers: ^1.0.0
```

**IMPORTANT**: `angular_test` will not run without these dependencies set.

To run tests, use `pub run build_runner test`. It automatically compiles your
templates and annotations with AngularDart, and then compiles all of the Dart
code to JavaScript in order to run browser tests. Here's an example of using
Chrome with Dartdevc:

```bash
pub run build_runner test -- -p chrome
```

For more information using `pub run build_runner test`, see the documentation:
https://github.com/dart-lang/build/tree/master/build_runner#built-in-commands
