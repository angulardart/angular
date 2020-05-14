/// A partial copy of `angular/lib/src/runtime.dart`.
///
/// To avoid circular dependencies and to retain behavior since the metadata
/// annotations are exported as part of the runtime code (`package:angular`)
/// these three members were copied.
///
/// TODO(b/155776466): Delete this shim once no longer necessary.
library angular_compiler.v1.src.metadata.runtime_shim;

/// Returns `true` when `assert` is enabled in this runtime.
///
/// See [isDevMode] for the framework internal visible API.
bool get _assertionsEnabled {
  var enabled = false;
  assert(enabled = true);
  return enabled;
}

/// Returns `true` when `assert` is enabled in this runtime.
///
/// Allows conditional tree-shaking of branches that are for test/debug only:
/// ```
/// if (isDevMode) {
///   doExpensiveDevOnlyCheck();
/// }
/// ```
bool get isDevMode => _assertionsEnabled;

/// Returns [any] assuming that the return type is [T].
///
/// May be used conditionally in Dart2JS with `--trust-type-annotations`,
/// without relying on an implicit downcast:
/// ```
/// // Has runtime cost.
/// Foo foo = object as Foo;
///
/// // Implicit cast which often leads to subtle bugs.
/// Foo foo = object;
///
/// // Clear intent without cost.
/// Foo foo = unsafeCost<Foo>(object);
/// ```
T unsafeCast<T>(dynamic any) => any;
