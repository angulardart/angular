@TestOn('vm')
import 'package:dev/travis.dart';
import 'package:test/test.dart';

void main() {
  group('OutputWriter', () {
    OutputWriter writer;

    setUp(() => writer = OutputWriter('', ''));

    test('writeAnalysisStep should analyze a package', () {
      writer.writeAnalysisStep(path: 'package_1');
      expect(
        writer.toPresubmitScript(),
        contains('PKG=package_1 tool/travis.sh analyze'),
      );
      expect(
        writer.toTravisDotYaml(),
        allOf(
          contains('script: ./tool/travis.sh analyze'),
          contains('env: PKG="package_1"'),
        ),
      );
    });

    test('writeBuildStep should build a package', () {
      writer.writeBuildStep(
        path: 'package_1',
        release: false,
      );
      expect(
        writer.toPresubmitScript(),
        contains('PKG=package_1 tool/travis.sh build'),
      );
      expect(
        writer.toTravisDotYaml(),
        allOf(
          contains('script: ./tool/travis.sh build'),
          contains('env: PKG="package_1"'),
        ),
      );
    });

    test('writeBuildStep should build a package in release mode', () {
      writer.writeBuildStep(
        path: 'package_1',
        release: true,
      );
      expect(
        writer.toPresubmitScript(),
        allOf(
          contains('PKG=package_1 tool/travis.sh build'),
          contains('PKG=package_1 tool/travis.sh build:release'),
        ),
      );
      expect(
        writer.toTravisDotYaml(),
        allOf(
          contains('script: ./tool/travis.sh build'),
          contains('script: ./tool/travis.sh build:release'),
          contains('env: PKG="package_1"'),
        ),
      );
    });

    test('writeTestStep should test a package', () {
      writer.writeTestStep(
        path: 'package_1',
        browser: false,
        buildable: true,
        release: false,
        custom: false,
      );
      expect(
        writer.toPresubmitScript(),
        allOf(
          contains('PKG=package_1 tool/travis.sh test'),
        ),
      );
      expect(
        writer.toTravisDotYaml(),
        allOf(
          contains('script: ./tool/travis.sh test'),
          contains('env: PKG="package_1"'),
        ),
      );
    });

    test('writeTestStep should test a web package', () {
      writer.writeTestStep(
        path: 'package_1',
        browser: true,
        buildable: true,
        release: false,
        custom: false,
      );
      expect(
        writer.toPresubmitScript(),
        allOf(
          contains('PKG=package_1 tool/travis.sh test'),
        ),
      );
      expect(
        writer.toTravisDotYaml(),
        allOf(
          contains('script: ./tool/travis.sh test'),
          contains('env: PKG="package_1"'),
          contains('chrome: stable'),
        ),
      );
    });

    test('writeTestStep should not use build_runner if not buildable', () {
      writer.writeTestStep(
        path: 'package_1',
        browser: false,
        buildable: false,
        release: false,
        custom: false,
      );
      expect(
        writer.toPresubmitScript(),
        allOf(
          contains('PKG=package_1 tool/travis.sh test:nobuild'),
        ),
      );
      expect(
        writer.toTravisDotYaml(),
        allOf(
          contains('script: ./tool/travis.sh test:nobuild'),
          contains('env: PKG="package_1"'),
        ),
      );
    });
  });
}
