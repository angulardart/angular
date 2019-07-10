import 'dart:async';

import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

import 'flags.dart';
import 'logging.dart';

/// Compiles `.dart` files and `.html`, `.css` files for AngularDart.
///
/// To use as a [Builder], see [Compiler.asBuilder].
class Compiler implements Generator {
  // Note: Use an absurdly long line width in order to speed up the formatter.
  // We still get a lot of other formatting, such as forced line breaks (after
  // semicolons for instance), spaces in argument lists, etc.
  static final _formatter = DartFormatter(pageWidth: 1000000);

  // Ideally this would be part of this generator, and not delegated to an
  // external function, but today much of the AngularDart compiler still lives
  // inside package:angular, and is non-trivial to
  // move over atomically.
  //
  // Once we're able to remove this parameter, we should.
  final Future<String> Function(LibraryReader, BuildStep, CompilerFlags) _build;
  final CompilerFlags _flags;
  final Map<Object, Object> _context;

  /// Create a new [Compiler] instance that uses the provided flag and builder.
  const Compiler(this._flags, this._build, [this._context = const {}]);

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) {
    return runBuildZoned(
      () => _build(library, buildStep, _flags),
      zoneValues: _context,
    );
  }

  /// Returns the compiler wrapped as a [Builder].
  Builder asBuilder({String extension = '.template.dart'}) {
    return LibraryBuilder(
      this,
      formatOutput: (s) => _formatter.format(s),
      generatedExtension: extension,
      header: '',
    );
  }

  /// Identify ourselves in debug logs and generated files.
  @override
  toString() => 'AngularDart Compiler';
}

/// Generates an empty file to indicate `.template.dart` will exist.
///
/// For files in the same build action (i.e. `dart_library` for Bazel and
/// a module for `build_runner`), we can't rely on a `.template.dart` existing
/// on disk as an indication whether one _will_ exist, or not.
///
/// Instead, a `.ng_placeholder` file may be emitted in an earlier build phase
/// in order to indicate "a .template.dart of the same will exist by the time
/// it is necessary to compile".
///
/// See: https://github.com/dart-lang/angular/issues/864.
class Placeholder implements Builder {
  const Placeholder();

  @override
  final buildExtensions = const {
    '.dart': ['.ng_placeholder'],
  };

  @override
  Future<Object> build(BuildStep buildStep) => buildStep.writeAsString(
      buildStep.inputId.changeExtension('.ng_placeholder'), '');
}
