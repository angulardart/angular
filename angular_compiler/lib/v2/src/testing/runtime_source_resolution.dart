/// At runtime (in command-line VM tests) resolves and instruments Dart source.
///
/// For functional tests that instrument the compiler in ad-hoc fashion; for
/// example to expect that given source code produces an error or other
/// specific output.
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_test/build_test.dart';
import 'package:package_config/package_config.dart';

const _angularPkgPath = 'package:';
const _angularLibPath = '${_angularPkgPath}angular/angular.dart';
const _environmentVar = 'ANGULAR_PACKAGE_CONFIG_PATH';
const _defaultLibrary = 'test_lib';
final _defaultAssetId = AssetId(_defaultLibrary, 'lib/$_defaultLibrary.dart');
final _packageConfigPath = Platform.environment[_environmentVar];
final _cachedPackageConfig = _loadPackageConfig();

Future<PackageConfig> _loadPackageConfig() {
  var config = Isolate.packageConfig.then((uri) => loadPackageConfigUri(uri!));
  return config;
}

String _assetToPath(AssetId asset) => '${asset.package}|${asset.path}';

/// Resolves [dartSource] as a library `package:test_lib/test_lib.dart`.
///
/// Example:
/// ```
/// lib = await resolveLibrary(
///   '''
///     @Component(
///       selector: 'example',
///       template: 'Hello World',
///     )
///     class ExampleComponent {}
///   ''',
/// );
/// ```
///
/// * [additionalFiles]: May provide additional files available to the program:
///   ```
///   resolveLibrary(
///     '''
///       @Component(
///         selector: 'example',
///         templateUrl: 'example.html',
///       )
///       class ExampleComponent {}
///     ''',
///     additionalFiles: {
///       AssetId(
///         'test_lib',
///         'lib/example.html',
///       ): '''
///         <div>Hello World</div>
///       ''',
///     },
///   )
///   ```
///
/// * [includeAngularDeps]: Set `false` to not include `import 'angular.dart'`.
///   This may be used to simulate scenarios where the user has forgotten to add
///   an import to Angular, or where you would want the import specified as an
///   alternative entry-point.
Future<LibraryElement> resolve(
  String dartSource, {
  Map<AssetId, String> additionalFiles = const {},
  bool includeAngularDeps = true,
}) async {
  // Add library and import directives to the top.
  dartSource = [
    if (includeAngularDeps) "import '$_angularLibPath';",
    '',
    dartSource,
  ].join('\n');
  final sources = {
    // Map<AssetId, String> -> Map<String, String>
    for (final entry in additionalFiles.entries)
      _assetToPath(entry.key): entry.value,

    // Adds an additional file (dartSource).
    _assetToPath(_defaultAssetId): dartSource,
  };
  final config = await _cachedPackageConfig;
  final result = await withEnabledExperiments(
    () => resolveSources(
      sources,
      (resolver) => resolver.libraryFor(_defaultAssetId),
      packageConfig: config,
    ),
    ['non-nullable'],
  );
  return result;
}
