import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';

class Cli {
  /// Path to AngularDart instance. Defaults to the root of this repository.
  String angular;
  final String _defaultAngular =
      dirname(dirname(dirname(dirname(Platform.script.path))));

  /// Path to Dart SDK for building Angular Components.
  String sdk;

  /// Angular Components git url. Defaults to the official GitHub repository.
  String componentsGitUrl;
  final String _defaultComponentsGitUrl =
      'https://github.com/dart-lang/angular_components.git';

  /// Angular Components git ref. Defaults to to "master".
  String componentsGitRef;
  final String _defaultComponentsGitRef = 'master';

  Cli(List<String> args) : assert(args != null) {
    _handleArgs(args);
  }

  void _handleArgs(List<String> args) {
    final parser = ArgParser()
      ..addOption(
        'angular',
        abbr: 'a',
        defaultsTo: _defaultAngular,
        help: 'Specify AngularDart location.',
      )
      ..addOption(
        'sdk',
        abbr: 's',
        help: 'Specify Dart SDK location.',
      )
      ..addOption(
        'components-git-url',
        abbr: 'g',
        defaultsTo: _defaultComponentsGitUrl,
        help: 'Specify Angular Components git repository URL.',
      )
      ..addOption(
        'components-git-ref',
        abbr: 'r',
        defaultsTo: _defaultComponentsGitRef,
        help: 'Specify Angular Components git repository ref.',
      );
    final results = parser.parse(args);
    angular = results['angular'];
    sdk = results['sdk'];
    componentsGitUrl = results['components-git-url'];
    componentsGitRef = results['components-git-ref'];
  }
}
