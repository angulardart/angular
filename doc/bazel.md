# Building with Bazel

## Collecting metrics

Understanding how customers use Angular helps inform or validate changes we make
to the framework. Instrumenting the compiler to collect metrics provides an
opportunity to understand exactly what and how specific features are used.

### Logging

Logging is a simple solution for collecting metrics across an entire project. To
add logging to the compiler, import [angular\_compiler/cli.dart][cli] and use
one of the provided logging functions.

There are two caveats to be aware of when collecting compilation metrics with
Bazel: caching and filtering.

Firstly, Bazel reuses the cached outputs of every target that hasn't changed
since it was last built. When an output is reused, the Angular compiler isn't
run for the target which produces it. Be sure to clear to any cached outputs
before collecting compilation metrics to ensure complete coverage of your
target.

Secondly, Bazel filters the output of all subpackages, meaning you likely won't
see logged metrics for any dependencies of the target you're compiling. To
prevent filtering and see metrics for the entire build, use
[`--auto_output_filter=none`][auto_output_filter].

```
$ bazel clean
$ bazel build --auto_output_filter=none //<path>:<target>
```

(`--auto_output_filter` is only currently supported on the internal Bazel)

[auto_output_filter]: https://github.com/bazelbuild/bazel/issues/3330
[cli]: https://github.com/dart-lang/angular/blob/master/angular_compiler/lib/cli.dart
