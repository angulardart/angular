import 'package:meta/meta.dart';

import 'repository.dart';

/// Generates `./.travis.yml` and `tool/presubmit.sh` for the repository.
class TravisGenerator {
  /// Analyzes and returns output files as part of scanning [repository].
  static TravisGenerator generate(Repository repository) {
    final writer = OutputWriter(
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
          buildable: package.isBuildable,
          release: package.hasReleaseMode,
          custom: package.hasCustomTestScript,
        );
      }
    }
    return TravisGenerator._(
      writer.toPresubmitScript(),
      writer.toTravisDotYaml(),
    );
  }

  /// Emitted `presubmit.sh` as a result of running this generator.
  final String presubmitScript;

  /// Emitted `.travis.yml` as a result of running this generator.
  final String travisConfig;

  const TravisGenerator._(this.presubmitScript, this.travisConfig);
}

/// Encapsulates logic for writing a `.travis.yml` file.
class OutputWriter {
  /// Content that should be emitted at the top of the output file.
  final String _prefix;

  /// Content that should be emitted at the bottom of the output file.
  final String _postfix;

  /// Stages that should be emitted in between the [_prefix] and [_postfix].
  ///
  /// Use `writeXStep` methods to write in a correctly formatted manner.
  final List<String> _stages = [];

  /// Presubmit script lines, as an alternative to `.travis.yml`.
  final List<String> _presubmit = [];

  @visibleForTesting
  OutputWriter(this._prefix, this._postfix);

  // Used when generating tool/presubmit.sh.
  static const _presubmitPreamble = '''
#!/bin/bash

# #################################################################### #
#         AUTO GENERATED. This is used locally to validate.            #
# #################################################################### #

# Fast fail the script on failures.
set -e

# Remove previous output directories.
rm -rf **/build/\n
''';

  /// The Pub cache directory path.
  ///
  /// Note that any Travis build stage which defines its own cache will ignore
  /// the global cache. So despite the Pub cache already being cached globally,
  /// it must be respecified by any build stage that defines its own cache.
  static const _pubCacheDirectory = r'$HOME/.pub-cache';

  String toPresubmitScript() {
    return _presubmitPreamble + _presubmit.join('\n');
  }

  String toTravisDotYaml() {
    return _prefix + '\n' + _stages.join('\n') + '\n' + _postfix;
  }

  void writeAnalysisStep({
    @required String path,
  }) {
    _stages.addAll([
      '    - stage: presubmit',
      '      script: ./tool/travis.sh analyze',
      '      env: PKG="$path"',
      '',
    ]);
    _presubmit.addAll([
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
    _stages.addAll([
      '    - stage: building',
      '      script: ./tool/travis.sh build${release ? ':release' : ''}',
      '      env: PKG="$path"',
      '      cache:',
      '        directories:',
      '          - $_pubCacheDirectory',
      '          - $path/.dart_tool',
      '',
    ]);
    _presubmit.addAll([
      'echo "Building $path in ${release ? 'release' : 'debug'} mode..."',
      'PKG=$path tool/travis.sh build${release ? ':release' : ''}',
    ]);
  }

  void writeTestStep({
    @required String path,
    @required bool browser,
    @required bool buildable,
    @required bool release,
    @required bool custom,
  }) {
    // TODO: Support testing in release mode.
    release = false;

    if (!buildable) {
      _stages.addAll([
        '    - stage: testing',
        '      script: ./tool/travis.sh test:nobuild',
        '      env: PKG="$path"',
        '',
      ]);
      _presubmit.addAll([
        'echo "Running tests in $path in (nobuild)"',
        'PKG=$path tool/travis.sh test:nobuild',
      ]);
      return;
    }

    if (custom) {
      _stages.addAll([
        '    - stage: testing',
        '      script:',
        '        - cd $path',
        '        - ./tool/test.sh',
        '      env: PKG="$path"',
        '      cache:',
        '        directories:',
        '          - $_pubCacheDirectory',
        '          - $path/.dart_tool',
        '',
      ]);
      _presubmit.addAll([
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
        buildable: true,
        browser: browser,
        release: false,
        custom: false,
      );
    }
    _stages.addAll([
      '    - stage: testing',
      '      script: ./tool/travis.sh test${release ? ':release' : ''}',
      '      env: PKG="$path"',
      '      cache:',
      '        directories:',
      '          - $_pubCacheDirectory',
      '          - $path/.dart_tool',
      '',
    ]);
    _presubmit.addAll([
      'echo "Running tests in $path in ${release ? 'release' : 'debug'} mode"',
      'PKG=$path tool/travis.sh test${release ? ':release' : ''}',
    ]);
    if (browser) {
      _stages.addAll(const [
        r'      addons:',
        r'        chrome: stable',
        '',
      ]);
    }
  }
}
