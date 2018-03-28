import 'package:meta/meta.dart';

import 'repository.dart';

/// Generates `./.travis.yml` and `tool/presubmit.sh` for the repository.
class TravisGenerator {
  /// Analyzes and returns output files as part of scanning [repository].
  static TravisGenerator generate(Repository repository) {
    final writer = new _OutputWriter(
      repository.readTravisPrefix(),
      repository.readTravisPostfix(),
    );
    for (final package in repository.packages) {
      // Every package has a pre-submit and build phase.
      writer.writeAnalysisStep(path: package.path);
      if (package.isBuildable) {
        writer.writeBuildStep(
          path: package.path,
          release: package.hasReleaseMode,
        );
      }
      if (package.hasTests) {
        writer.writeTestStep(
          path: package.path,
          browser: package.hasBrowserTests,
          release: package.hasReleaseMode,
          custom: package.hasCustomTestScript,
        );
      }
    }
    return new TravisGenerator._(
      _presubmitPreamble + writer.presubmit.join('\n'),
      writer.prefix + '\n' + writer.stages.join('\n') + '\n' + writer.postfix,
    );
  }

  // Used when generating tool/presubmit.sh.
  static const _presubmitPreamble = '''
#!/bin/bash

# #################################################################### #
#         AUTO GENERATED. This is used locally to validate.            #
# #################################################################### #

# Fast fail the script on failures.
set -e\n
''';

  /// Emitted `presubmit.sh` as a result of running this generator.
  final String presubmitScript;

  /// Emitted `.travis.yml` as a result of running this generator.
  final String travisConfig;

  const TravisGenerator._(this.presubmitScript, this.travisConfig);
}

/// Encapsulates logic for writing a `.travis.yml` file.
class _OutputWriter {
  /// Content that should be emitted at the top of the output file.
  final String prefix;

  /// Content that should be emitted at the bottom of the output file.
  final String postfix;

  /// Stages that should be emitted in between the [prefix] and [postfix].
  ///
  /// Use `writeXStep` methods to write in a correctly formatted manner.
  final List<String> stages = [];

  /// Presubmit script lines, as an alternative to `.travis.yml`.
  final List<String> presubmit = [];

  _OutputWriter(this.prefix, this.postfix);

  void writeAnalysisStep({
    @required String path,
  }) {
    stages.addAll([
      '    - stage: presubmit',
      '      script: ./tool/travis.sh analyze',
      '      env: PKG="$path"',
      '',
    ]);
    presubmit.addAll([
      'echo "Analyzing $path..."',
      'PKG=$path tool/travis.sh analyze',
    ]);
  }

  void writeBuildStep({
    @required String path,
    @required bool release,
  }) {
    // For packages with a release mode, also build in development mode.
    if (release) {
      writeBuildStep(path: path, release: false);
    }
    stages.addAll([
      '    - stage: building',
      '      script: ./tool/travis.sh build${release ? ':release': ''}',
      '      env: PKG="$path"',
      '      cache:',
      '        directories:',
      '          - $path/.dart_tool',
      '',
    ]);
    presubmit.addAll([
      'echo "Building $path in ${release ? 'release' : 'debug'} mode..."',
      'PKG=$path tool/travis.sh build${release ? ':release': ''}',
    ]);
  }

  void writeTestStep({
    @required String path,
    @required bool browser,
    @required bool release,
    @required bool custom,
  }) {
    if (custom) {
      stages.addAll([
        '    - stage: testing',
        '      script:',
        '        - cd $path',
        '        - ./tool/test.sh',
        '      env: PKG="$path"',
        '      cache:',
        '        directories:',
        '          - $path/.dart_tool',
        '',
      ]);
      presubmit.addAll([
        'echo "Running custom test script for $path..."',
        'pushd $path',
        './tool/test.sh',
        'popd',
        '',
      ]);
      return;
    }
    // For packages with a release mode, also test in development mode.
    if (release) {
      writeTestStep(
        path: path,
        browser: browser,
        release: false,
        custom: false,
      );
    }
    stages.addAll([
      '    - stage: testing',
      '      script: ./tool/travis.sh test${release ? ':release' : ''}',
      '      env: PKG="$path"',
      '      cache:',
      '        directories:',
      '          - $path/.dart_tool',
      '',
    ]);
    presubmit.addAll([
      'echo "Running tests in $path in ${release ? 'release' : 'debug'} mode"',
      'PKG=$path tool/travis.sh test${release ? ':release': ''}',
    ]);
    if (browser) {
      stages.addAll(const [
        r'      addons:',
        r'        chrome: stable',
        r'      before_install:',
        r'        - export DISPLAY=:99.0',
        r'        - sh -e /etc/init.d/xvfb start',
        r'        - "t=0; until (xdpyinfo -display :99 &> /dev/null || test $t -gt 10); do sleep 1; let t=$t+1; done"',
        '',
      ]);
    }
  }
}
