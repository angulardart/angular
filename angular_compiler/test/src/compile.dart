import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:angular_compiler/cli.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'resolve.dart';

/// Executes the [run] function, and expects no warnings or errors logged.
///
/// ```dart
/// test('should compile fine', () {
///   compilesNormally(() {
///     runSomeCodeThatMightLogErrors();
///   });
/// });
/// ```
///
/// Returns the result of the provided function.
Future<T> runsNormally<T>(Future<T> Function() run) {
  return runsExpecting(run, errors: isEmpty, warnings: isEmpty);
}

/// Executes the [run] function with the result of analyzing [source].
///
/// Similar to [runNormally] as it verifies no warnings or errors.
Future<void> compilesNormally(
  String source,
  Future<void> Function(LibraryElement) run,
) {
  return resolveLibrary(source).then((lib) => runsNormally(() => run(lib)));
}

Future<T> _recordLogs<T>(
  Future<T> Function() run,
  void Function(List<LogRecord>) onLog,
) {
  final logger = Logger('_recordLogs');
  final records = <LogRecord>[];
  final subscription = logger.onRecord.listen(records.add);
  return scopeLogAsync(() async {
    return runBuildZoned(
      run,
      zoneValues: {
        CompileContext: CompileContext(),
      },
    ).then((result) {
      subscription.cancel();
      onLog(records);
      return result;
    });
  }, logger);
}

/// Executes the [run] function with the result of analyzing [source].
///
/// Similar to [runsExpecting] as it verifies the expected warnings or errors.
Future<void> compilesExpecting(
  String source,
  Future<void> Function(LibraryElement) run, {
  Object /* Matcher | List<Matcher> | List<String> */ errors,
  Object /* Matcher | List<Matcher> | List<String> */ warnings,
}) {
  return resolveLibrary(source).then((lib) {
    return runsExpecting(
      () => run(lib),
      errors: errors,
      warnings: warnings,
    );
  });
}

/// Executes the [run] function, and expects specified [errors] or [warnings].
Future<T> runsExpecting<T>(
  Future<T> Function() run, {
  Object /* Matcher | List<Matcher> | List<String> */ errors,
  Object /* Matcher | List<Matcher> | List<String> */ warnings,
}) {
  errors ??= anything;
  warnings ??= anything;
  return _recordLogs(run, (records) {
    expect(
      records.where((r) => r.level == Level.SEVERE).map((r) => r.message),
      errors,
    );
    expect(
      records.where((r) => r.level == Level.WARNING).map((r) => r.message),
      warnings,
    );
  });
}
