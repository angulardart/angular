// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'logging.dart';

class CliOptions {
  static void printUsage() => log(_argParser.usage);

  final String pubBin;
  final String serveBin;
  final String package;
  final bool verbose;

  final List<String> serveArgs;
  final List<String> testArgs;

  const CliOptions._(
    this.pubBin,
    this.serveBin,
    this.package,
    this.verbose,
    this.serveArgs,
    this.testArgs,
  );

  factory CliOptions({
    // Options specific to `angular_test`.
    @required String pubBin,
    @required String package,
    @required bool verbose,
    @required String serveBin,

    // Translated into `pub run test` arguments.
    @required List<String> runTestFlags,
    @required List<String> runTestPlatforms,
    @required List<String> runTestNames,
    @required List<String> runTestPlainNames,
    @required List<String> runTestArgs,

    // Translated into `pub serve` arguments.
    @required String servePort,
    @required List<String> serveArgs,
  }) {
    serveArgs = serveArgs.toList();
    final testArgs = runTestArgs.toList();

    if (servePort != null) {
      serveArgs.add('--port=$servePort');
    } else if (!serveArgs.any((p) => p.contains('--port='))) {
      serveArgs.add('--port=0');
    }

    testArgs
      ..addAll(runTestFlags.map((t) => '--tags=$t'))
      ..addAll(runTestPlatforms.map((p) => '--platform=$p'))
      ..addAll(runTestNames.map((n) => '--name=$n'))
      ..addAll(runTestPlainNames.map((n) => '--plain-name=$n'));

    return new CliOptions._(
      pubBin,
      serveBin,
      package,
      verbose,
      serveArgs,
      new CombinedListView([
        const ['run', 'test'],
        testArgs,
      ]),
    );
  }

  factory CliOptions.fromArgs(List<String> args) {
    final results = _argParser.parse(args);
    if (results.wasParsed('help')) {
      log(_argParser.usage);
      exit(1);
    }
    const [
      'run-test-flag',
      'platform',
      'name',
      'plain-name',
      'port',
    ].where(results.wasParsed).forEach((option) {
      warn('"$option" is deprecated.');
    });

    String serveBin;
    var serveArgs = results['serve-arg'] as List<String>;
    var pubBin = results['pub-path'] as String;
    if (results.wasParsed('experimental-serve-script')) {
      serveBin = results['experimental-serve-script'];
    } else {
      serveBin = pubBin;
      serveArgs.insertAll(0, ['serve', 'test']);
    }

    return new CliOptions(
      pubBin: pubBin,
      serveBin: serveBin,
      package: results['package'] as String,
      verbose: results['verbose'] as bool,
      runTestFlags: results['run-test-flag'] as List<String>,
      runTestPlatforms: results['platform'] as List<String>,
      runTestNames: results['name'] as List<String>,
      runTestPlainNames: results['plain-name'] as List<String>,
      runTestArgs: results['test-arg'] as List<String>,
      servePort: results['port'] as String,
      serveArgs: serveArgs,
    );
  }
}

final _argParser = new ArgParser()
  // Hidden (internal only or for development/testing).
  ..addOption(
    'pub-path',
    help: 'Path to the "pub" executable.',
    hide: true,
    defaultsTo: Platform.isWindows ? 'pub.bat' : 'pub',
  )

  // Options specific to `angular_test`.
  ..addOption(
    'package',
    help: 'What directory containing a pub package to run tests in',
    defaultsTo: p.current,
  )
  ..addFlag(
    'verbose',
    abbr: 'v',
    help: 'Whether to display output of "pub serve" while running tests',
    defaultsTo: false,
  )
  ..addFlag(
    'help',
    help: 'Show usage',
    negatable: false,
  )

  // Translated into `pub serve` arguments.
  ..addOption(
    'port',
    help: ''
        'What port to use for pub serve.\n\n'
        '**DEPRECATED**: Use --serve-arg=--port=.... If this is\n'
        'not specified, and --serve-arg=--port is not specified, then\n'
        'defaults to a value of "0" (or random port).',
  )
  ..addOption(
    'serve-arg',
    abbr: 'S',
    help: ''
        'Pass an additional argument=value to `pub serve`\n\n'
        'Example use --serve-arg=--mode=release',
    allowMultiple: true,
  )

  // Translated into `pub run test` arguments.
  ..addOption(
    'run-test-flag',
    abbr: 't',
    help: ''
        'What flag(s) to include when running "pub run test".\n'
        'In order to have a fast test cycle, we only want to run\n'
        'tests that have Angular compilation required (all the ones\n'
        'created using this package do).\n\n'
        '**DEPRECATED**: Use --test-arg=--tags=... instead',
    allowMultiple: true,
  )
  ..addOption(
    'platform',
    abbr: 'p',
    help: ''
        'What platform(s) to pass to `pub run test`.\n\n'
        '**DEPRECATED**: Use --test-arg=--platform=... instead',
    allowMultiple: true,
  )
  ..addOption(
    'name',
    abbr: 'n',
    help: ''
        'A substring of the name of the test to run.\n'
        'Regular expression syntax is supported.\n'
        'If passed multiple times, tests must match all substrings.\n\n'
        '**DEPRECATED**: Use --test-arg=--name=... instead',
    allowMultiple: true,
    splitCommas: false,
  )
  ..addOption(
    'plain-name',
    abbr: 'N',
    help: ''
        'A plain-text substring of the name of the test to run.\n'
        'If passed multiple times, tests must match all substrings.\n\n'
        '**DEPRECATED**: Use --test-arg=--plain-name=... instead',
    allowMultiple: true,
    splitCommas: false,
  )
  ..addOption(
    'test-arg',
    abbr: 'T',
    help: ''
        'Pass an additional argument=value to `pub run test`\n\n'
        'Example: --test-arg=--name=ngIf',
    allowMultiple: true,
  )
  ..addOption('experimental-serve-script',
      help: ''
          'A custom build server script to run instead of pub serve. '
          'Path should be relative to --package if provided.'
          'Example: --experimental-serve-script=tool/build.dart');
