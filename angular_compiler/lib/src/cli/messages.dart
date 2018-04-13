import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

import 'messages/messages.dart';

/// Returns the currently bound [Messages] instance.
final Messages messages = const $Messages();

/// Defines common messages to use during compilation.
abstract class Messages {
  @visibleForOverriding
  const Messages.base();

  /// Possible reasons that static analysis/the compiler failed.
  String get analysisFailureReasons;

  /// Returns a message that the following [sourceSpans] were unresolvable.
  String unresolvedSource(
    Iterable<SourceSpan> sourceSpans, {
    String message: 'Was not resolved',
    @required String reason,
  }) {
    final buffer = new StringBuffer(reason)..writeln()..writeln();
    for (final sourceSpans in sourceSpans) {
      buffer.writeln(sourceSpans.message(message));
    }
    return buffer.toString();
  }

  /// What URL should be used for filing bugs when the compiler fails.
  String get urlFileBugs;
}
