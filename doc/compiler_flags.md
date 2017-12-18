# Compiler Flags

The following is a list of supported flags when using the AngularDart compiler
as a _pub/barback transformer_. Any flag you don't see listed below is not
supported in AngularDart 5.x, and will cause the compiler to fail.

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

## `fast_boot`

```yaml
transformers:
  angular:
    fast_boot: false
```

By disabling this flag, AngularDart may choose to generate additional code to
support legacy classes like `SlowComponentLoader` and `ReflectiveInjector`. If
you are using `fastBoot` (formally known as `bootstrapFactory`) then this can
always safely be `true`.

Defaults to `true` in AngularDart ^5.0.0-alpha+2.
