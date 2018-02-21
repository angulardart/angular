import 'package:angular/builder.dart' as angular;
import 'package:angular_compiler/cli.dart';
import 'package:build/build.dart';

BuilderOptions _withoutExtensions(BuilderOptions options) =>
    new BuilderOptions({}
      ..addAll(options.config)
      ..remove('extensions'));

/// Returns a [Builder] to generate (debug) template files for comparison.
///
/// Based on `build.yaml` configuration, this will either emit:
/// * `.golden` files: Checked into the repository.
/// * `.check` files: Temporarily generated, at HEAD, to compare against.
///
/// See `README.md` for this package for details.
Builder debugBuilder(BuilderOptions options) {
  return angular.templateCompiler(
    _withoutExtensions(options),
    defaultFlags: const CompilerFlags(
      genDebugInfo: true,
      ignoreNgPlaceholderForGoldens: true,
      useAstPkg: true,
    ),
    templateExtension: options.config['extensions']['debug'],
  );
}

/// Returns a [Builder] to generate (release) template files for comparison.
///
/// Based on `build.yaml` configuration, this will either emit:
/// * `.golden` files: Checked into the repository.
/// * `.check` files: Temporarily generated, at HEAD, to compare against.
///
/// See `README.md` for this package for details.
Builder releaseBuilder(BuilderOptions options) {
  return angular.templateCompiler(
    _withoutExtensions(options),
    defaultFlags: const CompilerFlags(
      genDebugInfo: false,
      ignoreNgPlaceholderForGoldens: true,
      useAstPkg: true,
    ),
    templateExtension: options.config['extensions']['release'],
  );
}

/// Returns a [Builder] to generate outline files for comparison.
///
/// Based on `build.yaml` configuration, this will either emit:
/// * `.golden` files: Checked into the repository.
/// * `.check` files: Temporarily generated, at HEAD, to compare against.
///
/// See `README.md` for this package for details.
Builder outlineBuilder(BuilderOptions options) {
  return angular.outlineCompiler(
    _withoutExtensions(options),
    defaultFlags: const CompilerFlags(
      genDebugInfo: false,
      ignoreNgPlaceholderForGoldens: true,
      useAstPkg: true,
    ),
    extension: options.config['extensions']['outline'],
  );
}
