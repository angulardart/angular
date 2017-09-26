import 'package:args/args.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular/source_gen.dart';
import 'package:angular_compiler/angular_compiler.dart';

const String TEMPLATE_EXTENSION_PARAM = 'template_extension';
const String CODEGEN_MODE_PARAM = 'codegen_mode';

Builder templateBuilder(List<String> args) {
  final argResults = _argParser.parse(args);
  final compilerFlags = new CompilerFlags(
    genDebugInfo: argResults[CODEGEN_MODE_PARAM] == 'debug',
  );
  if (argResults[CODEGEN_MODE_PARAM] == 'outline') {
    return new TemplateOutliner(compilerFlags,
        extension: argResults[TEMPLATE_EXTENSION_PARAM]);
  }
  return new LibraryBuilder(new TemplateGenerator(compilerFlags),
      generatedExtension: argResults[TEMPLATE_EXTENSION_PARAM]);
}

Builder templatePlaceholderBuilder(_) => const TemplatePlaceholderBuilder();

final _argParser = new ArgParser()
  ..addOption(CODEGEN_MODE_PARAM,
      help: 'What mode to run the code generator in. Either release or debug.')
  ..addOption(TEMPLATE_EXTENSION_PARAM,
      help: 'Generated template extension.', defaultsTo: '.template.dart');
