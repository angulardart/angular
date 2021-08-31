import 'package:args/args.dart';
import 'package:meta/meta.dart';

// Force enables the data-debug-source attribute on DOM elements created by
// AngularDart templates.
//
// This is intended to be manually changed for accessibility TGPs. It should
// remain false otherwise.
const _forceEnableDataDebugSource = false;

const _argLegacyStyle = 'use_legacy_style_encapsulation';
const _argDataDebugSource = 'enable-data-debug-source';

// Experimental flags (not published).
const _argEnableDevTools = 'enable_devtools';
// TODO(b/160883079): Use underscores everywhere.
const _argForceMinifyWhitespace = 'force-minify-whitespace';
const _argNoEmitComponentFactories = 'no-emit-component-factories';
const _argNoEmitInjectableFactories = 'no-emit-injectable-factories';
const _argPolicyExceptions = 'policy-exception';
const _argPolicyExceptionInPackages = 'policy-exception-in-packages';

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
    ..addFlag(_argDataDebugSource,
        defaultsTo: false,
        help: 'Adds the `data-debug-source` attribute to dom elements '
            'created from AngularDart templates.')
    ..addFlag(
      _argEnableDevTools,
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
    )
    ..addMultiOption(
      _argPolicyExceptionInPackages,
      hide: true,
    );

  /// Whether to emit code that supports developer tooling.
  @experimental
  final bool enableDevTools;

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

  /// Whether to add the `data-debug-source` attribute to dom elements created
  /// from AngularDart templates.
  final bool enableDataDebugSource;

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

  /// Exceptions keyed by `PolicyName` => `Packages`.
  @experimental
  final Map<String, Set<String>> policyExceptionInPackages;

  /// Exceptions keyed by `Name` -> `Paths`.
  final Map<String, Set<String>> policyExceptions;

  const CompilerFlags({
    this.enableDevTools = false,
    this.useLegacyStyleEncapsulation = false,
    this.forceMinifyWhitespace = false,
    this.emitComponentFactories = true,
    this.emitInjectableFactories = true,
    this.exportUserCodeFromTemplate = false,
    this.policyExceptionInPackages = const {},
    this.policyExceptions = const {},
    this.enableDataDebugSource = false,
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
        _argEnableDevTools,
        _argLegacyStyle,
        _argDataDebugSource,
        _argForceMinifyWhitespace,
        _argNoEmitComponentFactories,
        _argNoEmitInjectableFactories,
        _argPolicyExceptions,
        _argPolicyExceptionInPackages,
      };
      final unknownArgs = options.keys.toSet().difference(knownArgs);
      if (unknownArgs.isNotEmpty) {
        final message = ''
            'Invalid compiler arguments: \n'
            '  - ${unknownArgs.join('\n  - ')}\n\n';
        throw ArgumentError(message);
      }
    }

    final enableDevTools = options[_argEnableDevTools];
    final useLegacyStyle = options[_argLegacyStyle];
    final enableDataDebugSource = options[_argDataDebugSource];
    final forceMinifyWhitespace = options[_argForceMinifyWhitespace];
    final noEmitComponentFactories = options[_argNoEmitComponentFactories];
    final noEmitInjectableFactories = options[_argNoEmitInjectableFactories];
    final policyExceptions = options[_argPolicyExceptions];
    final policyExceptionInPackages = options[_argPolicyExceptionInPackages];

    return CompilerFlags(
      enableDevTools: enableDevTools as bool? ?? defaultTo.enableDevTools,
      useLegacyStyleEncapsulation:
          useLegacyStyle as bool? ?? defaultTo.useLegacyStyleEncapsulation,
      forceMinifyWhitespace:
          forceMinifyWhitespace as bool? ?? defaultTo.forceMinifyWhitespace,
      emitComponentFactories: noEmitComponentFactories != true,
      emitInjectableFactories: noEmitInjectableFactories != true,
      policyExceptions: _buildPolicyExceptions(policyExceptions),
      policyExceptionInPackages:
          _buildPolicyExceptions(policyExceptionInPackages),
      enableDataDebugSource: _forceEnableDataDebugSource ||
          (enableDataDebugSource as bool? ?? defaultTo.enableDataDebugSource),
    );
  }

  static Map<String, Set<String>> _buildPolicyExceptions(Object? arguments) {
    // No policy exceptions.
    if (arguments == null) {
      return const {};
    }
    // Single policy exception is parsed a String.
    if (arguments is String) {
      arguments = <String>[arguments];
    }
    // Process policy exceptions.
    //
    // This nested format is what is supported by _bazel_codegen (b/169775556).
    // --policy-exception=["A:file.dart", "B:file.dart"]
    if (arguments is List<Object>) {
      final output = <String, Set<String>>{};
      for (final argument in arguments.cast<String>()) {
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
