# Compiler Flags

The following is a list of supported flags when using the AngularDart compiler
as a _pub/barback transformer_. Any flag you don't see listed below is not
supported in AngularDart 4.x, and will cause the compiler to fail.

Additionally, you can use the `mode` flag (to pub) to force a build compilation
in `debug` mode (what is used for testing and local development). This can be
useful to inspect `.dart` files generated (on disk):

```bash
$ pub build --mode=debug
```

## `use_legacy_style_encapsulation`

```yaml
transformers:
  angular:
    use_legacy_style_encapsulation: true
```

**DEPRECATED**: Support for this flag will be removed in a future release.

Enables the use of deprecated Shadow DOM CSS selectors, and cause shadow host
selectors to prevent a series of selectors from being properly scoped to their
component.

Defaults to `false`.

## `entry_points`

```yaml
transformers:
  angular:
    entry_points:
      - web/main.dart
```

Entrypoint(s) of the application (i.e. where `bootstrap` is invoked or a
`*_test.dart` file that uses `angular_test`). Build systems that re-write files
(such as pub/barback) transform calls to `bootstrap` to `bootstrapStatic` and
initialize code required to run AngularDart applications and tests.

These may be written as a glob format (such as `lib/web/main_*.dart`).
