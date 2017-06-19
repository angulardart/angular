import 'package:barback/barback.dart';
import 'package:build_barback/build_barback.dart';
import 'package:dart_style/dart_style.dart';

import '../../source_gen.dart';
import 'common/eager_transformer_wrapper.dart';
import 'common/formatter.dart' as formatter;
import 'common/options.dart';
import 'common/options_reader.dart';
import 'deferred_rewriter/transformer.dart';
import 'directive_metadata_linker/transformer.dart';
import 'directive_processor/transformer.dart';
import 'inliner_for_test/transformer.dart';
import 'reflection_remover/transformer.dart';
import 'stylesheet_compiler/transformer.dart';
import 'template_compiler/transformer.dart';

export 'common/options.dart';

/// Replaces Angular 2 mirror use with generated code.
class AngularTransformerGroup extends TransformerGroup {
  AngularTransformerGroup._(Iterable<Iterable> phases, {bool formatCode: false})
      : super(phases) {
    if (formatCode) {
      formatter.init(new DartFormatter());
    }
  }

  factory AngularTransformerGroup(TransformerOptions options) {
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
        [new BuilderTransformer(new TemplatePlaceholderBuilder())],
        [new ReflectionRemover(options)],
        [
          new DeferredRewriter(),
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
        [new DirectiveProcessor(options)],
        [new DirectiveMetadataLinker(options)],
        [new ReflectionRemover(options)],
        [
          new DeferredRewriter(),
          new StylesheetCompiler(options),
          new TemplateCompiler(options)
        ],
      ];
    }
    if (options.modeName == BarbackMode.RELEASE.name ||
        !options.lazyTransformers) {
      phases = phases
          .map((phase) => phase.map((t) => new EagerTransformerWrapper(t)));
    }
    return new AngularTransformerGroup._(phases,
        formatCode: options.formatCode);
  }

  factory AngularTransformerGroup.asPlugin(BarbackSettings settings) {
    return new AngularTransformerGroup(parseBarbackSettings(settings));
  }
}
