import 'dart:async';

import 'package:build/build.dart' as build;
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

/// Executes the provided [fn], capturing [BuildError]s and forwarding to logs.
///
/// * [showInternalTraces]: If `true`, [BuildError.stackTrace] is printed.
T runBuildZoned<T>(T Function() fn, {bool showInternalTraces: false}) {
  return runZoned(
    fn,
    onError: (e, s) {
      if (e is BuildError) {
        build.log.severe(
          e.message,
          null,
          showInternalTraces ? e.stackTrace : null,
        );
      } else {
        build.log.severe(
          'Unhandled exception in compiler. Please report a bug!',
          e,
          s,
        );
      }
    },
    zoneSpecification: new ZoneSpecification(
      print: (_, __, ___, line) => build.log.fine(line),
    ),
  );
}

/// Base error type for all fatal errors encountered while compiling.
///
/// There is _intentionally_ no `logFailure` function, as all failures should
/// be as a result of throwing an [BuildError] or an error that extends from
/// [BuildError]. This guarantees that the build is exited as a result of the
/// failure.
class BuildError extends Error {
  /// Message describing the build error.
  final String message;

  @override
  final Trace stackTrace;

  BuildError(this.message, [Trace trace])
      : stackTrace = trace ?? new Trace.current();

  @override
  String toString() => message;
}

/// Logs a notice-level [message].
///
/// Notices do not have an impact on the build, but most build systems will not
/// display them default, and need to opt-in to higher verbosity in order to see
/// the message.
///
/// Example messages:
/// * "Ambiguous configuration, so we assumed X"
/// * "This code is experimental"
/// * "Took XX seconds to process Y"
void logNotice(String message) => build.log.info(message);

/// Logs a warning-level [message].
///
/// Warnings do not have an impact on the build, but most build systems will
/// display them to the user, so the underlying issue should be addressable
/// (i.e. not be an "FYI"), otherwise consider using [logNotice].
///
/// Example messages:
/// * "Could not determine X, falling back to Y. Consider <...> or <...>"
/// * "This code is deprecated"
void logWarning(String message) => build.log.warning(message);

/// Throws a [BuildError] with a predefined [message].
///
/// May optionally wrap a caught stack [trace].
@alwaysThrows
void throwFailure(String message, [StackTrace trace]) {
  throw new BuildError(message, new Trace.from(trace));
}
