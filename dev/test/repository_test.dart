@TestOn('vm')
import 'package:dev/repository.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  group('Repository', () {
    test('should find all packages', () async {
      await d.dir('angular', [
        d.dir('package_1', [
          d.file('pubspec.yaml', r'''
          name: package_1
        '''),
        ]),
        d.dir('package_2', [
          d.file('pubspec.yaml', r'''
          name: package_2
        '''),
        ]),
      ]).create();

      final rootPath = p.join(d.sandbox, 'angular');
      final repository = Repository.fromPath(rootPath);

      expect(
        repository,
        Repository(
          [
            Package(
              path: 'package_1',
              root: rootPath,
            ),
            Package(
              path: 'package_2',
              root: rootPath,
            )
          ],
          rootPath,
        ),
      );
    });

    test('should exclude packages in output/build folders', () async {
      await d.dir('angular', [
        d.dir('package_1', [
          d.file('pubspec.yaml', r'''
          name: package_1
        '''),
          d.dir('build', [
            d.dir('packages', [
              d.dir('some_dependency', [
                d.file('pubspec.yaml', r'''
                name: some_dependency
              '''),
              ])
            ]),
          ]),
        ]),
      ]).create();

      final rootPath = p.join(d.sandbox, 'angular');
      final repository = Repository.fromPath(rootPath);

      expect(
        repository,
        Repository(
          [
            Package(
              path: 'package_1',
              root: rootPath,
            ),
          ],
          rootPath,
        ),
      );
    });
  });

  group('Package', () {
    test('should parse dependencies and devDependencies', () async {
      await d.dir('angular', [
        d.dir('package_1', [
          d.file('pubspec.yaml', r'''
            name: package_1

            dependencies:
              a: ^1.0.0

            dev_dependencies:
              b: ">=2.0.0 <4.0.0"
          '''),
        ]),
      ]).create();

      final rootPath = p.join(d.sandbox, 'angular');
      final package = Package.loadAndParse(
        rootPath,
        p.join(rootPath, 'package_1'),
      );

      expect(
        package,
        Package(
          path: 'package_1',
          root: rootPath,
          dependencies: {
            'a': VersionConstraint.parse('^1.0.0'),
          },
          devDependencies: {
            'b': VersionConstraint.parse('>=2.0.0 <4.0.0'),
          },
        ),
      );
    });

    test('should not set some flags by default', () async {
      await d.dir('angular', [
        d.dir('package_1', [
          d.file('pubspec.yaml', r'''
            name: package_1
          '''),
        ]),
      ]).create();

      final rootPath = p.join(d.sandbox, 'angular');
      final package = Package.loadAndParse(
        rootPath,
        p.join(rootPath, 'package_1'),
      );

      expect(package.hasCustomTestScript, isFalse);
      expect(package.hasBrowserTests, isFalse);
      expect(package.hasTests, isFalse);
      expect(package.hasReleaseMode, isFalse);
      expect(package.isBuildable, isFalse);
    });

    test('should set hasCustomTestScript if tool/test.sh exists', () async {
      await d.dir('angular', [
        d.dir('package_1', [
          d.file('pubspec.yaml', r'''
            name: package_1
          '''),
          d.dir('tool', [
            d.file('test.sh', ''),
          ]),
        ]),
      ]).create();

      final rootPath = p.join(d.sandbox, 'angular');
      final package = Package.loadAndParse(
        rootPath,
        p.join(rootPath, 'package_1'),
      );

      expect(package.hasCustomTestScript, isTrue);
    });

    test('should set hasTests if test/ exists', () async {
      await d.dir('angular', [
        d.dir('package_1', [
          d.file('pubspec.yaml', r'''
            name: package_1
          '''),
          d.dir('test', [
            d.file('a_test.dart', ''),
          ]),
        ]),
      ]).create();

      final rootPath = p.join(d.sandbox, 'angular');
      final package = Package.loadAndParse(
        rootPath,
        p.join(rootPath, 'package_1'),
      );

      expect(package.hasTests, isTrue);
      expect(package.hasBrowserTests, isFalse);
    });

    test('should set hasTests if build.release.yaml exists', () async {
      await d.dir('angular', [
        d.dir('package_1', [
          d.file('pubspec.yaml', r'''
            name: package_1
          '''),
          d.file('build.release.yaml', ''),
        ]),
      ]).create();

      final rootPath = p.join(d.sandbox, 'angular');
      final package = Package.loadAndParse(
        rootPath,
        p.join(rootPath, 'package_1'),
      );

      expect(package.hasReleaseMode, isTrue);
    }, skip: 'Not currently supported');

    test('should set isBuildable if build_runner is a dependency', () async {
      await d.dir('angular', [
        d.dir('package_1', [
          d.file('pubspec.yaml', r'''
            name: package_1
            dev_dependencies:
              build_runner:
          '''),
        ]),
      ]).create();

      final rootPath = p.join(d.sandbox, 'angular');
      final package = Package.loadAndParse(
        rootPath,
        p.join(rootPath, 'package_1'),
      );

      expect(package.isBuildable, isTrue);
    });

    test('should set hasBrowserTests if build_web_compilers', () async {
      await d.dir('angular', [
        d.dir('package_1', [
          d.file('pubspec.yaml', r'''
            name: package_1
            dev_dependencies:
              build_runner:
              build_web_compilers:
          '''),
        ]),
      ]).create();

      final rootPath = p.join(d.sandbox, 'angular');
      final package = Package.loadAndParse(
        rootPath,
        p.join(rootPath, 'package_1'),
      );

      expect(package.isBuildable, isTrue);
      expect(package.hasBrowserTests, isTrue);
    });
  });
}
