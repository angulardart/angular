import 'dart:async';

import 'package:build/build.dart';
import 'package:angular_compiler/cli.dart';

import '../common/names.dart';
import 'processor.dart';

/// Pre-compiles CSS stylesheet files to Dart code for Angular 2.
class StylesheetCompiler implements Builder {
  final CompilerFlags _flags;

  const StylesheetCompiler(this._flags);

  @override
  final buildExtensions = const {
    CSS_EXTENSION: const [
      SHIMMED_STYLESHEET_EXTENSION,
      NON_SHIMMED_STYLESHEET_EXTENSION,
    ],
  };

  @override
  Future build(BuildStep buildStep) async {
    final outputs = await processStylesheet(
      buildStep,
      buildStep.inputId,
      _flags,
    );
    outputs.forEach(buildStep.writeAsString);
  }
}
