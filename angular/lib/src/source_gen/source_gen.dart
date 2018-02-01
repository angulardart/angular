import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular_compiler/angular_compiler.dart';

import 'common/names.dart';
import 'stylesheet_compiler/builder.dart';
import 'template_compiler/generator.dart';

export 'template_compiler/generator.dart'
    show TemplatePlaceholderBuilder, TemplateGenerator;

const _outlineOnlyFlag = 'outline-only';

Builder templateCompiler(BuilderOptions options) {
  final config = <String, dynamic>{}..addAll(options.config);
  final outlineOnly = config.remove(_outlineOnlyFlag) != null;
  var flags = new CompilerFlags.parseRaw(
    config,
    const CompilerFlags(
      genDebugInfo: false,
      useLegacyStyleEncapsulation: true,
      useAstPkg: true,
    ),
    severity: Level.SEVERE,
  );

  if (outlineOnly) {
    return new TemplateOutliner(flags);
  } else {
    return createSourceGenTemplateCompiler(flags);
  }
}

Builder templatePlaceholderBuilder(_) => const TemplatePlaceholderBuilder();

Builder stylesheetCompiler(BuilderOptions options) {
  final flags = new CompilerFlags.parseRaw(
    options.config,
    const CompilerFlags(genDebugInfo: false),
  );
  return new StylesheetCompiler(flags);
}

Builder createSourceGenTemplateCompiler(CompilerFlags flags) =>
    new LibraryBuilder(new TemplateGenerator(flags),
        formatOutput: (String original) => _formatter.format(original),
        generatedExtension: TEMPLATE_EXTENSION);

// Note: Use an absurdly long line width in order to speed up the formatter. We
// still get a lot of other formatting, such as forced line breaks (after
// semicolons for instance), spaces in argument lists, etc.
final _formatter = new DartFormatter(pageWidth: 1000000);
