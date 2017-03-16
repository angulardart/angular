@TestOn('browser && !js')
library angular2.test.public_api_test;

import 'package:test/test.dart';

import 'symbol_inspector/symbol_inspector.dart';
import 'public_apis.dart';

void main() {
  group('Public API check', () {
    publicLibraries.forEach((lib, expected) {
      if (expected == null) {
        // Not storing expected libraries yet – TODO
        return;
      }
      test('for ${lib} should fail when it changes unexpectedly', () {
        var symbols = getSymbolsFromLibrary(getLibrary(lib));
        expect(diff(symbols, expected), isEmpty);
      });
    });
  });
}

List<String> diff(Iterable<String> actual, Iterable<String> expected) =>
    <String>[]
      ..addAll(actual.where((i) => !expected.contains(i)).map((s) => '+$s'))
      ..addAll(expected.where((i) => !actual.contains(i)).map((s) => '-$s'))
      ..sort();
