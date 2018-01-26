import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular/source_gen.dart';
import 'package:angular_compiler/angular_compiler.dart';

const String TEMPLATE_EXTENSION_PARAM = 'template_extension';
const String CODEGEN_MODE_PARAM = 'codegen_mode';

Builder templateBuilder(BuilderOptions options) {
  final compilerFlags = new CompilerFlags(
    useAstPkg: true,
    genDebugInfo: options.config[CODEGEN_MODE_PARAM] == 'debug',
  );
  if (options.config[CODEGEN_MODE_PARAM] == 'outline') {
    return new TemplateOutliner(compilerFlags,
        extension: options.config[TEMPLATE_EXTENSION_PARAM]);
  }
  return new LibraryBuilder(new TemplateGenerator(compilerFlags),
      generatedExtension: options.config[TEMPLATE_EXTENSION_PARAM]);
}

Builder templatePlaceholderBuilder(_) => const TemplatePlaceholderBuilder();
