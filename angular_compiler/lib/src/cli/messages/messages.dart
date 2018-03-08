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
      '  $urlFileBugs';

  @override
  final urlFileBugs = 'https://github.com/dart-lang/angular/issues/new';
}
