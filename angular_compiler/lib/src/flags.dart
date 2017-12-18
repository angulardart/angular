import 'package:args/args.dart';
import 'package:barback/barback.dart' show BarbackSettings;
import 'package:build/build.dart' as build;
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

const _argDebugMode = 'debug';
const _argProfileFor = 'profile';
const _argLegacyStyle = 'use_legacy_style_encapsulation';
const _argAstPkg = 'use_new_template_parser';
const _argFastBoot = 'fast_boot';

// TODO: Deprecate. The compiler doesn't even work without it.
const _argPlaceholder = 'use_placeholder';

// TODO: Deprecate. Never shipped.
const _argEntryPoints = 'entry_points';

/// Compiler-wide configuration (flags) to allow opting in/out.
///
/// In some build environments flags are only configurable at the application
/// level, in others they occur at the package level. This class is not
/// opinionated and allows anything to be set, but has reasonable defaults set
/// with an option to use defaults set by bazel or pub's build systems.
class CompilerFlags {
  static final _argParser = new ArgParser()
    ..addFlag(
      _argDebugMode,
      defaultsTo: null,
      help: ''
          'Whether to run the code generator in debug mode. This is '
          'useful for local development but should be disabled for '
          'production builds.',
    )
    ..addFlag(
      _argLegacyStyle,
      defaultsTo: null,
      help: ''
          'Enables the use of deprecated Shadow DOM CSS selectors, and '
          'cause shadow host selectors to prevent a series of selectors '
          'from being properly scoped to their component',
    )
    ..addFlag(
      _argPlaceholder,
      defaultsTo: null,
      hide: true,
      help: ''
          'Enables the creation of an empty "placeholder" file. Some '
          'build systems require this in order to be able to determine '
          'where a ".template.dart" file will exist in a future build '
          'phase.',
    )
    ..addOption(
      _argProfileFor,
      valueHelp: '"build" or "binding"',
      defaultsTo: null,
      help: ''
          'Whether to emit additional code that may be used by tooling '
          'in order to profile performance or other runtime information.',
    )
    ..addOption(
      _argEntryPoints,
      allowMultiple: true,
      defaultsTo: null,
      help: ''
          'Entrypoint(s) of the application (i.e. where `bootstrap` is '
          'invoked). Build systems that re-write files use this in order '
          'to transform those calls to `bootstrapStatic`. These may be '
          'written in a glob format (such as lib/web/main_*.dart).',
    )
    ..addFlag(
      _argAstPkg,
      defaultsTo: null,
      hide: true,
      help: ''
          'Whether to use pkg:angular_ast for parsing template files instead '
          'of the existing template parser.',
    )
    ..addFlag(_argFastBoot,
        defaultsTo: null,
        help: 'Whether to support AngularDart v5\'s "fastBoot" functionality.');

  /// Entrypoint(s) of the application (i.e. where `bootstrap` is invoked).
  ///
  /// Build systems that re-write files use this in order to transform those
  /// calls to `bootstrapStatic`.
  final List<Glob> entryPoints;

  /// Whether to emit extra code suitable for testing and local development.
  final bool genDebugInfo;

  /// May emit extra code suitable for profiling or tooling.
  final Profile profileFor;

  /// Whether to support AngularDart v5's "fastBoot" functionality.
  ///
  /// If `false`, additional code may be generated that negatively affects
  /// startup performance and code size, but allows compatibility with
  /// functionality such as `SlowComponentLoader` and `ReflectiveInjector`.
  final bool useFastBoot;

  /// Whether to generate placeholder files in order to inform the compilation.
  ///
  /// In some build systems we aren't able to determine what files in the same
  /// package will have code generated portions, so `usePlaceholder` creates
  /// a dummy file for every file so we can use the file system as an indication
  /// that a `.template.dart` file will later exist.
  final bool usePlaceholder;

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

  /// Whether to opt-in to using the new angular_ast package for parsing
  /// template files.
  final bool useAstPkg;

  const CompilerFlags({
    @required this.genDebugInfo,
    this.entryPoints: const [],
    this.profileFor: Profile.none,
    this.useFastBoot: true,
    this.useLegacyStyleEncapsulation: false,
    this.usePlaceholder: true,
    this.useAstPkg: false,
  });

  /// Creates flags by parsing command-line arguments.
  ///
  /// Failures are reported to [logger].
  factory CompilerFlags.parseArgs(
    List<String> args, {
    CompilerFlags defaultTo: const CompilerFlags(genDebugInfo: false),
    Logger logger,
    Level severity: Level.WARNING,
  }) {
    final results = _argParser.parse(args);
    return new CompilerFlags.parseRaw(
      results,
      defaultTo,
      logger: logger,
      severity: severity,
    );
  }

  /// Creates flags by parsing barback transformer configuration.
  ///
  /// Failures are reported to [logger].
  factory CompilerFlags.parseBarback(
    BarbackSettings settings, {
    CompilerFlags defaultTo,
    Logger logger,
    Level severity: Level.WARNING,
  }) {
    defaultTo = new CompilerFlags(
      genDebugInfo: defaultTo.genDebugInfo,
    );
    return new CompilerFlags.parseRaw(
      settings.configuration,
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
    Level severity: Level.WARNING,
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
        _argDebugMode,
        _argProfileFor,
        _argLegacyStyle,
        _argPlaceholder,
        _argEntryPoints,
        _argAstPkg,
        _argFastBoot,
      ].toSet();
      final unknownArgs = options.keys.toSet().difference(knownArgs);
      if (unknownArgs.isNotEmpty) {
        logger?.severe('Invalid arguments passed to the transformer: \n'
            '  - ${unknownArgs.join('\n  - ')}\n\n'
            'You may be providing flags that are no longer valid or supported '
            'for AngularDart 5.x. See "compiler_flags.md" in the AngularDart '
            'repository for a list of supported flags.');
        throw new ArgumentError('Invalid compiler argument(s).');
      }
    }

    var debugMode = options[_argDebugMode];
    if (debugMode != null && debugMode is! bool) {
      log('Invalid value "$_argDebugMode": $debugMode');
      debugMode = null;
    }
    var entryPoints = options[_argEntryPoints];
    // Support entry_points: web/main.dart in addition to
    // entry_points:
    //   - web/main.dart
    if (entryPoints is String) {
      entryPoints = [entryPoints];
    } else if (entryPoints != null && entryPoints is! List<String>) {
      log('Invalid value "$_argEntryPoints": $entryPoints');
      entryPoints = null;
    }
    var profileFor = options[_argProfileFor];
    if (profileFor != null && profileFor is! String) {
      log('Invalid value "$_argProfileFor": $profileFor');
      profileFor = null;
    }
    var usePlaceholder = options[_argPlaceholder];
    if (usePlaceholder != null && usePlaceholder is! bool) {
      log('Invalid value "$_argPlaceholder": $usePlaceholder');
      usePlaceholder = null;
    }
    var useLegacyStyle = options[_argLegacyStyle];
    if (useLegacyStyle != null && useLegacyStyle is! bool) {
      log('Invalid value for "$_argLegacyStyle": $useLegacyStyle');
      useLegacyStyle = null;
    }
    var useAstPkg = options[_argAstPkg];
    if (useAstPkg != null && useAstPkg is! bool) {
      log('Invalid value for "$_argAstPkg": $useAstPkg');
      useAstPkg = null;
    }
    var useFastBoot = options[_argFastBoot];
    if (useFastBoot != null && useFastBoot is! bool) {
      log('Invalid value for "$_argFastBoot": $useFastBoot');
      useFastBoot = null;
    }
    return new CompilerFlags(
      genDebugInfo: debugMode ?? defaultTo.genDebugInfo,
      entryPoints: entryPoints == null
          ? defaultTo.entryPoints
          : (entryPoints as Iterable<String>).map((e) => new Glob(e)).toList(),
      profileFor: _toProfile(profileFor, log) ?? defaultTo.profileFor,
      usePlaceholder: usePlaceholder ?? defaultTo.usePlaceholder,
      useLegacyStyleEncapsulation:
          useLegacyStyle ?? defaultTo.useLegacyStyleEncapsulation,
      useAstPkg: useAstPkg ?? defaultTo.useAstPkg,
      useFastBoot: useFastBoot ?? defaultTo.useFastBoot,
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
