import 'package:angular2/src/transform/common/names.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

import 'template_compiler/generator.dart';
import 'template_compiler/generator_options.dart';

export 'template_compiler/generator.dart' show TemplatePlaceholderBuilder;
export 'template_compiler/generator_options.dart';

Builder createSourceGenTemplateCompiler(GeneratorOptions options) =>
    new GeneratorBuilder([new TemplateGenerator(options)],
        formatOutput: (String original) => _formatter.format(original),
        generatedExtension: TEMPLATE_EXTENSION,
        isStandalone: true);

// Note: Use an absurdly long line width in order to speed up the formatter. We
// still get a lot of other formatting, such as forced line breaks (after
// semicolons for instance), spaces in argument lists, etc.
final _formatter = new DartFormatter(pageWidth: 1000000);
