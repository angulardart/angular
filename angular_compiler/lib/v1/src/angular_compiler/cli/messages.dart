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
  const Messages.base();

  /// Possible reasons that static analysis/the compiler failed.
  String get analysisFailureReasons;

  /// An explanation that optional dependencies are expected to be nullable.
  String get optionalDependenciesNullable =>
      'For constructors or functions that are potentially invoked by '
      'dependency injection, nullable types (i.e. "Engine?") must be annotated '
      '@Optional(), and likewise parameters annotated with @Optional() must be '
      'nullable in opted-in libraries (i.e. "@Optional() Engine?")';

  /// Returns a message that the following [sourceSpans] were unresolvable.
  String unresolvedSource(
    Iterable<SourceSpanMessageTuple> tuples, {
    required String reason,
  }) {
    final buffer = StringBuffer(reason)
      ..writeln()
      ..writeln();
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

  /// Returns a message that the following global singleton [service] should be
  /// removed from injector or providers.
  String removeGlobalSingletonService(String service);
}
