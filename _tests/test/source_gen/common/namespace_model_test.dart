@TestOn('vm')
import 'package:code_builder/testing.dart';
import 'package:test/test.dart';
import 'package:angular/src/source_gen/common/namespace_model.dart';

void main() {
  group('Namespace model', () {
    group('import', () {
      test('simple import', () {
        expect(new ImportModel(uri: 'foo').asBuilder,
            equalsSource("import 'foo';\n"));
      });
      test('has prefix', () {
        expect(new ImportModel(uri: 'foo', prefix: 'bar').asBuilder,
            equalsSource("import 'foo' as bar;\n"));
      });
      test('is deferred', () {
        expect(
            new ImportModel(uri: 'foo', isDeferred: true, prefix: 'bar')
                .asBuilder,
            equalsSource("import 'foo' deferred as bar;\n"));
      });
      test('has show clause', () {
        expect(
            new ImportModel(uri: 'foo', showCombinators: ['bar, baz'])
                .asBuilder,
            equalsSource("import 'foo' show bar, baz;\n"));
      });
      test('has hide clause', () {
        expect(
            new ImportModel(uri: 'foo', hideCombinators: ['bar, baz'])
                .asBuilder,
            equalsSource("import 'foo' hide bar, baz;\n"));
      });
      test('complex import', () {
        expect(
            new ImportModel(
                uri: 'foo',
                prefix: 'bar',
                isDeferred: true,
                showCombinators: ['fiz'],
                hideCombinators: ['baz']).asBuilder,
            equalsSource("import 'foo' deferred as bar show fiz hide baz;\n"));
      });
    });

    group('export', () {
      test('simple export', () {
        expect(new ExportModel(uri: 'foo').asBuilder,
            equalsSource("export 'foo';\n"));
      });
      test('has show clause', () {
        expect(
            new ExportModel(uri: 'foo', showCombinators: ['bar, baz'])
                .asBuilder,
            equalsSource("export 'foo' show bar, baz;\n"));
      });
      test('has hide clause', () {
        expect(
            new ExportModel(uri: 'foo', hideCombinators: ['bar, baz'])
                .asBuilder,
            equalsSource("export 'foo' hide bar, baz;\n"));
      });
      test('complex export', () {
        expect(
            new ExportModel(
                uri: 'foo',
                showCombinators: ['fiz'],
                hideCombinators: ['baz']).asBuilder,
            equalsSource("export 'foo' show fiz hide baz;\n"));
      });
    });
  });
}
