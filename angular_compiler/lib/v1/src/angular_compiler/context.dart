import 'dart:async';

import 'package:build/build.dart';
import 'package:meta/meta.dart';

/// Execution-local static state for the current compilation.
///
/// When the compiler is running as a worker (i.e. long-running), this context
/// refers to the _current_ compilation occurring (where multiple may occur over
/// the lifecycle of the compiler).
abstract class CompileContext {
  @visibleForTesting
  static const ignoreAllPolicies = _IgnoreAllPoliciesCompileContext();

  /// Currently executing context based on [Zone.current].
  static CompileContext get current {
    final context = _overrideForTesting ?? Zone.current[CompileContext];
    if (context == null) {
      throw StateError('No CompileContext configured');
    }
    return context as CompileContext;
  }

  static CompileContext _overrideForTesting;

  /// Set the [CompileContext] to be used for test cases going forward.
  ///
  /// If not specified, defaults to [ignoreAllPolicies].
  @visibleForTesting
  static void overrideForTesting([CompileContext context = ignoreAllPolicies]) {
    _overrideForTesting = context;
  }

  const factory CompileContext({
    @required Map<String, Set<String>> policyExceptions,
  }) = _CompileContext;

  /// Returns whether [path] should allow list-literals (`[...]`) in templates.
  bool allowListLiterals(String path);
}

class _CompileContext implements CompileContext {
  /// See [CompilerFlags.policyExceptions].
  final Map<String, Set<String>> _policyExceptions;

  const _CompileContext({
    @required Map<String, Set<String>> policyExceptions,
  })  : assert(policyExceptions != null),
        _policyExceptions = policyExceptions;

  @override
  bool allowListLiterals(String path) {
    return _hasPolicyException('ALLOW_LIST_LITERALS', path);
  }

  /// Returns whether a policy exception of [type] is present for [path].
  ///
  /// For example:
  /// ```
  ///   _hasPolicyException('ALLOW_LIST_LITERALS', 'path/to/lib/file.dart')
  /// ```
  ///
  /// This method is intentionally private in order to encourage creating new
  /// named methods for every single type of policy exception:
  /// ```
  ///   bool allowListLiteral(String path) {
  ///     return _hasPolicyException('ALLOW_LIST_LITERALS', path);
  ///   }
  /// ```
  bool _hasPolicyException(String type, String path) {
    final files = _policyExceptions[type] ?? const {};
    try {
      return files.contains(_normalizePathToDisk(path));
    } on Object catch (_) {
      // Not ideal, but we don't want to crash because of an incomplete URL.
      //
      // TODO(b/154262933): Refactor once we have a consistent pipeline.
      return false;
    }
  }

  /// Converts a build tool path to an on-disk path (e.g. in a Bazel workspace).
  ///
  /// TODO(b/154275151): Consider just taking an AssetId instead.
  static String _normalizePathToDisk(String path) {
    // Parse either "package:x.y/z.dart" or "asset:x.y/test/z.dart".
    final asset = AssetId.resolve(path);
    // Convert ["x.y", "lib/z.dart"] -> ["x/y", "lib/z.dart"].
    final package = asset.package.replaceAll('.', '/');
    // Combine to form an on-disk relative url (for Bazel workspaces, at least).
    return '$package/${asset.path}';
  }
}

class _IgnoreAllPoliciesCompileContext implements CompileContext {
  const _IgnoreAllPoliciesCompileContext();

  @override
  bool allowListLiterals(String path) => true;
}
