import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';
import 'package:logging/logging.dart';

final log = Logger('Pubspec');

class Pubspec {
  /// Pubspec file handle.
  final File _file;

  Pubspec(String workspaceDir)
      : assert(workspaceDir != null),
        _file = File(join(workspaceDir, 'pubspec.yaml'));

  /// Rewrite pubspec.yaml dependency_overrides section.
  /// It adds AngularDart packages overrides e.g.
  ///     'angular_ast': {'path': '/path/to/angular/angular_ast')}.
  /// It keeps overrides not related to AngularDart unchanged.
  Future<void> overrideAngularDependencies(String angular) async {
    final pubspec = await _read();
    _overrideAngularDependencies(angular, pubspec);
    _write(pubspec);
  }

  Future<Map<dynamic, dynamic>> _read() async {
    log.info('Loading pubspec.yaml: "${_file.path}"');
    final contents = await _file.readAsString();
    final yaml = loadYaml(contents);
    final _json = json.encode(yaml);
    final map = json.decode(_json);
    return map as Map;
  }

  void _overrideAngularDependencies(
      String angular, Map<dynamic, dynamic> pubspec) {
    log.info('Overriding Angular dependencies');
    log.info('Angular used for overrides: "${angular}"');

    final overrides = {
      'angular': {'path': join(angular, 'angular')},
      'angular_ast': {'path': join(angular, 'angular_ast')},
      'angular_compiler': {'path': join(angular, 'angular_compiler')},
      'angular_router': {'path': join(angular, 'angular_router')},
      'angular_forms': {'path': join(angular, 'angular_forms')},
    };
    pubspec['dependency_overrides'] ??= {};
    pubspec['dependency_overrides'].addAll(overrides);

    log.info(
        'Post-update dependency_overrides:\n${pubspec['dependency_overrides']}');
  }

  void _write(Map<dynamic, dynamic> pubspec) {
    log.info('Writing to pubspec.yaml: "${_file.path}"');
    _file.writeAsStringSync(json.encode(pubspec));
  }
}
