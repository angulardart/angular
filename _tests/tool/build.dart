#!/usr/bin/env dart
import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_compilers/build_compilers.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_test/builder.dart';
import 'package:angular/src/source_gen/source_gen.dart';
import 'package:angular/src/transform/stylesheet_compiler/transformer.dart';
import 'package:angular_compiler/angular_compiler.dart';

Future main(List<String> args) async {
  var graph = new PackageGraph.forThisPackage();
  var flags = new CompilerFlags(genDebugInfo: true);
  var builders = [
    apply(
        'angular',
        'angular',
        [
          (_) => const TemplatePlaceholderBuilder(),
          (_) => createSourceGenTemplateCompiler(flags),
          (_) => new StylesheetCompiler(flags),
        ],
        toAll([toPackage('angular'), toDependentsOf('angular')])),
    applyToRoot(new TestBootstrapBuilder(), inputs: ['test/**_test.dart']),
    apply(
        'build_compilers',
        'ddc',
        [
          (_) => new ModuleBuilder(),
          (_) => new UnlinkedSummaryBuilder(),
          (_) => new LinkedSummaryBuilder(),
          (_) => new DevCompilerBuilder(),
        ],
        toAllPackages(),
        isOptional: true),
    applyToRoot(new DevCompilerBootstrapBuilder(),
        inputs: ['web/**.dart', 'test/**.browser_test.dart']),
  ];

  await build(
    createBuildActions(graph, builders),
    deleteFilesByDefault: true,
    writeToCache: true,
    enableLowResourcesMode: true,
  );
}
