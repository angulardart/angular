library angular.transform.codegen.dart;

import 'package:barback/barback.dart';
import 'package:build_barback/build_barback.dart';
import 'package:dart_style/dart_style.dart';
import 'package:angular/source_gen.dart';
import 'package:angular/src/transform/asset_consumer/transformer.dart';
import 'package:angular/src/transform/common/eager_transformer_wrapper.dart';
import 'package:angular/src/transform/common/formatter.dart'
    as formatter;
import 'package:angular/src/transform/common/options.dart';
import 'package:angular/src/transform/common/options_reader.dart';
import 'package:angular/src/transform/directive_metadata_linker/transformer.dart';
import 'package:angular/src/transform/directive_processor/transformer.dart';
import 'package:angular/src/transform/inliner_for_test/transformer.dart';
import 'package:angular/src/transform/stylesheet_compiler/transformer.dart';
import 'package:angular/src/transform/template_compiler/transformer.dart';

export 'package:angular/src/transform/common/options.dart';

/// Generates code to replace mirror use in Angular apps.
///
/// This transformer can be used along with others as a faster alternative to
/// the single angular transformer.
///
/// See [the wiki][] for details.
///
/// [the wiki]: https://github.com/angular/angular/wiki/Angular-2-Dart-Transformer
class CodegenTransformer extends TransformerGroup {
  CodegenTransformer._(Iterable<Iterable> phases, {bool formatCode: false})
      : super(phases) {
    if (formatCode) {
      formatter.init(new DartFormatter());
    }
  }

  factory CodegenTransformer(TransformerOptions options) {
    Iterable<Iterable> phases;
    if (options.useAnalyzer) {
      if (options.platformDirectives?.isNotEmpty == true ||
          options.platformPipes?.isNotEmpty == true) {
        throw new UnsupportedError(''
            'Transformer option "$USE_ANALYZER" cannot be used alongside '
            '"$PLATFORM_DIRECTIVES" or "$PLATFORM_PIPES", as the new '
            'compiler needs to be able to resolve all directives and pipes '
            'using the Dart analyzer. See https://goo.gl/68VhMa for details.');
      }
      phases = [
        [new AssetConsumer()],
        [new BuilderTransformer(new TemplatePlaceholderBuilder())],
        [
          new StylesheetCompiler(options),
          new BuilderTransformer(createSourceGenTemplateCompiler(
              new GeneratorOptions(
                  codegenMode: options.codegenMode,
                  useLegacyStyleEncapsulation:
                      options.useLegacyStyleEncapsulation)))
        ]
      ];
    } else if (options.inlineViews) {
      phases = [
        [new InlinerForTest(options)]
      ];
    } else {
      phases = [
        [new AssetConsumer()],
        [new DirectiveProcessor(options)],
        [new DirectiveMetadataLinker(options)],
        [
          new StylesheetCompiler(options),
          new TemplateCompiler(options),
        ],
      ];
    }
    if (options.modeName == BarbackMode.RELEASE.name ||
        !options.lazyTransformers) {
      phases = phases
          .map((phase) => phase.map((t) => new EagerTransformerWrapper(t)));
    }
    return new CodegenTransformer._(phases, formatCode: options.formatCode);
  }

  factory CodegenTransformer.asPlugin(BarbackSettings settings) {
    return new CodegenTransformer(parseBarbackSettings(settings));
  }
}
