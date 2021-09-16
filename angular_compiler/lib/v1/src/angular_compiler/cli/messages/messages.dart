import '../messages.dart';

/// URL of the AngularDart GitHub repository.
const _github = 'https://github.com/angulardart/angular';

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
  String removeGlobalSingletonService(String service) =>
      '"$service" is an app-wide, singleton service provided by the '
      'framework that cannot be overridden or manually provided.\n'
      '\n'
      'If you are providing this service to fix a missing provider error, you '
      "likely have created an injector that is disconnected from the app's "
      'injector hierarchy. This can occur when instantiating an injector and '
      'you omit the parent injector argument, or explicitly configure an empty '
      'parent injector. Please check your injector constructors to make sure '
      "the current context's injector is passed as the parent.";
}
