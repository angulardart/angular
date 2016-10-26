import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/source_gen/template_compiler/find_components.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

const testFiles = 'test/source_gen/template_compiler/test_files';

class TestComponentExtractor extends Generator {
  final JsonEncoder _encoder = const JsonEncoder.withIndent('  ');

  @override
  Future<String> generate(Element element, BuildStep buildStep) async {
    if (element is! LibraryElement) return null;
    var components = await findComponents(buildStep, element);
    if (components.isEmpty) return null;
    return 'final String output = """${_encoder.convert(components.map((c) => c.toJson()).toList())}""";';
  }
}

GeneratorBuilder testComponentExtractor({String extension: '.ng_summary'}) =>
    new GeneratorBuilder([new TestComponentExtractor()],
        generatedExtension: extension, isStandalone: true);
