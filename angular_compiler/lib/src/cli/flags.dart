import 'package:args/args.dart';
import 'package:build/build.dart' as build;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

const _argProfileFor = 'profile';
const _argLegacyStyle = 'use_legacy_style_encapsulation';

// Experimental flags (not published).
const _argForceMinifyWhitespace = 'force-minify-whitespace';
const _argI18nEnabled = 'i18n';
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
      valueHelp: '"build" or "binding"',
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
      _argI18nEnabled,
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

  /// Whether to emit extra code suitable for testing and local development.
  @Deprecated('This value is always `false`')
  final bool genDebugInfo;

  /// May emit extra code suitable for profiling or tooling.
  final Profile profileFor;

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

  /// Whether internationalization of templates is supported.
  ///
  /// This flag is currently used to disable support while the feature is
  /// developed.
  @experimental
  final bool i18nEnabled;

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
    this.genDebugInfo = false,
    this.i18nEnabled = false,
    this.ignoreNgPlaceholderForGoldens = false,
    this.profileFor = Profile.none,
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
    CompilerFlags defaultTo = const CompilerFlags(genDebugInfo: false),
    Logger logger,
    Level severity = Level.WARNING,
  }) {
    final results = _argParser.parse(args);
    return CompilerFlags.parseRaw(
      results,
      defaultTo,
      logger: logger,
      severity: severity,
    );
  }

  /// Parses a raw map of flags into [CompilerFlags].
  ///
  /// Failures are reported to [logger].
  factory CompilerFlags.parseRaw(
    // Untyped because 'argResults' doesn't expose a Map interface.
    dynamic options,
    CompilerFlags defaultTo, {
    Logger logger,
    Level severity = Level.WARNING,
  }) {
    // Use the default package:build logger if not specified, otherwise throw.
    logger ??= build.log;
    void log(dynamic message) {
      if (logger == null) throw message;
      logger.log(severity, message);
    }

    // Check for invalid (unknown) arguments when possible.
    if (options is Map) {
      final knownArgs = const [
        _argI18nEnabled,
        _argProfileFor,
        _argLegacyStyle,
        _argForceMinifyWhitespace,
        _argNoEmitComponentFactories,
        _argNoEmitInjectableFactories,
      ].toSet();
      final unknownArgs = options.keys.toSet().difference(knownArgs);
      if (unknownArgs.isNotEmpty) {
        final message = 'Invalid arguments passed to the transformer: \n'
            '  - ${unknownArgs.join('\n  - ')}\n\n'
            'You may be providing flags that are no longer valid or supported '
            'for AngularDart 5.x. See "compiler_flags.md" in the AngularDart '
            'repository for a list of supported flags.';
        throw ArgumentError(message);
      }
    }

    final i18nEnabled = options[_argI18nEnabled];
    final profileFor = options[_argProfileFor];
    final useLegacyStyle = options[_argLegacyStyle];
    final forceMinifyWhitespace = options[_argForceMinifyWhitespace];
    final noEmitComponentFactories = options[_argNoEmitComponentFactories];
    final noEmitInjectableFactories = options[_argNoEmitInjectableFactories];

    return CompilerFlags(
      genDebugInfo: false,
      i18nEnabled: i18nEnabled ?? defaultTo.i18nEnabled,
      profileFor: _toProfile(profileFor, log) ?? defaultTo.profileFor,
      useLegacyStyleEncapsulation:
          useLegacyStyle ?? defaultTo.useLegacyStyleEncapsulation,
      forceMinifyWhitespace:
          forceMinifyWhitespace ?? defaultTo.forceMinifyWhitespace,
      emitComponentFactories: !(noEmitComponentFactories == true),
      emitInjectableFactories: !(noEmitInjectableFactories == true),
    );
  }
}

/// Optional configuration for emitting additional code for profiling.
///
/// See [CompilerFlags.profileFor].
enum Profile {
  /// No profiling is enabled.
  none,

  /// Profile component view construction performance.
  build,

  /// Profile component bindings (accessed methods and getters in components).
  binding,
}

Profile _toProfile(dynamic profile, void log(dynamic message)) {
  if (profile == null) return null;
  switch (profile) {
    case '':
      return Profile.none;
    case 'build':
      return Profile.build;
    case 'binding':
      return Profile.binding;
    default:
      log('Invalid flag for "$_argProfileFor": $profile.');
      return Profile.none;
  }
}
