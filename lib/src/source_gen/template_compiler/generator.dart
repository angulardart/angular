import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/compiler/config.dart';
import 'package:angular2/src/compiler/logging.dart' show loggerKey;
import 'package:angular2/src/source_gen/common/url_resolver.dart';
import 'package:angular2/src/transform/common/options.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

import 'code_builder.dart';
import 'generator_options.dart';
import 'template_processor.dart';

/// Generates `.template.dart` files to initialize the Angular2 system.
///
/// - Processes the input element using `findComponents`.
/// - Passes the resulting `NormalizedComponentWithViewDirectives` instance(s)
///   to the `TemplateCompiler` to generate compiled template(s) as a
///   `SourceModule`.
/// - [Eventually]Uses the resulting `NgDeps` object to generate code which
///   initializes the Angular2 reflective system.
class TemplateGenerator extends Generator {
  final GeneratorOptions _options;

  const TemplateGenerator(this._options);

  @override
  Future<String> generate(Element element, BuildStep buildStep) async {
    if (element is! LibraryElement) return null;
    return runZoned(() async {
      var config = new CompilerConfig(
          genDebugInfo: _options.codegenMode == CODEGEN_DEBUG_MODE,
          logBindingUpdate: _options.reflectPropertiesAsAttributes,
          useLegacyStyleEncapsulation: _options.useLegacyStyleEncapsulation);
      var outputs = await processTemplates(element, buildStep, config);
      if (outputs == null) return _emptyNgDepsContents;
      return buildGeneratedCode(
        outputs,
        fileName(buildStep.inputId),
        element.name,
      );
    }, zoneSpecification: new ZoneSpecification(
      print: (_, __, ___, message) {
        log.warning('(via print) $message');
      },
    ), zoneValues: {
      'inSourceGen': true,
      loggerKey: log, // [Logger] of the current build step.
    });
  }
}

final String _emptyNgDepsContents = prettyToSource(
    new MethodBuilder.returnVoid('initReflector').buildTopLevelAst());
