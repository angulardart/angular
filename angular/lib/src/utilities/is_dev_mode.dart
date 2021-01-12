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
