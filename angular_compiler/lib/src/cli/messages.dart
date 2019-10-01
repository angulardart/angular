import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

import 'messages/messages.dart';

/// Returns the currently bound [Messages] instance.
final Messages messages = const $Messages();

class SourceSpanMessageTuple {
  final SourceSpan sourceSpan;
  final String message;
  SourceSpanMessageTuple(this.sourceSpan, this.message);
}

/// Defines common messages to use during compilation.
abstract class Messages {
  @visibleForOverriding
  const Messages.base();

  /// Possible reasons that static analysis/the compiler failed.
  String get analysisFailureReasons;

  /// Returns a message that the following [sourceSpans] were unresolvable.
  String unresolvedSource(Iterable<SourceSpanMessageTuple> tuples,
      {@required String reason}) {
    final buffer = StringBuffer(reason)..writeln()..writeln();
    for (final tuple in tuples) {
      buffer.writeln(tuple.sourceSpan.message(tuple.message));
    }
    return buffer.toString();
  }

  /// What URL should be used for OnPush compatibility documentation.
  String get urlOnPushCompatibility;

  /// What URL should be used for filing bugs when the compiler fails.
  String get urlFileBugs;
}
