@TestOn('vm')
import 'package:analyzer/analyzer.dart';
import 'package:angular2/src/transform/directive_processor/deferred_import_validator.dart';
import 'package:angular2/src/transform/common/zone.dart' as zone;
import 'package:barback/barback.dart';
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';

void main() {
  group('Check deferred import initialization', () {
    runTest('warns if deferred imports aren\'t initialized',
        invalidReflectiveCode, true);

    runTest('warns if the .template.dart file isn\'t imported', invalidImport,
        true);

    runTest('Doesn\'t warn with @SkipAngularInitCheck()',
        invalidCodeWithSkipAnnotation, false);

    runTest('Doesn\'t warn if properly initialized using async/await',
        validAsyncAwaitCode, false);

    runTest('Doesn\'t warn if properly initialized using Future.then',
        validFutureThenCode, false);
  });
}

void runTest(String name, String code, bool expectWarning) {
  test(name, () async {
    var logger = new _CapturingLogger();
    await zone.exec(() {
      var parsedCode = parseCompilationUnit(code);
      checkDeferredImportInitialization(code, parsedCode);
    }, log: logger);
    var hasWarning = logger.entries.any((e) =>
        e.level == LogLevel.WARNING && e.message.contains("initReflector"));
    if (expectWarning) {
      expect(hasWarning, isTrue,
          reason: 'Expected a warning for uninitialized deferred imports.');
    } else {
      expect(hasWarning, isFalse,
          reason:
              'Didn\'t expect a warning about unitialized deferred imports');
    }
  });
}

const invalidReflectiveCode = '''
import 'dart:async';
import 'foo.dart' deferred as foo;

Future loadFoo() => foo.loadLibrary();
''';

const invalidImport = '''
import 'dart:async';
import 'foo.dart' deferred as foo;

Future loadFoo() async {
  await foo.loadLibrary();
  foo.initReflector();
}
''';

const invalidCodeWithSkipAnnotation = '''
import 'dart:async';
import 'package:angular2/angular2.dart';
@SkipAngularInitCheck()
import 'foo.dart' deferred as foo;

Future loadFoo() => foo.loadLibrary();
''';

const validAsyncAwaitCode = '''
import 'dart:async';
import 'foo.template.dart' deferred as foo;

Future loadFoo() async {
  await foo.loadLibrary();
  foo.initReflector();
}
''';

const validFutureThenCode = '''
import 'dart:async';
import 'foo.template.dart' deferred as foo;

Future loadFoo() {
  return foo.loadLibrary().then((_) {
    foo.initReflector();
  });
}
''';

class _CapturingLogger implements TransformLogger {
  final List<LogEntry> entries = [];

  void fine(String message, {AssetId asset, SourceSpan span}) {
    entries.add(new LogEntry(null, asset, LogLevel.FINE, message, span));
  }

  void info(String message, {AssetId asset, SourceSpan span}) {
    entries.add(new LogEntry(null, asset, LogLevel.INFO, message, span));
  }

  void warning(String message, {AssetId asset, SourceSpan span}) {
    entries.add(new LogEntry(null, asset, LogLevel.WARNING, message, span));
  }

  void error(String message, {AssetId asset, SourceSpan span}) {
    entries.add(new LogEntry(null, asset, LogLevel.ERROR, message, span));
  }
}
