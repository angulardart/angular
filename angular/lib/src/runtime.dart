/// **INTERNAL ONLY**: Runtime-only code internal to the framework.
///
/// We use these exported functions and classes internally and in code
/// generation, but do not expose them to the end-user, as they are unsafe to
/// rely on.
library angular.src.runtime;

import 'runtime/messages/messages.dart';

export 'runtime/check_binding.dart'
    show
        UnstableExpressionError,
        checkBinding,
        debugEnterThrowOnChanged,
        debugExitThrowOnChanged,
        debugThrowIfChanged;

export 'runtime/optimizations.dart' show isDevMode, unsafeCast;

/// Formatting service for displaying runtime text or error message bodies.
///
/// Internally, this may be implemented differently in order to display internal
/// only links, and likewise when exported to GitHub/Pub.
const runtimeMessages = Messages();
