import 'package:args/args.dart';
import 'package:meta/meta.dart';

const _argProfileFor = 'profile';
const _argLegacyStyle = 'use_legacy_style_encapsulation';

// Experimental flags (not published).
const _argForceMinifyWhitespace = 'force-minify-whitespace';
const _argNoEmitComponentFactories = 'no-emit-component-factories';
const _argNoEmitInjectableFactories = 'no-emit-injectable-factories';

/// Compiler-wide configuration (flags) to allow opting in/out.
///
/// In some build environments flags are only configurable at the application
/// level, in others they occur at the package level. This class is not
/// opinionated and allows anything to be set, but has reasonable defaults set
/// with an option to use defaults set by bazel or pub's build systems.
class CompilerFlags {
  static final _argParser = ArgParser()
    ..addFlag(
      _argLegacyStyle,
      defaultsTo: null,
      help: ''
          'Enables the use of deprecated Shadow DOM CSS selectors, and '
          'cause shadow host selectors to prevent a series of selectors '
          'from being properly scoped to their component',
    )
    ..addOption(
      _argProfileFor,
      valueHelp: '"build"',
      defaultsTo: null,
      help: ''
          'Whether to emit additional code that may be used by tooling '
          'in order to profile performance or other runtime information.',
    )
    ..addFlag(
      _argForceMinifyWhitespace,
      defaultsTo: null,
      hide: true,
    )
    ..addFlag(
      _argNoEmitComponentFactories,
      hide: true,
    )
    ..addFlag(
      _argNoEmitInjectableFactories,
      hide: true,
    );

  /// What (named) function types (typedefs) can be used as DI tokens.
  final List<String> allowedTypeDefs;

  /// Whether to opt-in to supporting a legacy mode of style encapsulation.
  ///
  /// If `true`, shadow host selectors prevent the following selectors from
  /// being scoped to their component much like a shadow piercing combinator.
  /// It also allows the use of the following _deprecated_ selectors:
  /// * `::content`
  /// * `::shadow`
  /// * polyfill-next-selector
  /// * polyfill-unscoped-rule
  final bool useLegacyStyleEncapsulation;

  /// Whether to look for a file to determine if `.template.dart` will exist.
  ///
  /// **NOTE**: This is an _internal_ flag that is currently only supported for
  /// use with the golden file testing, and may be removed at some point in the
  /// future.
  @experimental
  final bool ignoreNgPlaceholderForGoldens;

  /// Whether to operate as if `preserveWhitespace: false` is always set.
  @experimental
  final bool forceMinifyWhitespace;

  /// Whether to emit code supporting `SlowComponentLoader`.
  @experimental
  final bool emitComponentFactories;

  /// Whether to emit code supporting `ReflectiveInjector`.
  @experimental
  final bool emitInjectableFactories;

  /// Whether to emit `export {{file.dart}}` in `file.template.dart`.
  @experimental
  final bool exportUserCodeFromTemplate;

  const CompilerFlags({
    this.allowedTypeDefs = const [],
    this.ignoreNgPlaceholderForGoldens = false,
    this.useLegacyStyleEncapsulation = false,
    this.forceMinifyWhitespace = false,
    this.emitComponentFactories = true,
    this.emitInjectableFactories = true,
    this.exportUserCodeFromTemplate = true,
  });

  /// Creates flags by parsing command-line arguments.
  ///
  /// Failures are reported to [logger].
  factory CompilerFlags.parseArgs(
    List<String> args, {
    CompilerFlags defaultTo = const CompilerFlags(),
  }) {
    final results = _argParser.parse(args);
    return CompilerFlags.parseRaw(
      results,
      defaultTo,
    );
  }

  /// Parses a raw map of flags into [CompilerFlags].
  ///
  /// Failures are reported to [logger].
  factory CompilerFlags.parseRaw(
    // Untyped because 'argResults' doesn't expose a Map interface.
    dynamic options,
    CompilerFlags defaultTo,
  ) {
    // Check for invalid (unknown) arguments when possible.
    if (options is Map<Object, Object>) {
      final knownArgs = const [
        _argProfileFor,
        _argLegacyStyle,
        _argForceMinifyWhitespace,
        _argNoEmitComponentFactories,
        _argNoEmitInjectableFactories,
      ].toSet();
      final unknownArgs = options.keys.toSet().difference(knownArgs);
      if (unknownArgs.isNotEmpty) {
        final message = ''
            'Invalid compiler arguments: \n'
            '  - ${unknownArgs.join('\n  - ')}\n\n';
        throw ArgumentError(message);
      }
    }

    final useLegacyStyle = options[_argLegacyStyle];
    final forceMinifyWhitespace = options[_argForceMinifyWhitespace];
    final noEmitComponentFactories = options[_argNoEmitComponentFactories];
    final noEmitInjectableFactories = options[_argNoEmitInjectableFactories];

    return CompilerFlags(
      useLegacyStyleEncapsulation:
          useLegacyStyle ?? defaultTo.useLegacyStyleEncapsulation,
      forceMinifyWhitespace:
          forceMinifyWhitespace ?? defaultTo.forceMinifyWhitespace,
      emitComponentFactories: !(noEmitComponentFactories == true),
      emitInjectableFactories: !(noEmitInjectableFactories == true),
    );
  }
}
