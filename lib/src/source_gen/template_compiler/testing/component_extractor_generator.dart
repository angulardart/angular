import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/source_gen/template_compiler/find_components.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class TestComponentExtractor extends Generator {
  final JsonEncoder _encoder = const JsonEncoder.withIndent('  ');

  @override
  Future<String> generate(Element element, BuildStep buildStep) async {
    if (element is! LibraryElement) return null;
    var components = findComponents(element);
    if (components.isEmpty)
      return 'final String output = "No components found.";';
    var output = _encoder.convert(components);
    return 'final String output = """$output""";';
  }
}
