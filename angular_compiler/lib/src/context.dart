import 'dart:async';

import 'package:meta/meta.dart';

import 'analyzer.dart';

/// Execution-local static state for the current compilation.
///
/// When the compiler is running as a worker (i.e. long-running), this context
/// refers to the _current_ compilation occurring (where multiple may occur over
/// the lifecycle of the compiler).
class CompileContext {
  /// Currently executing context based on [Zone.current].
  static CompileContext get current {
    final context = Zone.current[CompileContext];
    if (context == null) {
      throw StateError('No CompileContext configured');
    }
    return context as CompileContext;
  }

  /// Creates a new [CompileContext].
  factory CompileContext({
    Iterable<String> allowedTypeDefs = const [],
  }) {
    return CompileContext._(
      allowedTypeDefs: allowedTypeDefs.map((uri) {
        final parts = uri.split('#');
        final symbol = parts.last;
        final import = parts.first;
        return TypeLink(symbol, import);
      }).toSet(),
    );
  }

  /// See [CompilerFlags.allowedTypeDefs].
  final Set<TypeLink> allowedTypeDefs;

  const CompileContext._({
    @required this.allowedTypeDefs,
  }) : assert(allowedTypeDefs != null);
}
