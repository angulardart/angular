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
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

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
    final logger = PerformanceLog(StringBuffer());
    byteStore = MemoryByteStore();

    scheduler = AnalysisDriverScheduler(logger)..start();
    resourceProvider = MemoryResourceProvider();

    sdk = MockSdk(resourceProvider: resourceProvider);
    final packageMap = <String, List<Folder>>{
      'angular': [resourceProvider.getFolder('/angular')],
      'test_package': [resourceProvider.getFolder('/')],
    };
    final packageResolver = PackageMapUriResolver(resourceProvider, packageMap);
    sourceFactory = SourceFactory([
      DartUriResolver(sdk),
      packageResolver,
      ResourceUriResolver(resourceProvider)
    ]);

    dartDriver = AnalysisDriver(
        AnalysisDriverScheduler(logger)..start(),
        logger,
        resourceProvider,
        byteStore,
        FileContentOverlay(),
        null,
        sourceFactory,
        AnalysisOptionsImpl());
    errorListener = GatheringErrorListener();
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

  /// Assert that the number of errors that have been gathered matches the
  /// number of errors that are given and that they have the expected error
  /// codes.
  ///
  /// The order in which the errors were gathered is ignored.
  void assertErrorsWithCodes(
      [List<ErrorCode> expectedErrorCodes = const <ErrorCode>[]]) {
    final buffer = StringBuffer();

    _expectNonEmptyMessages(expectedErrorCodes);

    final expectedCounts = _countExpectedErrorCodes(expectedErrorCodes);
    final errorsByCode = _groupErrorsByCode();

    _checkExpectedErrorsArePresent(expectedCounts, errorsByCode, buffer);
    _checkNoExtraErrorsArePresent(expectedCounts, errorsByCode, buffer);

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

  void _checkExpectedErrorsArePresent(
      Map<ErrorCode, int> expectedCounts,
      Map<ErrorCode, List<AnalysisError>> errorsByCode,
      StringBuffer errorMessageBuffer) {
    expectedCounts.forEach((code, expectedCount) {
      final list = errorsByCode.remove(code);
      final actualCount = list?.length ?? 0;

      if (actualCount != expectedCount) {
        if (errorMessageBuffer.isEmpty) {
          errorMessageBuffer.write("Expected ");
        } else {
          errorMessageBuffer.write("; ");
        }
        errorMessageBuffer
          ..write(expectedCount)
          ..write(" errors of type ")
          ..write(code.uniqueName)
          ..write(", found ")
          ..write(actualCount);
      }
    });
  }

  void _checkNoExtraErrorsArePresent(
      Map<ErrorCode, int> expectedCounts,
      Map<ErrorCode, List<AnalysisError>> errorsByCode,
      StringBuffer errorMessageBuffer) {
    errorsByCode.forEach((code, actualErrors) {
      if (errorMessageBuffer.isEmpty) {
        errorMessageBuffer.write("Expected ");
      } else {
        errorMessageBuffer.write("; ");
      }
      errorMessageBuffer
        ..write("0 errors of type ")
        ..write(code.uniqueName)
        ..write(", found ")
        ..write(actualErrors.length)
        ..write(" (")
        ..write(actualErrors.map((error) => error.offset).join(', '))
        ..write(")");
    });
  }

  Map<ErrorCode, int> _countExpectedErrorCodes(
      List<ErrorCode> expectedErrorCodes) {
    final expectedCounts = <ErrorCode, int>{};
    for (final code in expectedErrorCodes) {
      expectedCounts.putIfAbsent(code, () => 0);
      expectedCounts[code]++;
    }

    return expectedCounts;
  }

  void _expectNonEmptyMessages(List<ErrorCode> expectedErrorCodes) {
    for (final errorCode in expectedErrorCodes) {
      expect(errorCode.message.isEmpty, isFalse,
          reason: "Empty error code message");
    }
  }

  Map<ErrorCode, List<AnalysisError>> _groupErrorsByCode() {
    final errorsByCode = <ErrorCode, List<AnalysisError>>{};
    for (final error in errors) {
      errorsByCode.putIfAbsent(error.errorCode, () => []).add(error);
    }

    return errorsByCode;
  }
}

class MockSource extends Mock implements Source {}
