import 'dart:async';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:angular/src/build.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:angular_compiler/cli.dart';
import 'package:logging/logging.dart';
import 'package:build/build.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_test/build_test.dart' hide testBuilder;
import 'package:test/test.dart';

/// A 'test' build process (similar to the normal one).
final Builder _testAngularBuilder = MultiplexingBuilder([
  templateCompiler(
    BuilderOptions({}),
    defaultFlags: const CompilerFlags(
      ignoreNgPlaceholderForGoldens: true,
    ),
  ),
  stylesheetCompiler(BuilderOptions({})),
]);

// Here to be configurable.
//
// We could use a better PackageAssetReader if necessary in some platforms.
final Future<PackageAssetReader> _packageAssets = (() async {
  final runfiles = Platform.environment['RUNFILES'];
  if (runfiles == null) {
    return PackageAssetReader.currentIsolate();
  }
  final root = Platform.environment['PKG_ANGULAR_ROOT'];
  final path = '$runfiles/$root';
  if (!FileSystemEntity.isFileSync('$path/lib/angular.dart')) {
    throw StateError('Could not find $path/lib/angular.dart');
  }
  return PackageAssetReader.forPackages({
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
final _ngFiles = Glob('lib/**.dart');

/// Modeled after `package:build_test/build_test.dart#testBuilder`.
Future<Null> _testBuilder(
  Builder builder,
  Map<String, String> sourceAssets, {
  void Function(LogRecord) onLog,
  String rootPackage,
}) async {
  // Setup the readers/writers for assets.
  final sources = InMemoryAssetReader(rootPackage: rootPackage);
  final packages = await _packageAssets;
  final reader = MultiAssetReader([
    sources,
    packages,
  ]);

  // Sanity check.
  if (!await reader.canRead(AssetId(ngPackage, 'lib/angular.dart'))) {
    throw StateError('Unable to read "$ngImport".');
  }

  // Load user sources.
  final writer = InMemoryAssetWriter();
  final inputIds = <AssetId>[];
  sourceAssets.forEach((serializedId, contents) {
    final id = makeAssetId(serializedId);
    sources.cacheStringAsset(id, contents);
    inputIds.add(id);
  });

  if (inputIds.isEmpty) {
    throw ArgumentError.value(sourceAssets, 'No inputs', 'sourceAssets');
  }

  // Load framework sources.
  // TODO: Can we cache and re-use this once per test suite?
  final framework = packages.findAssets(_ngFiles, package: ngPackage);
  await for (final file in framework) {
    sources.cacheStringAsset(file, await packages.readAsString(file));
  }

  final logger = Logger('_testBuilder');
  final logSub = logger.onRecord.listen(onLog);
  await runBuildZoned(
    () {
      return runBuilder(
        builder,
        inputIds,
        reader,
        writer,
        AnalyzerResolvers(),
        logger: logger,
      );
    },
    zoneValues: {
      CompileContext: CompileContext(),
    },
  );
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
  final sources = <String, String>{
    inputSource: input,
  }..addAll(include);

  // Run the builder.
  final records = <Level, List<LogRecord>>{};
  await _testBuilder(_testAngularBuilder, sources, onLog: (record) {
    records.putIfAbsent(record.level, () => []).add(record);
  });

  expectLogRecords(records[Level.SEVERE], errors, 'Errors');
  expectLogRecords(records[Level.WARNING], warnings, 'Warnings');
  expectLogRecords(records[Level.INFO], notices, 'Notices');

  if (outputs != null) {
    // TODO: Add an output verification or consider a golden file mechanism.
    throw UnimplementedError();
  }
}

void expectLogRecords(List<LogRecord> logs, matcher, String reasonPrefix) {
  if (matcher == null) {
    return;
  }
  logs ??= [];
  expect(logs.map(formattedLogMessage), matcher,
      reason:
          '$reasonPrefix: \n${logs.map((l) => '${formattedLogMessage(l)} at:\n ${l.stackTrace}')}');
}

String formattedLogMessage(LogRecord record) {
  var message = record.message;
  if (record.error != null) {
    message += '\nERROR: ${record.error}';
  }
  return message;
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

/// Match for a source location, but don't require tests to manage package
/// names.
Matcher containsSourceLocation(int line, int column) =>
    contains("line $line, column $column of ");
