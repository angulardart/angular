#!/usr/bin/env dart
import 'dart:async';
import 'dart:io';

import 'package:angular/src/source_gen/source_gen.dart';
import 'package:angular/src/transform/stylesheet_compiler/transformer.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:build/build.dart';
import 'package:build_barback/build_barback.dart';

import 'package:build_compilers/build_compilers.dart';

import 'package:build_runner/build_runner.dart';
import 'package:build_test/builder.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future main(List<String> args) async {
  var port = 8080;
  if (args.isNotEmpty) {
    assert(args.length == 1 && args.first.startsWith('--port'));
    var parts = args.first.split('=');
    assert(parts.length == 2);
    port = int.parse(parts[1]);
  }

  var graph = new PackageGraph.forThisPackage();
  var buildActions = _angularBuildActions(graph);
  buildActions.add(new BuildAction(new TestBootstrapBuilder(), graph.root.name,
      inputs: ['test/**_test.dart']));

  void addBuilderForAll(Builder builder, String inputExtension) {
    for (var packageNode in graph.orderedPackages) {
      buildActions
          .add(new BuildAction(builder, packageNode.name, isOptional: true));
    }
  }

  addBuilderForAll(new ModuleBuilder(), '.dart');
  addBuilderForAll(new UnlinkedSummaryBuilder(), moduleExtension);
  addBuilderForAll(new LinkedSummaryBuilder(), moduleExtension);
  addBuilderForAll(new DevCompilerBuilder(), moduleExtension);

  buildActions.add(new BuildAction(
      new DevCompilerBootstrapBuilder(), graph.root.name,
      inputs: ['web/**.dart', 'test/**.browser_test.dart']));

  var serveHandler = await watch(
    buildActions,
    deleteFilesByDefault: true,
    writeToCache: true,
  );

  var testServer =
      await shelf_io.serve(serveHandler.handlerFor('test'), 'localhost', port);

  var firstBuild = await serveHandler.currentBuild;
  stdout.writeln('Serving test on http://localhost:$port/');

  if (firstBuild.status == BuildStatus.success) {
    stdout.writeln('Build completed successfully');
  }

  await serveHandler.buildResults.drain();
  await testServer.close();
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
