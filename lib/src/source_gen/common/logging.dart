import 'dart:async';

import 'package:build/build.dart';
import 'package:logging/logging.dart';

/// Writes a log entry at `LogLevel.FINE` granularity with the time taken by
/// `asyncOperation`.
///
/// Returns the result of executing `asyncOperation`.
Future<T> logElapsedAsync<T>(Future<T> asyncOperation(),
    {String operationName: 'unknown', AssetId assetId, Logger log}) async {
  final timer = new Stopwatch()..start();
  final result = await asyncOperation();
  timer.stop();
  _logElapsed(timer, operationName, assetId, log);
  return result;
}

/// Writes a log entry at `LogLevel.FINE` granularity with the time taken by
/// `operation`.
///
/// Returns the result of executing `operation`.
T logElapsedSync<T>(T operation(),
    {String operationName: 'unknown', AssetId assetId, Logger log}) {
  final timer = new Stopwatch()..start();
  final result = operation();
  timer.stop();
  _logElapsed(timer, operationName, assetId, log);
  return result;
}

/// Logs the time since `timer` was started.
void _logElapsed(
    Stopwatch timer, String operationName, AssetId assetId, Logger log) {
  final buf =
      new StringBuffer('[$operationName] took ${timer.elapsedMilliseconds} ms');
  if (assetId != null) {
    buf.write(' on $assetId');
  }
  log ??= new Logger('');
  log.fine(buf.toString());
}
