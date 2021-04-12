/// Returns [any] assuming that the return type is [T].
///
/// In [Dart2JS with `--omit-implicit-type-checks`][1] no type check is made.
///
/// [1]: https://dart.dev/tools/dart2js#options
///
/// ```
/// // Has runtime cost.
/// Foo foo = object as Foo;
///
/// // Implicit cast which often leads to subtle bugs.
/// Foo foo = object;
///
/// // Clear intent without cost.
/// Foo foo = unsafeCast<Foo>(object);
/// ```
@pragma('dart2js:tryInline') // Required for next pragma to be effective.
@pragma('dart2js:as:trust') // Omits `as T`.
T unsafeCast<T>(dynamic any) => any as T;
