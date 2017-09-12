import 'dart:async';

import 'package:build/build.dart';
import 'package:angular/src/transform/common/names.dart';
import 'package:angular_compiler/angular_compiler.dart';

import 'processor.dart';

/// Pre-compiles CSS stylesheet files to Dart code for Angular 2.
class StylesheetCompiler implements Builder {
  final CompilerFlags _flags;

  StylesheetCompiler(this._flags);

  @override
  final buildExtensions = {
    CSS_EXTENSION: const [
      SHIMMED_STYLESHEET_EXTENSION,
      NON_SHIMMED_STYLESHEET_EXTENSION
    ]
  };

  @override
  Future build(BuildStep buildStep) async {
    final outputs =
        await processStylesheet(buildStep, buildStep.inputId, _flags);
    outputs.forEach(buildStep.writeAsString);
  }
}
