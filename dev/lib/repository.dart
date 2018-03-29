/// Tools for searching and parsing relevant packages in this repository.
library dev.repository;

import 'dart:io' show Directory, File, Process;

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart' as yaml;

/// A set of packages, i.e., a mono-repository.
class Repository {
  /// Current repository, i.e. as determined by [p.current].
  static Repository get current => new Repository.fromPath(p.current);

  static final _defaultInclude = [
    new Glob('**/pubspec.yaml'),
  ];

  static final _defaultExclude = [
    new Glob('dev/**'),
    new Glob('angular/tools/**'),
    new Glob('**/build/**'),
  ];

  /// Returns a list of files pointing to relevant `pubspec.yaml` files.
  static List<File> _findPubspecs(
    List<Glob> include,
    List<Glob> exclude, {
    String rootPath,
  }) =>
      include
          .expand((g) => g.listSync(root: rootPath))
          .cast<File>()
          .where((f) => !exclude.any((g) => g.matches(f.path)))
          .toList()
            ..sort((a, b) => a.path.compareTo(b.path));

  /// A set of packages found within the repository.
  final List<Package> packages;

  /// Root path.
  final String rootPath;

  /// Returns a set of packages in the current repository [path].
  ///
  /// If [include] is not specified, it defaults to `['**/pubspec.yaml']`.
  /// If [exclude] is not specified, it defaults to
  /// ```
  /// [
  ///   'dev/**',
  ///   'angular/tools/**',
  ///   '**/build/**',
  /// ]
  /// ```
  factory Repository.fromPath(
    String path, {
    List<Glob> include,
    List<Glob> exclude,
  }) {
    include ??= _defaultInclude;
    exclude ??= _defaultExclude;
    final packages = _findPubspecs(include, exclude, rootPath: path)
        .map((f) => new Package._(p.relative(p.dirname(f.path), from: path)))
        .toList();
    return new Repository._(packages, path);
  }

  // Internal.
  const Repository._(this.packages, this.rootPath);

  /// Reads `prefix.yaml`, used for generating `.travis.yml`.
  String readTravisPrefix() {
    final file = new File(p.join(
      rootPath,
      'dev',
      'tool',
      'travis',
      'prefix.yaml',
    ));
    return file.readAsStringSync();
  }

  /// Reads `postfix.yaml`, used for generating `.travis.yml`.
  String readTravisPostfix() {
    final file = new File(p.join(
      rootPath,
      'dev',
      'tool',
      'travis',
      'postfix.yaml',
    ));
    return file.readAsStringSync();
  }
}

/// A package within a [Repository].
///
/// Various metadata are extracted for tooling to use.
class Package {
  static const _dartTestYaml = 'dart_test.yaml';
  static const _pubspecYaml = 'pubspec.yaml';
  static const _releaseYaml = 'build.release.yaml';
  static const _testFolder = 'test';
  static final _testScript = p.join('tool', 'test.sh');

  /// Returns a raw YAML map as a `Map<String, VersionConstraint>`.
  ///
  /// Where a `VersionConstraint` was not parse-able, `ANY` is used instead.
  static Map<String, VersionConstraint> _parseDependencies(dynamic deps) {
    if (deps == null) {
      return const {};
    }
    return (deps as Map).cast<String, dynamic>().map((k, v) {
      return new MapEntry(k, _parseVersion(v));
    });
  }

  static VersionConstraint _parseVersion(dynamic version) {
    if (version is String) {
      try {
        return new VersionConstraint.parse(version);
      } on FormatException catch (_) {
        return VersionConstraint.any;
      }
    }
    return VersionConstraint.any;
  }

  /// Dependencies of this package.
  final Map<String, VersionConstraint> dependencies;

  /// Developer dependencies of this package.
  final Map<String, VersionConstraint> devDependencies;

  /// Path to the package, from the root of the repository.
  final String path;

  factory Package._(String path) {
    final pubspec = new File(p.join(path, _pubspecYaml));
    final yamlDoc = yaml.loadYaml(
      pubspec.readAsStringSync(),
      sourceUrl: pubspec.path,
    ) as yaml.YamlMap;
    return new Package._with(
      dependencies: _parseDependencies(yamlDoc['dependencies']),
      devDependencies: _parseDependencies(yamlDoc['dev_dependencies']),
      path: path,
    );
  }

  const Package._with({
    this.dependencies,
    this.devDependencies,
    this.path,
  });

  /// Whether a browser is needed to execute at least 1 test in this package.
  bool get hasBrowserTests {
    final file = new File(p.join(path, _dartTestYaml));
    if (file.existsSync()) {
      // TODO: Improve this check.
      return file.readAsStringSync().contains('chrome');
    }
    return false;
  }

  /// Whether `tool/test.sh` should be used instead of `pub run test`.
  ///
  /// This is usually an indication of custom configuration.
  bool get hasCustomTestScript {
    return new File(p.join(path, _testScript)).existsSync();
  }

  /// Whether a `test/` directory exists for this package.
  bool get hasTests => new Directory(p.join(path, _testFolder)).existsSync();

  /// Whether a `build.release.yaml` exists in this package.
  ///
  /// This is an indication that Dart2JS should be used, as well as DDC.
  bool get hasReleaseMode => new File(p.join(path, _releaseYaml)).existsSync();

  /// Whether `build_runner` is a dependency of this package.
  bool get isBuildable => devDependencies.containsKey('build_runner');

  /// Runs `pub get` in this package.
  void runPubGet() {
    Process.runSync('pub', ['get'], workingDirectory: path);
  }

  /// Runs `pub upgrade` in this package.
  void runPubUpgrade() {
    Process.runSync('pub', ['upgrade'], workingDirectory: path);
  }
}
