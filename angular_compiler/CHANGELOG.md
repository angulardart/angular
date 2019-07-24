## 0.4.5

*   The InjectorReader now fails with an explicit error if types are used inside
    a ValueProvider object. Previously, using types in ValueProviders would
    crash the AngularDart compiler.

    Instead of a ValueProvider, use a FactoryProvider for complicated objects,
    such as those that contain types.

*   Removed the `i18n` compiler flag that was previously used to opt-in to
    internationalization in templates before the feature had stabilized.

*   Added support for a command-line flag, `allowed_typedefs_as_di_token`. This
    is intended to be used as a transitional flag to ban using a `typedef` as a
    DI token (which has non-predictable properties in Dart 2).

*   Added `$ChangeDetectionLink`, a type checker for matching the experimental
    `@changeDetectionLink` annotation.

## 0.4.4

*   Maintenance release to support the newest version of `analyzer`.

## 0.4.3

*   FormatExceptions thrown while parsing modules in InjectorReader are now
    rethrown as BuildErrors with source information.

*   The InjectorReader will fail earlier in the compile process on parse errors.

*   Unhandled errors from InjectorReader are now caught and reported with source
    information.

*   BuildError now has factory constructors to create errors for annotations and
    elements.

## 0.4.2

*   Updates the `messages.unresolvedSource` API to support different error
    messages for each `SourceSpan` affected.

*   Update failure message to include an asset id when collecting type
    parameters.

*   `TypedReader` now throws a build error when reading a private type argument.

## 0.4.1

*   Catches an (invalid) `null` token of a provider and throws a better error.

*   Catches an (invalid) `null` value of the function for `FactoryProvider`.

*   Emits all strings for `@GeneratedInjector` as raw (`r'$5.00'`).

*   Supports named arguments for `ValueProvider` and `@GeneratedInjector`.

*   Prevents `InjectorReader.accept()` from crashing when given a dependency
    with no type or token.

## 0.4.0

### New Features

*   Added `TypedElement` to represent a statically parsed `Typed`.

*   `TypedReader.parse()` now returns a `TypedElement`.

*   Added `$Typed`, a `TypeChecker` for `Typed`.

*   Added `TypedReader` for parsing generic directive types.

*   Added support for `void` and `Null` types to appear in tokens.

*   Added `DirectiveVisitor`, and removed `$HostBinding` and `$HostListener`.

*   Added `ModuleReader.extractProviderObjects` to use in the view compiler.

*   Added `logFine` as a new top-level API.

*   Added an internal `cli.dart` library. See `lib/cli.dart` for details.

*   Added `SplitDartEmitter` for internal use.

*   Added `$QueryList` as a `TypeChecker`.

*   Expose the `$Provider` `TypeChecker`.

*   Added `typeArgumentOf` helper method.

*   Added support for recognizing the `MultiToken` type.

*   `CompilerFlags` now supports as a `fast_boot` argument; default is `true`.

*   `ReflectorEmitter` now takes an optional `deferredModules{Source}`.

*   Started adding experimental support for a new `Module` syntax.

### Breaking Changes

*   `CompilerFlags` no longer parses and supports the `'debug'` option and
    `genDebugInfo` is always `false`, and is deprecated pending removal in a
    future version.

*   Removes unused APIs of `ComponentReader`.

*   `TokenReader` no longer supports arbitrary const objects or literals.

*   Removed `use_new_template_parser` flag. The old parser was removed.

*   Removed `$QueryList`.

*   Added `canRead` to `NgAssetReader`.

*   Moved `CompilerFlags` and `Profile` to `cli.dart`.

*   `linkToReference` now requires a second parameter, a `LibraryReader`, and
    treats private types (i.e. prefixed with `_`) as `dynamic` as the compiler
    cannot point to them.

*   `ReflectableEmitter` has been completely replaced with a new implementation.

*   Removed all references and use of determining a "prefix" of a type. This was
    no longer used once `ReflectableEmitter` was re-written.

*   Removed a number of internal flags that were no longer strictly required.

*   `ModuleReader.deduplicateProviders` now returns a `List` not a `Set`, and
    providers that are _multi_ are not removed, as it is a feature of the DI
    system to have multiple of them with the same token.

*   Add the `TypeLink` class, and replace uses of `Uri`.

*   `@Component` and `@Directive` annotated classes are no longer `@Injectable`.
    In practice this means they can no loger be provided as an implicit `const
    Provider(FooComponent)` without either manually adding `@Injectable` or
    refactoring your code. We found this didn't really affect users, and most
    uses of components and directives in these lists were accidental.

### Bug Fixes

*   Fixed a bug where the compiler crashed after resolving a bound type failed.

*   Misspelled or otherwise erroneous annotations on classes now produce a more
    understandable error message, including the element that was annotated and
    the annotation that was not resolved.

*   Fix a bug where `throwFailure` hit an NPE without a stack trace.

*   `linkTypeOf` correctly resolves bound types (i.e. `<T>`) in most cases, and
    can fallback to `dynamic` otherwise.

*   Removed all remaining (invalid) references to `package:barback`.

*   Prevented a `RangeError` that occurred when an invalid import lacked an
    extension.

*   `ReflectorEmitter` now supports `MultiToken` and generic-typed tokens, with
    some known limitations. See https://github.com/dart-lang/angular/issues/782.

*   Fix a bug in the _outliner_ that did not the correct output extension.

## 0.3.0

*   Always link to `export "...template.dart" files` in `initReflector()`.
*   Catch missing field-formal (`this.`) fields and warn in the compiler.
*   Does not emit a `registerDependencies` function call for empty constructors.
*   `initReflector()` no longer treats `@Pipe` as an `@Injectable` service.

## 0.2.2

*   Fixed the outliner to instruct the analyzer to ignore unused imports.
*   Add `NgAssetReader`.

## 0.2.1

*   Various changes internal to the compiler.

## 0.2.0

*   Added various classes and helpers to form the new compile infrastructure:
    *   `ComponentReader`
    *   `DependencyReader`, `DependencyInvocation`, `DependencyElement`
    *   `ProviderReader`, `ProviderElement`
    *   `TokenReader`, `TypeTokenElement`, `OpaqueTokenElement`
    *   `getInheritanceHierarchy`, `urlOf`
    *   `ReflectableReader`, `ReflectableOutput`, `ReflectableClass`

## 0.1.1

*   Fixed a bug where flag `entry_points` was only allowed to be a list.

## 0.1.0

*   Initial commit of `angular_compiler`.
