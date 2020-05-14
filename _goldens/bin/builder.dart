import 'package:angular/src/build.dart' as angular;
import 'package:build/build.dart';

BuilderOptions _withoutExtensions(BuilderOptions options) => BuilderOptions({}
  ..addAll(options.config)
  ..remove('extensions'));

final placeholderBuilder = angular.templatePlaceholder;

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
    templateExtension: options.config['extensions']['template'],
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
    extension: options.config['extensions']['outline'],
  );
}
