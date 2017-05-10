import 'package:angular2/src/transform/common/names.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'template_compiler/generator.dart';
import 'template_compiler/generator_options.dart';

export 'template_compiler/generator_options.dart';

Builder createSourceGenTemplateCompiler(GeneratorOptions options) =>
    new GeneratorBuilder([new TemplateGenerator(options)],
        generatedExtension: TEMPLATE_EXTENSION, isStandalone: true);
