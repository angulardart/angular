import 'dart:async';

import 'package:build/build.dart';
import 'package:logging/logging.dart';

import 'zone.dart' as zone show log;

/// The [Logger] for the current {@link Zone}.
Logger get log {
  var log = zone.log;
  return log != null ? log : new Logger('');
}

/// Writes a log entry at `LogLevel.FINE` granularity with the time taken by
/// `asyncOperation`.
///
/// Returns the result of executing `asyncOperation`.
Future<dynamic/*<T>*/ > logElapsedAsync/*<T>*/(
    Future<dynamic/*<T>*/ > asyncOperation(),
    {String operationName: 'unknown',
    AssetId assetId}) async {
  final timer = new Stopwatch()..start();
  final result = await asyncOperation();
  timer.stop();
  _logElapsed(timer, operationName, assetId);
  return result;
}

/// Writes a log entry at `LogLevel.FINE` granularity with the time taken by
/// `operation`.
///
/// Returns the result of executing `operation`.
dynamic logElapsedSync(dynamic operation(),
    {String operationName: 'unknown', AssetId assetId}) {
  final timer = new Stopwatch()..start();
  final result = operation();
  timer.stop();
  _logElapsed(timer, operationName, assetId);
  return result;
}

/// Logs the time since `timer` was started.
void _logElapsed(Stopwatch timer, String operationName, AssetId assetId) {
  final buf =
      new StringBuffer('[$operationName] took ${timer.elapsedMilliseconds} ms');
  if (assetId != null) {
    buf.write(' on $assetId');
  }
  log.fine(buf.toString());
}
