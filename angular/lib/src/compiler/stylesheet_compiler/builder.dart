import 'dart:async';

import 'package:build/build.dart';
import 'package:angular_compiler/cli.dart';

import 'processor.dart';

const _cssExtension = '.css';
const _shimmedStylesheetExtension = '.css.shim.dart';
const _nonShimmedStylesheetExtension = '.css.dart';

/// Pre-compiles CSS stylesheet files to Dart code for Angular 2.
class StylesheetCompiler implements Builder {
  final CompilerFlags _flags;

  const StylesheetCompiler(this._flags);

  @override
  final buildExtensions = const {
    _cssExtension: [
      _shimmedStylesheetExtension,
      _nonShimmedStylesheetExtension,
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final outputs = await processStylesheet(
      buildStep,
      buildStep.inputId,
      _flags,
    );
    outputs.forEach(buildStep.writeAsString);
  }
}
