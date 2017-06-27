// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart';

import 'logging.dart';
import 'options.dart';

Future<Null> run(List<String> args) async {
  initLogging('angular_test');

  final options = new CliOptions.fromArgs(args);
  _assertValidPackage(options.package);

  if (!options.verbose) {
    final logFile = new File(
      p.join(
        Directory.systemTemp.path,
        'angular_test_pub_serve_output.log',
      ),
    )..createSync();
    log('The pub serve output is at ${logFile.uri.toFilePath()}.');
    log('Run with --verbose to get this output in the console instead.');
    initFileWriting(logFile.openWrite());
  }

  Process pubServeProcess;

  void killPub() {
    if (pubServeProcess == null) return;
    log('Shutting down...');
    if (!pubServeProcess.kill() != null) {
      warn('`pub serve` was not terminated');
    }
    pubServeProcess = null;
  }

  await Chain.capture(() async {
    log('${options.pubBin} ${options.pubArgs.join(' ')}');
    pubServeProcess = await Process.start(options.pubBin, options.pubArgs);
    Uri serveUri;
    var testsRunning = false;

    final stdOutDone = _toLines(pubServeProcess.stdout).forEach((line) async {
      if (serveUri == null) {
        final serveMatch = _serveRegExp.firstMatch(line);
        if (serveMatch != null) {
          serveUri = Uri.parse(serveMatch[1]);
          log('Pub "serve" started on $serveUri');
        }
      }
      if (line.contains('Serving angular_testing')) {
        log('Using pub serve to compile code with AngularDart...');
      } else if (line.contains('Build completed successfully')) {
        if (testsRunning) {
          throw new StateError('Should only get this output once.');
        }
        if (serveUri == null) {
          throw new StateError('Could not determine serve host and port.');
        }
        success('Finished compilation. Running tests...');
        testsRunning = true;
        exitCode = await _runTests(options, serveUri.port);
        killPub();
      } else {
        log(line, verbose: options.verbose);
      }
    });
    final stdErrDone = _toLines(pubServeProcess.stderr).forEach((line) {
      error(line, verbose: options.verbose);
    });
    await Future.wait([
      stdOutDone,
      stdErrDone,
      pubServeProcess.exitCode,
    ]).whenComplete(() async {
      await closeIOSink();
    });
  }, onError: (e, chain) {
    error([e, chain.terse].join('\n').trim(), exception: e, stack: chain);
    killPub();
    exitCode = 1;
  });
}

Future<int> _runTests(CliOptions options, int port) async {
  if (port == 0) {
    throw new ArgumentError.value(port, 'port must not be `0`');
  }
  final testArgs = options.testArgs.toList()..add('--pub-serve=$port');
  log('${options.pubBin} ${testArgs.join(' ')}');
  final process = await Process.start(options.pubBin, testArgs);
  await Future.wait([
    _toLines(process.stderr).forEach(error),
    _toLines(process.stdout).forEach(log),
  ]);
  return await process.exitCode;
}

final _serveRegExp = new RegExp(r'^Serving\s+.*\s+on\s+(.*)$');

void _assertValidPackage(String path) {
  final pubspecFile = new File(p.join(path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {}
  if (!FileSystemEntity.isFileSync(p.join(path, 'pubspec.yaml'))) {
    error('No "pubspec.yaml" found at $path.');
    CliOptions.printUsage();
    exit(-1);
  }
}

Stream<String> _toLines(Stream<List<int>> source) =>
    source.transform(SYSTEM_ENCODING.decoder).transform(const LineSplitter());
