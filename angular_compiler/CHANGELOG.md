### New features

*   Added an internal `cli.dart` library. See `lib/cli.dart` for details.
*   Added `SplitDartEmitter` for internal use.
*   Added `$QueryList` as a `TypeChecker`.

### Bug fixes

*   Removed all remaining (invalid) references to `package:barback`.

### Breaking changes

*   Added `canRead` to `NgAssetReader`.
*   Moved `CompilerFlags` and `Profile` to `cli.dart`.

## 0.4.0-alpha+5

### Bug fixes

*   `linkTypeOf` correctly resolves bound types (i.e. `<T>`) in most cases, and
    can fallback to `dynamic` otherwise.

### Breaking changes

*   Requires `source_gen ^0.7.4+2` (was previously `^0.7.0`).

*   `linkToReference` now requires a second parameter, a `LibraryReader`, and
    treats private types (i.e. prefixed with `_`) as `dynamic` as the compiler
    cannot point to them.

*   `ReflectableEmitter` has been completely replaced with a new implementation.

*   Removed all references and use of determining a "prefix" of a type. This was
    no longer used once `ReflectableEmitter` was re-written.

*   Removed a number of internal flags that were no longer strictly required.

## 0.4.0-alpha+4

### Breaking changes

*   `ModuleReader.deduplicateProviders` now returns a `List` not a `Set`, and
    providers that are _multi_ are not removed, as it is a feature of the DI
    system to have multiple of them with the same token.

*   Add the `TypeLink` class, and replace uses of `Uri`.

*   Require `code_builder ^3.0.0`.

### New features

*   Added `typeArgumentOf` helper method.

*   Added `ReflectableEmitter.useCodeBuilder`, which uses `package:code_builder`
    instead of an ad-hoc string-based output for Dart code. Once this passes the
    same suite of tests the original strategy will be removed.

### Bug fixes

*   Prevented a `RangeError` that occurred when an invalid import lacked an
    extension.

*   `ReflectorEmitter` now supports `MultiToken` and generic-typed tokens, with
    some known limitations. See https://github.com/dart-lang/angular/issues/782.

## 0.4.0-alpha+3

*   Added support for recognizing the `MultiToken` type.

## 0.4.0-alpha+2

*   `CompilerFlags` now supports as a `fast_boot` argument; default is `true`.
*   `ReflectorEmitter` now takes an optional `deferredModules{Source}`.

## 0.4.0-alpha+1

*   Now using `code_builder: '>=2.0.0-beta <3.0.0'`.

### Bug fixes

*   Correctly depend on `analyzer: ^0.31.0-alpha.1`.

## 0.4.0-alpha

While _technically_ a breaking change from `0.3.0`, it will likely be safe for
most users to set bound constraints that include `0.4.0`; this will allow users
of the `4.0.0` AngularDart release to utilize the new `generator_inputs`
optimization.

```yaml
dependencies:
  angular_compiler: '>=0.3.0 <0.5.0'
```

### Breaking changes

*   `@Component` and `@Directive` annotated classes are no longer `@Injectable`.
    In practice this means they can no loger be provided as an implicit `const
    Provider(FooComponent)` without either manually adding `@Injectable` or
    refactoring your code. We found this didn't really affect users, and most
    uses of components and directives in these lists were accidental.

### New features

*   Add `generator_inputs` flag support to `CompilerFlags`, to speed up builds
    that use `barback` (i.e. pub transformers). By default in `pub` it assumed
    that all files relative to the same package have the AngularDart transformer
    run on them:

```
lib/
  foo.dart
  bar.dart
```

This used to asynchronously block and wait for generation to complete, but at
`0.3.1` will instead infer that a relative import _will_ eventually have a
generated file:

```dart
// foo.dart
import 'bar.dart';
```

While this could be considered a **breaking change**, in practice it should be
breaking only if the `$include` or `$exclude` flags are being used to control
what files have the AngularDart generator run on them. In that case, the flag
can be controlled:

```yaml
transformers:
  - angular:
      $include:
        - lib/foo.dart
      generator_inputs:
        - lib/foo.dart      # Only foo.dart, not bar.dart.
        - lib/src/**.dart   # But include everything else.
```

*   Started adding experimental support for a new `Module` syntax.

### Bug fixes

*   Fix a bug in the _outliner_ that did not the correct output extension.

## 0.3.0

-   Always link to `export "...template.dart" files` in `initReflector()`.
-   Catch missing field-formal (`this.`) fields and warn in the compiler.
-   Does not emit a `registerDependencies` function call for empty constructors.
-   `initReflector()` no longer treats `@Pipe` as an `@Injectable` service.

## 0.2.2

-   Fixed the outliner to instruct the analyzer to ignore unused imports.
-   Add `NgAssetReader`.

## 0.2.1

-   Various changes internal to the compiler.

## 0.2.0

-   Added various classes and helpers to form the new compile infrastructure:
    -   `ComponentReader`
    -   `DependencyReader`, `DependencyInvocation`, `DependencyElement`
    -   `ProviderReader`, `ProviderElement`
    -   `TokenReader`, `TypeTokenElement`, `OpaqueTokenElement`
    -   `getInheritanceHierarchy`, `urlOf`
    -   `ReflectableReader`, `ReflectableOutput`, `ReflectableClass`

## 0.1.1

-   Fixed a bug where flag `entry_points` was only allowed to be a list.

## 0.1.0

-   Initial commit of `angular_compiler`.
