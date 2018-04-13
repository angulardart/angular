import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

import '../messages.dart';

/// Concrete implementation of [Messages] for external users.
class $Messages extends Messages {
  const $Messages() : super.base();

  @override
  String get analysisFailureReasons =>
      'Try the following when diagnosing the problem:\n'
      '  * Check your IDE or with the dartanalyzer for errors or warnings\n'
      '  * Check your "import" statements for missing or incorrect URLs\n'
      '\n'
      'If you are still stuck, file an issue and include this error message:\n'
      '$urlFileBugs';

  @override
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

  @override
  final urlFileBugs = 'https://github.com/dart-lang/angular/issues/new';
}
