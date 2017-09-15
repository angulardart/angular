import 'dart:async';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular/src/compiler/logging.dart' show loggerKey;
import 'package:angular/src/source_gen/common/url_resolver.dart';
import 'package:angular_compiler/angular_compiler.dart';

import 'code_builder.dart';
import 'template_processor.dart';

/// Generates `.template.dart` files to initialize the Angular2 system.
///
/// - Processes the input element using `findComponentsAndDirectives`.
/// - Passes the resulting `NormalizedComponentWithViewDirectives` instance(s)
///   to the `TemplateCompiler` to generate compiled template(s) as a
///   `SourceModule`.
/// - [Eventually]Uses the resulting `NgDeps` object to generate code which
///   initializes the Angular2 reflective system.
class TemplateGenerator extends Generator {
  final CompilerFlags _flags;

  const TemplateGenerator(this._flags);

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    return runZoned(() async {
      var outputs = await processTemplates(library.element, buildStep, _flags);
      if (outputs == null) return 'void initReflector() {}';
      return buildGeneratedCode(
        library.element,
        outputs,
        fileName(buildStep.inputId),
        library.element.name,
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

/// Generates an empty `.ng_placeholder` file which is used as a signal to later
/// builders which files will eventually get `.template.dart` generated.
class TemplatePlaceholderBuilder implements Builder {
  const TemplatePlaceholderBuilder();

  @override
  final buildExtensions = const {
    '.dart': const ['.ng_placeholder']
  };

  @override
  Future build(BuildStep buildStep) {
    buildStep.writeAsString(
        buildStep.inputId.changeExtension('.ng_placeholder'), '');
    return new Future.value(null);
  }
}
