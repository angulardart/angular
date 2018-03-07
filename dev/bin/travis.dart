import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:angular.dev/dry.dart';
import 'package:angular.dev/find.dart';

/// Writes `<root>/.travis.yml` based on the configuration in this file.
void main(List<String> args) {
  final dryRun = isDryRun(args);

  // Start the preamble of .travis.yml.
  final prefix = new File(p.join('dev', 'tool', 'travis', 'prefix.yaml'))
      .readAsStringSync();
  final postfix = new File(p.join('dev', 'tool', 'travis', 'postfix.yaml'))
      .readAsStringSync();

  // Make build stages.
  final stages = <String>[];
  final packages =
      findRelevantPubspecs().map((f) => p.normalize(p.dirname(f.path)));

  for (final package in packages) {
    // Every package has a pre-submit and build phase.
    stages.add(_analyze(package));

    if (_isBuildable(package)) {
      stages.add(_build(package));
    }

    // Some packages will also build in "release" (Dart2JS) mode.
    if (_hasReleaseMode(package)) {
      stages.add(_build(package, release: true));
    }

    // Some packages will have tests.
    if (_hasTests(package)) {
      final requiresBrowser = _hasBrowserTests(package);
      stages.add(_test(package, browser: requiresBrowser));
      if (_hasReleaseMode(package)) {
        stages.add(_test(package, browser: requiresBrowser));
      }
    }
  }

  final output = new File('.travis.yml');
  final contents = ([
    prefix,
    stages.join('\n\n'),
    '',
    postfix,
    '',
  ].join('\n'));

  if (dryRun) {
    if (output.readAsStringSync().trimRight() != contents.trimRight()) {
      exitCode = 1;
      stderr.writeln(
        '${output.path} was not updated. Run dev/travis/config.dart.',
      );
    } else {
      stdout.writeln('No updates needed to ${output.path}.');
    }
    return;
  }
  output.writeAsStringSync(contents);
}

/// Whether there is a `test/` directory in this [path].
bool _hasTests(String path) {
  return new Directory(p.join(path, 'test')).existsSync();
}

/// Whether there is a `build.release.yaml` in this [path].
bool _hasReleaseMode(String path) {
  return new File(p.join(path, 'build.release.yaml')).existsSync();
}

/// Whether there are browsers being run as part `dart_test.yaml`.
bool _hasBrowserTests(String path) {
  final config = new File(p.join(path, 'dart_test.yaml'));
  if (config.existsSync()) {
    final text = config.readAsStringSync();
    // This could be a lot better.
    return text.contains('chrome');
  }
  return false;
}

/// Whether there is a custom `tool/test.sh` in this package.
bool _hasCustomTestScript(String path) {
  return new File(p.join(path, 'tool', 'test.sh')).existsSync();
}

/// Whether there is `build_runner` in `pubspec.yaml`.
bool _isBuildable(String path) => new File(p.join(path, 'pubspec.yaml'))
    .readAsStringSync()
    .contains('build_runner:');

String _analyze(String package) {
  return [
    '    - stage: presubmit',
    '      script: ./tool/travis.sh analyze',
    '      env: PKG="$package"',
  ].join('\n');
}

String _build(String package, {bool release: false}) {
  return [
    '    - stage: building',
    '      script: ./tool/travis.sh build${release ? ':release': ''}',
    '      env: PKG="$package"',
    '      cache:',
    '        directories:',
    '          - $package/.dart_tool',
  ].join('\n');
}

String _test(
  String package, {
  bool browser: false,
  bool release: false,
}) {
  if (_hasCustomTestScript(package)) {
    return [
      '    - stage: testing',
      '      script:',
      '        - cd $package',
      '        - ./tool/test.sh',
      '      env: PKG="$package"',
      '      cache:',
      '        directories:',
      '          - $package/.dart_tool',
    ].join('\n');
  }
  final out = [
    '    - stage: testing',
    '      script: ./tool/travis.sh test${release ? ':release' : ''}',
    '      env: PKG="$package"',
    '      cache:',
    '        directories:',
    '          - $package/.dart_tool',
  ];
  if (browser) {
    out.addAll([
      r'      addons:',
      r'        chrome: stable',
      r'      before_install:',
      r'        - export DISPLAY=:99.0',
      r'        - sh -e /etc/init.d/xvfb start',
      r'        - "t=0; until (xdpyinfo -display :99 &> /dev/null || test $t -gt 10); do sleep 1; let t=$t+1; done"',
    ]);
  }
  return out.join('\n');
}
