Testing infrastructure for [AngularDart][webdev_angular], used with the
[`build_runner` package][build_runner].

See https://github.com/angulardart for current updates on this project.

Documentation and examples:

* [`_tests/test/`][test_folder] (tests for the main dart-lang/angular package)

[pub_angular_test]: https://pub.dev/packages/angular_test
[pub_test]: https://pub.dev/packages/test
[build_runner]: https://pub.dev/packages/build_runner
[test_folder]: https://github.com/angulardart/angular/tree/master/_tests/test
[webdev_angular]: https://pub.dev/packages/angular

Additional resources:

*   Community/support: [Gitter chat room]

[Gitter chat room]: https://gitter.im/angulardart/community

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
  build_runner: ^2.0.0
  build_test: ^2.0.0
  build_web_compilers: ^3.0.0
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
