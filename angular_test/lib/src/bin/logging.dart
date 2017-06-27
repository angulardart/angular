// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:logging/logging.dart';

Logger _currentLogger;

IOSink _logFileIOSink;

final _green = new AnsiPen()..green();
final _red = new AnsiPen()..red();
final _yellow = new AnsiPen()..yellow();

void log(String message, {bool verbose: true}) {
  if (verbose) {
    _currentLogger.info(message);
  } else {
    _logFileIOSink.writeln(message);
  }
}

void success(String message, {bool verbose: true}) {
  if (verbose) {
    _currentLogger.info(_green(message));
  } else {
    _logFileIOSink.writeln(message);
  }
}

void warn(String message,
    {Object exception, StackTrace stack, bool verbose: true}) {
  if (verbose) {
    _currentLogger.warning(_yellow(message), exception, stack);
  } else {
    _logFileIOSink.writeln(message);
  }
}

void error(String message,
    {Object exception, StackTrace stack, bool verbose: true}) {
  if (verbose) {
    _currentLogger.severe(_red(message), exception, stack);
  } else {
    _logFileIOSink.writeln(message);
  }
}

/// Starts listening to a new logger and outputting it through `print`.
void initLogging(String name) {
  _currentLogger = new Logger(name)
    ..onRecord.forEach((message) => print(message.message.trim()));
}

void initLoggingForTest(String name, List<String> output) {
  _currentLogger = new Logger(name)
    ..onRecord.forEach((message) => output.add(message.message.trim()));
}

void initFileWriting(IOSink sink) {
  _logFileIOSink = sink;
}

Future closeIOSink() async {
  await _logFileIOSink?.done;
}
