import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/source_gen/common/url_resolver.dart';
import 'package:angular2/src/source_gen/template_compiler/code_builder.dart';
import 'package:angular2/src/source_gen/template_compiler/template_processor.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

/// Generates `.template.dart` files to initialize the Angular2 system.
///
/// - Processes the input element using `findComponents`.
/// - Passes the resulting `NormalizedComponentWithViewDirectives` instance(s)
///   to the `TemplateCompiler` to generate compiled template(s) as a
///   `SourceModule`.
/// - [Eventually]Uses the resulting `NgDeps` object to generate code which
///   initializes the Angular2 reflective system.
class TemplateGenerator extends Generator {
  @override
  Future<String> generate(Element element, BuildStep buildStep) async {
    if (element is! LibraryElement) return null;
    var outputs = await processTemplates(element, buildStep);
    if (outputs == null) return _emptyNgDepsContents;
    return buildGeneratedCode(
        outputs, fileName(buildStep.input.id), element.name);
  }
}

final String _emptyNgDepsContents = prettyToSource(
    new MethodBuilder.returnVoid('initReflector').buildTopLevelAst());
