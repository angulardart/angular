import 'package:build/build.dart' as build;
import 'package:source_span/source_span.dart';

/// Creates a source span with line and column numbers.
SourceSpan sourceSpanWithLineInfo(
  int offset,
  int length,
  String source,
  Uri uri,
) {
  final sourceFile = SourceFile.fromString(source, url: uri);
  return sourceFile.span(offset, offset + length);
}

/// Logs a fine-level [message].
///
/// Messages do not have an impact on the build, and most build systems will not
/// display by default, and need to opt-in to higher verbosity in order to see
/// the message.
///
/// These are closer to debug-only messages.
void logFine(String message) => build.log.fine(message);

/// Logs a notice-level [message].
///
/// Notices do not have an impact on the build, but most build systems will not
/// display by default, and need to opt-in to higher verbosity in order to see
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
