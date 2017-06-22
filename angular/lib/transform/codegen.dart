import 'package:barback/barback.dart';
import 'package:build_barback/build_barback.dart';
import 'package:dart_style/dart_style.dart';
import 'package:angular/source_gen.dart';
import 'package:angular/src/transform/asset_consumer/transformer.dart';
import 'package:angular/src/transform/common/eager_transformer_wrapper.dart';
import 'package:angular/src/transform/common/formatter.dart' as formatter;
import 'package:angular/src/transform/common/options.dart';
import 'package:angular/src/transform/common/options_reader.dart';
import 'package:angular/src/transform/stylesheet_compiler/transformer.dart';

export 'package:angular/src/transform/common/options.dart';

/// Generates code to replace mirror use in AngularDart apps.
///
/// This transformer can be used along with others as a faster alternative to
/// the single AngularDart transformer.
///
/// See [the wiki][] for details.
///
/// [the wiki]: https://github.com/angular/angular/wiki/AngularDart-Transformer
class CodegenTransformer extends TransformerGroup {
  CodegenTransformer._(Iterable<Iterable> phases, {bool formatCode: false})
      : super(phases) {
    if (formatCode) {
      formatter.init(new DartFormatter());
    }
  }

  factory CodegenTransformer(TransformerOptions options) {
    Iterable<Iterable> phases;
    if (!options.useAnalyzer) {
      throw new UnsupportedError('Option $USE_ANALYZER is required.');
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
