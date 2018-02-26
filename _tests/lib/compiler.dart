import 'dart:async';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:angular/builder.dart';
import 'package:angular_compiler/cli.dart';
import 'package:logging/logging.dart';
import 'package:build/build.dart';
import 'package:build_barback/build_barback.dart';
import 'package:build_test/build_test.dart' hide testBuilder;
import 'package:test/test.dart';

/// A 'test' build process (similar to the normal one).
final Builder _testAngularBuilder = new MultiplexingBuilder([
  templateCompiler(
    new BuilderOptions({}),
    defaultFlags: const CompilerFlags(
      genDebugInfo: false,
      ignoreNgPlaceholderForGoldens: true,
      useAstPkg: true,
    ),
  ),
  stylesheetCompiler(new BuilderOptions({})),
]);

// Here to be configurable.
//
// We could use a better PackageAssetReader if necessary in some platforms.
final Future<PackageAssetReader> _packageAssets = (() async {
  final runfiles = Platform.environment['RUNFILES'];
  if (runfiles == null) {
    return PackageAssetReader.currentIsolate();
  }
  final root = const String.fromEnvironment('PKG_ANGULAR_ROOT');
  final path = '$runfiles/$root';
  if (!FileSystemEntity.isFileSync('$path/lib/angular.dart')) {
    throw new StateError('Could not find $path/lib/angular.dart');
  }
  return new PackageAssetReader.forPackages({
    ngPackage: '$runfiles/$root',
  });
})();

// The locations of the import for AngularDart source code.
//
// **NOTE**: Be very careful changing this, there are hard-coded transformation
// rules as part of open sourcing process to make sure this works both
// externally and internally.
const ngPackage = 'angular';
const ngImport = 'package:$ngPackage/angular.dart';
final _ngFiles = new Glob('lib/**.dart');

/// Modeled after `package:build_test/build_test.dart#testBuilder`.
Future<Null> _testBuilder(
  Builder builder,
  Map<String, String> sourceAssets, {
  void Function(LogRecord) onLog,
  String rootPackage,
}) async {
  // Setup the readers/writers for assets.
  final sources = new InMemoryAssetReader(rootPackage: rootPackage);
  final packages = await _packageAssets;
  final reader = new MultiAssetReader([
    sources,
    packages,
  ]);

  // Sanity check.
  if (!await reader.canRead(new AssetId(ngPackage, 'lib/angular.dart'))) {
    throw new StateError('Unable to read "$ngImport".');
  }

  // Load user sources.
  final writer = new InMemoryAssetWriter();
  final inputIds = <AssetId>[];
  sourceAssets.forEach((serializedId, contents) {
    final id = makeAssetId(serializedId);
    sources.cacheStringAsset(id, contents);
    inputIds.add(id);
  });

  if (inputIds.isEmpty) {
    throw new ArgumentError.value(sourceAssets, 'No inputs', 'sourceAssets');
  }

  // Load framework sources.
  // TODO: Can we cache and re-use this once per test suite?
  final framework = packages.findAssets(_ngFiles, package: ngPackage);
  await for (final file in framework) {
    sources.cacheStringAsset(file, await packages.readAsString(file));
  }

  final logger = new Logger('_testBuilder');
  final logSub = logger.onRecord.listen(onLog);
  await runBuildZoned(() {
    return runBuilder(
      builder,
      inputIds,
      reader,
      writer,
      const BarbackResolvers(),
      logger: logger,
    );
  });
  await logSub.cancel();
}

/// Returns a future that completes, asserting potential end states.
///
/// File [input] is treated as the primary input source. Additional
/// sources can be added via the [include] and [inputSource] properties:
/// ```
/// compilesExpect('...',
///   inputSource: 'pkg|lib/input.dart',
///   include: {
///     'pkg|lib/input.html': '...',
///     'pkg|lib/other.dart': '...',
///   }
/// )
/// ```
///
/// Note that `package:angular/**.dart` is always included.
Future<Null> compilesExpecting(
  String input, {
  String inputSource,
  Map<String, String> include,
  Object /*Matcher|Iterable<Matcher>*/ errors,
  Object /*Matcher|Iterable<Matcher>*/ warnings,
  Object /*Matcher|Iterable<Matcher>*/ notices,
  Object /*Matcher|Map<String, Matcher>*/ outputs,
}) async {
  // Default values.
  //
  // We do not use constructor defaults, because then we'd have to specify them
  // twice, once here, and again in 'compilesNormally' (+ additional times
  // wherever we want variants).
  inputSource ??= 'pkg|lib/input.dart';
  include ??= const {};

  // Complete list of input sources.
  final sources = <String, dynamic>{
    inputSource: input,
  }..addAll(include);

  // Run the builder.
  final records = <Level, List<String>>{};
  await _testBuilder(_testAngularBuilder, sources, onLog: (record) {
    var message = record.message;
    if (record.error != null) {
      message += '\nERROR: ${record.error}';
    }
    records.putIfAbsent(record.level, () => []).add(message);
  });

  if (errors != null) {
    final logs = records[Level.SEVERE] ?? [];
    expect(
      logs,
      errors,
      reason: 'Errors: \n${logs.join('\n')}',
    );
  }
  if (warnings != null) {
    final logs = records[Level.WARNING] ?? [];
    expect(
      logs,
      warnings,
      reason: 'Warnings: \n${logs.join('\n')}',
    );
  }
  if (notices != null) {
    final logs = records[Level.INFO] ?? [];
    expect(
      logs,
      notices,
      reason: 'Notices: \n${logs.join('\n')}',
    );
  }
  if (outputs != null) {
    // TODO: Add an output verification or consider a golden file mechanism.
    throw new UnimplementedError();
  }
}

/// Returns a future that completes, asserting no errors or warnings occur.
///
/// An alias [compilesExpecting] with `errors` and `warnings` asserting empty.
Future<Null> compilesNormally(
  String input, {
  String inputSource,
  Map<String, String> include,
}) =>
    compilesExpecting(
      input,
      inputSource: inputSource,
      include: include,
      errors: isEmpty,
      warnings: isEmpty,
    );
