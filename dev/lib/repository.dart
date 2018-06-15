/// Tools for searching and parsing relevant packages in this repository.
library dev.repository;

import 'dart:io' show Directory, File, Process;

import 'package:collection/collection.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart' as yaml;

/// A set of packages, i.e., a mono-repository.
class Repository {
  /// Current repository, i.e. as determined by [p.current].
  static Repository get current => Repository.fromPath(p.current);

  static final _defaultInclude = [
    Glob('**/pubspec.yaml'),
  ];

  static final _defaultExclude = [
    Glob('angular/tools/**'),
    Glob('**/build/**'),
  ];

  static bool _isExcluded(String relativePath, List<Glob> exclude) {
    for (final glob in exclude) {
      if (glob.matches(relativePath)) {
        return true;
      }
    }
    return false;
  }

  /// Returns a list of files pointing to relevant `pubspec.yaml` files.
  static List<File> _findPubspecs(
    List<Glob> include,
    List<Glob> exclude, {
    String rootPath,
  }) =>
      include
          .expand((g) => g.listSync(root: rootPath))
          .cast<File>()
          .where(
              (f) => !_isExcluded(p.relative(f.path, from: rootPath), exclude))
          .toList()
            ..sort((a, b) => a.path.compareTo(b.path));

  /// A set of packages found within the repository.
  final List<Package> packages;

  /// Root path of the repository.
  final String path;

  /// Returns a set of packages in the current repository [path].
  ///
  /// If [include] is not specified, it defaults to `['**/pubspec.yaml']`.
  /// If [exclude] is not specified, it defaults to
  /// ```
  /// [
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
        .map((f) => Package.loadAndParse(path, p.dirname(f.path)))
        .toList();
    return Repository(packages, path);
  }

  @visibleForTesting
  const Repository(this.packages, this.path);

  @override
  bool operator ==(o) =>
      o is Repository &&
      path == o.path &&
      const ListEquality().equals(packages, o.packages);

  @override
  int get hashCode => path.hashCode ^ const ListEquality().hash(packages);

  /// Reads `prefix.yaml`, used for generating `.travis.yml`.
  String readTravisPrefix() {
    final file = File(p.join(
      path,
      'dev',
      'tool',
      'travis',
      'prefix.yaml',
    ));
    return file.readAsStringSync();
  }

  /// Reads `postfix.yaml`, used for generating `.travis.yml`.
  String readTravisPostfix() {
    final file = File(p.join(
      path,
      'dev',
      'tool',
      'travis',
      'postfix.yaml',
    ));
    return file.readAsStringSync();
  }

  @override
  String toString() {
    final buffer = StringBuffer('\n  path: $path\n');
    for (final package in packages) {
      buffer.writeln('    ${'$package'.split('\n').join('\n    ')}');
    }
    return buffer.toString();
  }
}

/// A package within a [Repository].
///
/// Various metadata are extracted for tooling to use.
class Package {
  static const _pubspecYaml = 'pubspec.yaml';
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
      return MapEntry(k, _parseVersion(v));
    });
  }

  static VersionConstraint _parseVersion(dynamic version) {
    if (version is String) {
      try {
        return VersionConstraint.parse(version);
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

  /// Relative path to the package, from [root].
  final String path;

  /// Absolute path to the repository root.
  final String root;

  @visibleForTesting
  factory Package.loadAndParse(String repositoryRootPath, String packagePath) {
    final pubspec = File(p.join(
      repositoryRootPath,
      packagePath,
      _pubspecYaml,
    ));
    final yamlDoc = yaml.loadYaml(
      pubspec.readAsStringSync(),
      sourceUrl: pubspec.path,
    ) as yaml.YamlMap;
    return Package(
      dependencies: _parseDependencies(yamlDoc['dependencies']),
      devDependencies: _parseDependencies(yamlDoc['dev_dependencies']),
      path: p.relative(packagePath, from: repositoryRootPath),
      root: repositoryRootPath,
    );
  }

  @visibleForTesting
  const Package({
    this.dependencies = const {},
    this.devDependencies = const {},
    @required this.path,
    @required this.root,
  });

  @override
  bool operator ==(o) =>
      o is Package &&
      path == o.path &&
      const MapEquality().equals(dependencies, o.dependencies) &&
      const MapEquality().equals(devDependencies, o.devDependencies);

  @override
  int get hashCode =>
      path.hashCode ^
      const MapEquality().hash(dependencies) ^
      const MapEquality().hash(devDependencies);

  /// Whether a browser is likely needed to execute a test in this package.
  bool get hasBrowserTests {
    return devDependencies.containsKey('build_web_compilers');
  }

  /// Whether `tool/test.sh` should be used instead of `pub run test`.
  ///
  /// This is usually an indication of custom configuration.
  bool get hasCustomTestScript {
    return File(p.join(root, path, _testScript)).existsSync();
  }

  /// Whether a `test/` directory exists for this package.
  bool get hasTests {
    return Directory(p.join(root, path, _testFolder)).existsSync();
  }

  /// Whether Dart2JS should be used, as well as DDC.
  ///
  /// **NOTE**: This is currently *always* `false`.
  bool get hasReleaseMode => false;

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

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('path: $path');
    buffer.writeln('dependencies:');
    dependencies.forEach((name, version) {
      buffer.writeln('  $name: $version');
    });
    buffer.writeln('devDependencies:');
    devDependencies.forEach((name, version) {
      buffer.writeln('  $name: $version');
    });
    return buffer.toString();
  }
}
