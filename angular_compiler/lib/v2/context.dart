import 'dart:async';

import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular/src/utilities.dart';
import 'package:angular_compiler/v1/src/angular_compiler/cli/messages.dart';
import 'package:angular_compiler/v2/asset.dart';

import 'src/context/build_error.dart';

export 'src/context/build_error.dart';

/// Private key for reading/writing [CompileContext] to [Zone] values.
///
/// This is private so that it's not tempting to try and read or write a
/// [CompileContext] instance outside of this class.
final _compileContextKey = Object();

/// Executes [run] with [CompileContext.current] set to [instance].
///
/// Any uncaught error thrown in [run] are logged as fatal messages. An error
/// that does not implement [BuildError] (or [UnresolvedAnnotationException]) is
/// reported as an "unhandled exception" with a stack trace encouraging the user
/// to file a bug (these invariants should not happen for users).
///
/// Before completing, [CompileContext.throwRecoverableErrors] is checked, and
/// any calls to [CompileContext.reportAndRecover] are reported as fatal errors
/// (these are different than uncaught errors in that they allow compilation to
/// complete, see [CompileContext.reportAndRecover]).
///
/// **NOTE**: Unless you are specifically testing [runWithContext], tests should
/// use [CompileContext.overrideForTesting] instead to set the current context.
Future<T> runWithContext<T>(
  CompileContext instance,
  Future<T> Function() run,
) {
  ArgumentError.checkNotNull(instance, 'instance');
  // A call to runZoned with "onError" becomes a special kind of zone called an
  // "Error Zone", which no longer guarantees completion (that is, the function
  // executing or catching an unhandled error are considered exclusive).
  //
  // This completer is (manually) completed when the function finishes or fails.
  final buildCompletedOrFailed = Completer<T>.sync();
  runZonedGuarded(
    run,
    (e, s) {
      // Convert pkg/source_gen#UnresolvedAnnotationException into a BuildError.
      if (e is UnresolvedAnnotationException) {
        final eCasted = e;
        final convert = BuildError.forSourceSpan(
          spanForElement(eCasted.annotatedElement),
          'Could not resolve "${eCasted.annotationSource!.text}":\n'
          '${messages.analysisFailureReasons}',
        );
        e = convert;
      }
      if (e is BuildError) {
        log.severe(
          'An error occurred compiling ${instance.path}:\n$e',
          // TODO(b/170758093): Add conditional stack traces, perhaps behind a
          // --define flag for developers of the compiler to get information on
          // the exact location of a failure.
        );
      } else {
        log.severe(
          'Unhandled exception in the AngularDart compiler!\n\n'
          'Please report a bug: ${messages.urlFileBugs}',
          e.toString(),
          s,
        );
      }
      if (!buildCompletedOrFailed.isCompleted) {
        buildCompletedOrFailed.complete();
      }
    },
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, line) => log.info(line),
    ),
    zoneValues: {
      _compileContextKey: instance,
    },
  )?.then((result) {
    if (!buildCompletedOrFailed.isCompleted) {
      buildCompletedOrFailed.complete(result);
    }
  });
  instance.throwRecoverableErrors();
  return buildCompletedOrFailed.future;
}

/// Execution-local static state for the current compilation.
///
/// Such state includes:
/// - Various flags or modes that are conditionally enabled.
/// - Ability to report diagnostics related to the current compilation.
///
/// When the compiler is running as a worker (i.e. long-running), this context
/// refers to the _current_ compilation occuring (where multiple may occur over
/// the lifecycle of the compiler).
///
/// When the compiler or components of the compiler are running in a _test_ it
/// is required to statically initialize one by using [overrideForTesting].
@sealed
abstract class CompileContext {
  /// Overrides [CompileContext.current] to return [context].
  ///
  /// This can be done once during `main()` or `setUpAll(() => ...)`:
  /// ```
  /// void main() {
  ///   CompileContext.overrideForTesting();
  /// }
  /// ```
  ///
  /// Or piece-meal per-test for custom behaviors:
  /// ```
  /// void main() {
  ///   test('...', () {
  ///     CompileContext.overrideForTesting(flagSet1);
  ///   });
  ///
  ///   test('...', () {
  ///     CompileContext.overrideForTesting(flagSet2);
  ///   });
  /// }
  /// ```
  @visibleForTesting
  static void overrideForTesting([
    CompileContext context = const _TestCompileContext(),
  ]) {
    ArgumentError.checkNotNull(context, 'context');
    _overrideForTesting = context;
  }

  /// Unsets the [overrideForTesting] instance, defaulting to normal behavior.
  ///
  /// A typical use-case for this might be `tearDown`:
  /// ```
  /// tearDown(CompileContext.removeTestingOverride);
  /// ```
  @visibleForTesting
  static void removeTestingOverride() {
    _overrideForTesting = null;
  }

  static CompileContext? _overrideForTesting;

  /// Currently executing context based on `Zone.current[CompileContext]`.
  ///
  /// Using zones to determine the context is the default behavior unless
  /// [overrideForTesting] is used to set the global context.
  ///
  /// If no context has been assigned, either through [overrideForTesting] or
  /// from `Zone.current[CompileContext]` being available, then an error is
  /// thrown.
  static CompileContext get current {
    final context = _overrideForTesting ?? Zone.current[_compileContextKey];
    if (context == null) {
      _failNoCompileContextConfigured();
    }
    return context as CompileContext;
  }

  @alwaysThrows
  static void _failNoCompileContextConfigured() {
    var errorMessage = 'No CompileContext configured.';
    if (isDevMode) {
      errorMessage = ''
          '$errorMessage\n'
          'During tests that invoke parts of the compiler it is required to '
          'use CompileContext.overrideForTesting to initialize a default '
          'context. This can be done once in `main()`, in `setUpAll()`, or '
          'piece-meal per test if special behavior is desired.';
    } else {
      errorMessage = ''
          '$errorMessage\n'
          'This should not happen, and might be the result of using part of '
          'the compiler outside of the normal build process.';
    }
    throw StateError(errorMessage);
  }

  /// Creates a [CompileContext] for the provided [libraryPath].
  factory CompileContext(
    AssetId libraryPath, {
    required Map<String, Set<String>> policyExceptions,
    required Map<String, Set<String>> policyExceptionsInPackages,
    required bool enableDevTools,
    required bool isNullSafe,
  }) {
    return _LibraryCompileContext(
      enableDevTools: enableDevTools,
      isNullSafe: isNullSafe,
      path: libraryPath.toRelativeUrl(),
      policyExceptionsPerFiles: policyExceptions,
      policyExceptionsPerPackages: policyExceptionsInPackages,
    );
  }

  /// Creates a standalone [CompileContext] with pre-configured flags.
  ///
  /// This is intended for use with [overrideForTesting] only:
  /// ```
  /// // Generate null-safe code in these test cases.
  /// CompileContext.overrideForTesting(CompileContext.forTesting(
  ///   emitNullSafeCode: true,
  /// ))
  /// ```
  ///
  /// **NOTE**: [reportAndRecover] simply uses `throw` in this configuration.
  @visibleForTesting
  const factory CompileContext.forTesting({
    bool emitNullSafeCode,
    bool isDevToolsEnabled,
    bool validateMissingDirectives,
  }) = _TestCompileContext;

  /// Path of the file being compiled.
  String get path;

  // TODO(b/170758395): Move `BuildError` to v2 and type these `<BuildError>`.

  /// Reports an [error] or exception that does not need to suspend compilation.
  ///
  /// Unlike `throw <Error>`, it is expected that the compiler component calling
  /// this method is able to gracefully proceed with compilation (by subsituting
  /// a default value, by skipping part of the tree, etc), which allows emitting
  /// multiple errors instead of just the first one.
  ///
  /// An example of where this could be used is in HTML parsing, where you may
  /// choose to want to show _all_ invalid HTML instead of one error at a time.
  ///
  /// As a result, [reportAndRecover] is _not_ required to immediately `throw`
  /// (though it can choose to do so, especially in tests were it is unlikely
  /// you want compilation to continue on an error). The collected errors are
  /// stored and can be lazily reported using [throwRecoverableErrors].
  void reportAndRecover(BuildError error);

  /// Throws any errors collected via [reportAndRecover].
  ///
  /// The buffer of previous errors is cleared as a result.
  void throwRecoverableErrors();

  /// Whether to emit code that supports https://dart.dev/null-safety.
  ///
  /// This is based on a combination of:
  /// 1. The library and/or package being opted-in to null safety.
  /// 2. The library being added to the appropriate allow-list.
  bool get emitNullSafeCode;

  /// Whether to emit code that supports developer tooling.
  ///
  /// There are two ways to enable this flag:
  /// 1. Passing `--define=ENABLE_DEVTOOLS=true`.
  /// 2. Adding a specific file to the appropriate allow-list.
  ///
  /// See [_CompileContext.isDevToolsEnabled] for implementation details.
  bool get isDevToolsEnabled;

  /// Whether to issue a compile-time error when directives appear missing.
  bool get validateMissingDirectives;
}

class _LibraryCompileContext implements CompileContext {
  /// See `CompilerFlags.policyExceptions`.
  final Map<String, Set<String>> policyExceptionsPerFiles;

  /// See `CompilerFlags.policyExceptionInPackages`.
  final Map<String, Set<String>> policyExceptionsPerPackages;

  @override
  final String path;

  /// Whether `--define=ENABLE_DEVTOOLS=true` was passed during compilation.
  final bool enableDevTools;

  /// Whether the library being compiled is opted-in to null-safety.
  final bool isNullSafe;

  _LibraryCompileContext({
    required this.path,
    required this.policyExceptionsPerFiles,
    required this.policyExceptionsPerPackages,
    required this.enableDevTools,
    required this.isNullSafe,
  });

  final _recoverableErrors = <BuildError>[];

  @override
  void reportAndRecover(BuildError error) {
    try {
      throw error;
    } on BuildError catch (errorWithStackTrace) {
      // This is important, because `<Error>.stackTrace` is `null` unless it is
      // actually thrown. The performance impact here is neglibile because the
      // build is going to terminate unsucessfully anyway.
      _recoverableErrors.add(errorWithStackTrace);
    }
  }

  @override
  void throwRecoverableErrors() {
    final result = _recoverableErrors.toList();
    _recoverableErrors.clear();
    if (result.isNotEmpty) {
      throw BuildError.fromMultiple(
        result,
        'One or more fatal errors occured during compilation',
      );
    }
  }

  /// Returns whether a policy exception of [type] is present for [path].
  ///
  /// This method is intentionally [protected] in order to encourage creating
  /// new named methods for every single type of policy exception:
  /// ```
  /// bool get allowListLiterals => hasPolicyException('ALLOW_LIST_LITERALS');
  /// ```
  @protected
  bool hasPolicyException(String type) {
    final files = policyExceptionsPerFiles[type] ?? const {};
    try {
      return files.contains(path);
    } on Object catch (_) {
      // Not ideal, but we don't want to crash because of an incomplete URL.
      //
      // TODO(b/154262933): Refactor once we have a consistent pipeline.
      return false;
    }
  }

  /// Returns whether a policy exception of [type] is present for [path].
  ///
  /// Unlike [hasPolicyException], a prefix match (i.e. the beginning of a path)
  /// will return `true`, which lets us avoid having to continuously add files
  /// to an allow-list in a given directory.
  @protected
  bool hasPolicyExceptionInPackage(String type) {
    final packages = policyExceptionsPerPackages[type] ?? const {};
    return packages.any(path.startsWith);
  }

  @override
  bool get emitNullSafeCode => isNullSafe;

  @override
  bool get isDevToolsEnabled {
    return enableDevTools || hasPolicyException('FORCE_DEVTOOLS_ENABLED');
  }

  @override
  bool get validateMissingDirectives {
    return !hasPolicyExceptionInPackage('EXCLUDED_VALIDATE_MISSING_DIRECTIVES');
  }
}

class _TestCompileContext implements CompileContext {
  @override
  final bool emitNullSafeCode;

  @override
  final bool isDevToolsEnabled;

  @override
  final bool validateMissingDirectives;

  const _TestCompileContext({
    this.emitNullSafeCode = true,
    this.isDevToolsEnabled = false,
    this.validateMissingDirectives = true,
  });

  @override
  String get path => 'input.dart';

  @override
  void reportAndRecover(BuildError error) => throw error;

  @override
  void throwRecoverableErrors() {}
}
