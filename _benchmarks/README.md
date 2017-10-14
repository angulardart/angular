# _benchmarks

This package contains code for an external benchmarking framework to run and
reporting timings for. We don't currently have an open source tool that is well
supported, but this package allows AngularDart developers to check in benchmark
code alongside the framework.

The tests (`/test`) are entirely to ensure this code continues to work.

## Benchmarks

### Dependency Injection

#### Create 20 Bindings

Configures dependency injection for 20 standalone services:

```dart
const flat20Bindings = const [
  Service1,
  Service2,
  ...,
  Service19,
  Service20,
];
```

May be run either with `@Component(providers: const [ ... ])` or
`ReflectiveInjector`.

* `create_20_bindings_directive.dart`
* `create_20_bindings_reflective.dart`

#### Create Tree

Configures dependency injection for a simple web-like application tree.

```dart
//                             <App>
//                             /   \
//                          <Page><Page>
//                          / | \ / |  \
//                         Panels Panels
//                        /*           \*
//                       Tabs         Tabs
```

May be run either with `@Component(providers: const [ ... ])` or
`ReflectiveInjector`.

* `create_tree_bindings_directive.dart`
* `create_tree_bindings_reflective.dart`
