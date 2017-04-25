import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/source_gen/template_compiler/find_components.dart';
import 'package:build/build.dart';

class TestComponentExtractor implements Builder {
  final String _extension;

  const TestComponentExtractor(this._extension);

  Future<String> _generate(Element element) async {
    if (element == null) {
      return '';
    }
    var components = findComponents(element);
    if (components.isNotEmpty) {
      return const JsonEncoder.withIndent('  ').convert(components);
    }
    return '';
  }

  @override
  Future build(BuildStep buildStep) async {
    buildStep.writeAsString(
      buildStep.inputId.changeExtension(_extension),
      await _generate(
        (await buildStep.resolver).getLibrary(buildStep.inputId),
      ),
    );
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': [_extension]
      };
}
