import '../messages.dart';

/// URL of the AngularDart GitHub repository.
const _github = 'https://github.com/dart-lang/angular';

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
  final urlFileBugs = '$_github/issues/new';

  @override
  final urlOnPushCompatibility = '$_github/blob/master/doc/advanced/on-push.md'
      '#compatibility-with-default-change-detection';
}
