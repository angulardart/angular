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

  /// What message should be used for OnPush compatibility warnings.
  String warningForOnPushCompatibility(String name) {
    return ''
        '"$name" doesn\'t use "ChangeDetectionStrategy.OnPush", but '
        'is used by a component that does. This is unsupported and unlikely '
        'to work as expected.';
  }

  /// What URL should be used for filing bugs when the compiler fails.
  String get urlFileBugs;
}
