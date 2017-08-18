/// @nodoc

import 'package:barback/barback.dart';
import 'package:build_barback/build_barback.dart';
import 'package:angular/source_gen.dart';
import 'package:angular/src/transform/asset_consumer/transformer.dart';
import 'package:angular/src/transform/common/eager_transformer_wrapper.dart';
import 'package:angular/src/transform/stylesheet_compiler/transformer.dart';
import 'package:angular_compiler/angular_compiler.dart';

/// Generates code to replace mirror use in AngularDart apps.
///
/// This transformer can be used along with others as a faster alternative to
/// the single AngularDart transformer.
///
/// See [the wiki][] for details.
///
/// [the wiki]: https://github.com/angular/angular/wiki/AngularDart-Transformer
class CodegenTransformer extends TransformerGroup {
  CodegenTransformer._(Iterable<Iterable> phases) : super(phases);

  factory CodegenTransformer(CompilerFlags flags) {
    Iterable<Iterable> phases = [
      [new AssetConsumer()],
      [new BuilderTransformer(new TemplatePlaceholderBuilder())],
      [
        new StylesheetCompiler(flags),
        new BuilderTransformer(createSourceGenTemplateCompiler(flags)),
      ],
    ];
    phases =
        phases.map((phase) => phase.map((t) => new EagerTransformerWrapper(t)));
    return new CodegenTransformer._(phases);
  }

  factory CodegenTransformer.asPlugin(BarbackSettings settings) {
    return new CodegenTransformer(
      new CompilerFlags.parseBarback(
        settings,
        defaultTo: new CompilerFlags(
          genDebugInfo: settings.mode == BarbackMode.DEBUG,
        ),
      ),
    );
  }
}
