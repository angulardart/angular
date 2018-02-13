/// **INTERNAL ONLY**: Runtime-only code internal to the framework.
///
/// We use these exported functions and classes internally and in code
/// generation, but do not expose them to the end-user, as they are unsafe to
/// rely on.
library angular.src.runtime;

export 'runtime/optimizations.dart' show isDevMode, unsafeCast;
