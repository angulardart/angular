# Compiler Flags

The following is a list of supported flags when using the AngularDart compiler
with the `build_runner` build system. Any flag you _don't_ see listed below may
not be supported in the current build of AngularDart 5.x, and could cause the
compiler to fail.

YAML files below are expected to be in `build.yaml` for a given project.

## `use_legacy_style_encapsulation`

```yaml
targets:
  $default:
    builders:
      angular:
        options:
          use_legacy_style_encapsulation: true
```

**DEPRECATED**: Support for this flag will be removed in a future release.

Enables the use of deprecated Shadow DOM CSS selectors, and cause shadow host
selectors to prevent a series of selectors from being properly scoped to their
component.

Defaults to `false`.

## `fast_boot`

```yaml
targets:
  $default:
    builders:
      angular:
        options:
          fast_boot: false
```

By disabling this flag, AngularDart may choose to generate additional code to
support legacy classes like `SlowComponentLoader` and `ReflectiveInjector`. If
you are using `fastBoot` (formally known as `bootstrapFactory`) then this can
always safely be `true`.

Defaults to `true` in AngularDart ^5.0.0-alpha+2.

## `use_new_template_parser`

```yaml
targets:
  $default:
    builders:
      angular:
        options:
          use_new_template_parser: false
```

By disabling this flag, AngularDart will use the older, less-strict template
parser, which will eventually be removed. Only disable this option if you need
additional time to migrate.

Defaults to `true` in AngularDart ^5.0.0-alpha+5.
