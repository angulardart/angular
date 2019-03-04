import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart'
    show AnalysisDriver, AnalysisDriverScheduler;
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mock_sdk.dart';

/// Base shared functionality for tests that rely on dart analysis
class AnalyzerTestBase {
  MemoryResourceProvider resourceProvider;

  DartSdk sdk;
  AnalysisDriver dartDriver;
  AnalysisDriverScheduler scheduler;
  ByteStore byteStore;
  SourceFactory sourceFactory;

  GatheringErrorListener errorListener;

  /// Assert that the [errCode] is reported for [code], highlighting the
  /// [snippet].
  ///
  /// Optionally, expect [additionalErrorCodes] to appear at any location.
  void assertErrorInCodeAtPosition(
      ErrorCode errCode, String code, String snippet,
      {List<ErrorCode> additionalErrorCodes}) {
    final snippetIndex = code.indexOf(snippet);
    expect(snippetIndex, greaterThan(-1),
        reason: 'Error in test: snippet $snippet not part of code $code');
    final expectedErrorCodes = (additionalErrorCodes ?? <ErrorCode>[])
      ..add(errCode);
    errorListener.assertErrorsWithCodes(expectedErrorCodes);
    final error =
        errorListener.errors.singleWhere((e) => e.errorCode == errCode);
    expect(error.offset, snippetIndex);
    expect(error.length, snippet.length);
  }

  void fillErrorListener(List<AnalysisError> errors) {
    errorListener.addAll(errors);
  }

  Source newSource(String path, [String content = '']) {
    final file = resourceProvider.newFile(path, content);
    final source = file.createSource();
    dartDriver.addFile(path);
    return source;
  }

  void setUp() {
    final logger = new PerformanceLog(new StringBuffer());
    byteStore = new MemoryByteStore();

    scheduler = new AnalysisDriverScheduler(logger)..start();
    resourceProvider = new MemoryResourceProvider();

    sdk = new MockSdk(resourceProvider: resourceProvider);
    final packageMap = <String, List<Folder>>{
      'angular2': [resourceProvider.getFolder('/angular2')],
      'angular': [resourceProvider.getFolder('/angular')],
      'test_package': [resourceProvider.getFolder('/')],
    };
    final packageResolver =
        new PackageMapUriResolver(resourceProvider, packageMap);
    sourceFactory = new SourceFactory([
      new DartUriResolver(sdk),
      packageResolver,
      new ResourceUriResolver(resourceProvider)
    ]);

    dartDriver = new AnalysisDriver(
        new AnalysisDriverScheduler(logger)..start(),
        logger,
        resourceProvider,
        byteStore,
        new FileContentOverlay(),
        null,
        sourceFactory,
        new AnalysisOptionsImpl());
    errorListener = new GatheringErrorListener();
  }
}

/// Instances of the class [GatheringErrorListener] implement an error listener
/// that collects all of the errors passed to it for later examination.
class GatheringErrorListener implements AnalysisErrorListener {
  /// A list containing the errors that were collected.
  final errors = <AnalysisError>[];

  /// Add all of the given errors to this listener.
  void addAll(List<AnalysisError> errors) {
    for (final error in errors) {
      onError(error);
    }
  }

  /// Assert that the number of errors that have been gathered matches the number
  /// of errors that are given and that they have the expected error codes.
  ///
  /// The order in which the errors were gathered is ignored.
  void assertErrorsWithCodes(
      [List<ErrorCode> expectedErrorCodes = const <ErrorCode>[]]) {
    final buffer = new StringBuffer();
    //
    // Verify that the expected error codes have a non-empty message.
    //
    for (final errorCode in expectedErrorCodes) {
      expect(errorCode.message.isEmpty, isFalse,
          reason: "Empty error code message");
    }
    //
    // Compute the expected number of each type of error.
    //
    final expectedCounts = <ErrorCode, int>{};
    for (final code in expectedErrorCodes) {
      var count = expectedCounts[code];
      if (count == null) {
        count = 1;
      } else {
        count = count + 1;
      }
      expectedCounts[code] = count;
    }
    //
    // Compute the actual number of each type of error.
    //
    final errorsByCode = <ErrorCode, List<AnalysisError>>{};
    for (final error in errors) {
      final code = error.errorCode;
      var list = errorsByCode[code];
      if (list == null) {
        list = <AnalysisError>[];
        errorsByCode[code] = list;
      }
      list.add(error);
    }
    //
    // Compare the expected and actual number of each type of error.
    //
    expectedCounts.forEach((code, expectedCount) {
      int actualCount;
      final list = errorsByCode.remove(code);
      if (list == null) {
        actualCount = 0;
      } else {
        actualCount = list.length;
      }
      if (actualCount != expectedCount) {
        if (buffer.length == 0) {
          buffer.write("Expected ");
        } else {
          buffer.write("; ");
        }
        buffer
          ..write(expectedCount)
          ..write(" errors of type ")
          ..write(code.uniqueName)
          ..write(", found ")
          ..write(actualCount);
      }
    });
    //
    // Check that there are no more errors in the actual-errors map,
    // otherwise record message.
    //
    errorsByCode.forEach((code, actualErrors) {
      final actualCount = actualErrors.length;
      if (buffer.isEmpty) {
        buffer.write("Expected ");
      } else {
        buffer.write("; ");
      }
      buffer
        ..write("0 errors of type ")
        ..write(code.uniqueName)
        ..write(", found ")
        ..write(actualCount)
        ..write(" (");
      for (var i = 0; i < actualErrors.length; i++) {
        final error = actualErrors[i];
        if (i > 0) {
          buffer.write(", ");
        }
        buffer.write(error.offset);
      }
      buffer.write(")");
    });
    if (buffer.length > 0) {
      fail(buffer.toString());
    }
  }

  /// Assert that no errors have been gathered.
  void assertNoErrors() {
    assertErrorsWithCodes();
  }

  @override
  void onError(AnalysisError error) {
    errors.add(error);
  }
}

class MockSource extends Mock implements Source {}
