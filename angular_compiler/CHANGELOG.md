## 0.3.0

- Always link to `export "...template.dart" files` in `initReflector()`.
- Catch missing field-formal (`this.`) fields and warn in the compiler.
- Does not emit a `registerDependencies` function call for empty constructors.
- `initReflector()` no longer treats `@Pipe` as an `@Injectable` service.

## 0.2.2

- Fixed the outliner to instruct the analyzer to ignore unused imports.
- Add `NgAssetReader`.

## 0.2.1

- Various changes internal to the compiler.

## 0.2.0

- Added various classes and helpers to form the new compile infrastructure:
  - `ComponentReader`
  - `DependencyReader`, `DependencyInvocation`, `DependencyElement`
  - `ProviderReader`, `ProviderElement`
  - `TokenReader`, `TypeTokenElement`, `OpaqueTokenElement`
  - `getInheritanceHierarchy`, `urlOf`
  - `ReflectableReader`, `ReflectableOutput`, `ReflectableClass`

## 0.1.1

- Fixed a bug where flag `entry_points` was only allowed to be a list.

## 0.1.0

- Initial commit of `angular_compiler`.
