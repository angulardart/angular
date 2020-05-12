import 'package:args/args.dart';
import 'package:meta/meta.dart';

const _argProfileFor = 'profile';
const _argLegacyStyle = 'use_legacy_style_encapsulation';

// Experimental flags (not published).
const _argRemoveDebugAttributes = 'remove-debug-attributes';
const _argForceMinifyWhitespace = 'force-minify-whitespace';
const _argNoEmitComponentFactories = 'no-emit-component-factories';
const _argNoEmitInjectableFactories = 'no-emit-injectable-factories';
const _argPolicyExceptions = 'policy-exception';

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
      _argRemoveDebugAttributes,
      defaultsTo: false,
      hide: true,
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
    )
    ..addMultiOption(
      _argPolicyExceptions,
      hide: true,
    );

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

  /// Removes all HTML attributes starting `debug`.
  ///
  /// The current implementation _always_ removes these attributes (regardless
  /// of whether `assert` is enabled) in order to estimate code-size benefits
  /// to our larger apps.
  @experimental
  final bool removeDebugAttributes;

  /// Exceptions keyed by `Name` -> `Paths`.
  final Map<String, Set<String>> policyExceptions;

  const CompilerFlags({
    this.useLegacyStyleEncapsulation = false,
    this.forceMinifyWhitespace = false,
    this.emitComponentFactories = true,
    this.emitInjectableFactories = true,
    this.exportUserCodeFromTemplate = true,
    this.removeDebugAttributes = false,
    this.policyExceptions = const {},
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
      final knownArgs = const {
        _argProfileFor,
        _argLegacyStyle,
        _argForceMinifyWhitespace,
        _argNoEmitComponentFactories,
        _argNoEmitInjectableFactories,
        _argPolicyExceptions,
        _argRemoveDebugAttributes,
      };
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
    final policyExceptions = options[_argPolicyExceptions];
    final removeDebugAttributes = options[_argRemoveDebugAttributes];

    return CompilerFlags(
      useLegacyStyleEncapsulation:
          useLegacyStyle ?? defaultTo.useLegacyStyleEncapsulation,
      forceMinifyWhitespace:
          forceMinifyWhitespace ?? defaultTo.forceMinifyWhitespace,
      emitComponentFactories: noEmitComponentFactories != true,
      emitInjectableFactories: noEmitInjectableFactories != true,
      policyExceptions: _buildPolicyExceptions(policyExceptions),
      removeDebugAttributes:
          removeDebugAttributes ?? defaultTo.removeDebugAttributes,
    );
  }

  static Map<String, Set<String>> _buildPolicyExceptions(Object arguments) {
    // No policy exceptions.
    if (arguments == null) {
      return const {};
    }
    // Single policy exception is parsed a String.
    if (arguments is String) {
      arguments = <String>[arguments];
    }
    // Process policy exceptions.
    if (arguments is List<String>) {
      final output = <String, Set<String>>{};
      for (final argument in arguments) {
        final split = argument.split(':');
        final policy = split.first;
        final files = split.last.split(',');
        output[policy] = files.toSet();
      }
      return output;
    }
    // Unknown/unsupported.
    throw ArgumentError.value(
      arguments,
      'arguments',
      'Expected List<String>, got ${arguments.runtimeType}.',
    );
  }
}
