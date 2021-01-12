/// Angular Components integration test.
/// It verifies if 'angular_components_example' from 'angular_components' repo
/// can be built with local instance of AngularDart.

import 'package:examples.angular_components_integration/cli.dart';
import 'package:examples.angular_components_integration/pub.dart';
import 'package:examples.angular_components_integration/pubspec.dart';
import 'package:examples.angular_components_integration/repository.dart';
import 'package:logging/logging.dart';

final log = Logger('Main');

void main(List<String> args) async {
  configureLogging();
  final cli = Cli(args);
  final repository = await Repository.fetch(cli.componentsGitUrl,
      gitRef: cli.componentsGitRef);
  repository.changeTo(['examples', 'angular_components_example']);
  final pubspec = Pubspec(repository.workingDir);
  await pubspec.overrideAngularDependencies(cli.angular);
  final pub = await Pub.init(repository.workingDir, sdk: cli.sdk);
  await pub.update();
  await pub.build();
}

void configureLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((r) {
    final log = '${r.level.name}: ${r.time}: ${r.loggerName}: ${r.message}';
    print(log);
  });
}
