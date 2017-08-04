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
