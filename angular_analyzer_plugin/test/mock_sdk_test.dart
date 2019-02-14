import 'dart:async';

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analyzer_base.dart';
import 'mock_sdk.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MockSdkTest);
  });
}

@reflectiveTest
class MockSdkTest extends AnalyzerTestBase {
  // ignore: non_constant_identifier_names
  Future test_futureOr() async {
    final dartResult =
        await dartDriver.getResult('$sdkRoot/lib/async/async.dart');
    expect(dartResult.errors, isEmpty);
    expect(
        dartResult.libraryElement.exportNamespace.get('FutureOr'), isNotNull);
    expect(
        dartResult.libraryElement.context.typeProvider.futureOrType, isNotNull);
  }
}
