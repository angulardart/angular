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
  var buildActions = _angularBuildActions(graph);
  buildActions.add(new BuildAction(new TestBootstrapBuilder(), graph.root.name,
      inputs: ['test/**_test.dart']));

  void addBuilderForAll(Builder builder) {
    for (var packageNode in graph.orderedPackages) {
      buildActions
          .add(new BuildAction(builder, packageNode.name, isOptional: true));
    }
  }

  addBuilderForAll(new ModuleBuilder());
  addBuilderForAll(new UnlinkedSummaryBuilder());
  addBuilderForAll(new LinkedSummaryBuilder());
  addBuilderForAll(new DevCompilerBuilder());

  buildActions.add(new BuildAction(
      new DevCompilerBootstrapBuilder(), graph.root.name,
      inputs: ['web/**.dart', 'test/**.browser_test.dart']));

  await build(
    buildActions,
    deleteFilesByDefault: true,
    writeToCache: true,
    enableLowResourcesMode: true,
    buildDir: 'build',
  );
  // TODO(jakemac): Something is preventing us from exiting here.
  exit(0);
}

List<BuildAction> _angularBuildActions(PackageGraph graph) {
  var actions = <BuildAction>[];
  var flags = new CompilerFlags(genDebugInfo: true);
  var builders = [
    const TemplatePlaceholderBuilder(),
    createSourceGenTemplateCompiler(flags),
    new StylesheetCompiler(flags),
  ];
  var packages = ['angular']
    ..addAll(graph.dependentsOf('angular').map((n) => n.name));
  for (var builder in builders) {
    for (var package in packages) {
      actions.add(new BuildAction(builder, package));
    }
  }
  return actions;
}
