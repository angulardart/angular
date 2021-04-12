// @dart=2.9

/// Configuration for using `package:build`-compatible build systems.
///
/// See:
/// * [build_runner](https://pub.dev/packages/build_runner)
/// * [_bazel_codegen](https://pub.dev/packages/_bazel_codegen)
///
/// This library is **not** intended to be imported by typical end-users unless
/// you are creating a custom compilation pipeline. See documentation for
/// details, and `build.yaml` for how these builders are configured by default.
library angular.builder;

import 'package:build/build.dart';
import 'package:angular_compiler/v1/angular_compiler.dart';
import 'package:angular_compiler/v1/cli.dart';
import 'package:angular_compiler/v1/src/compiler/stylesheet_compiler/builder.dart';
import 'package:angular_compiler/v1/src/source_gen/template_compiler/generator.dart';

/// An option to generate a lighter-weight output for complex build systems.
///
/// The "outline" variants of `.template.dart` files do not have valid function
/// bodies, and are used as a sort of API skeleton for tooling, deferring the
/// actual generation of `.template.dart` off the critical path of a large
/// build.
const _useTemplateOutlinesInstead = 'outline-only';

/// Default build flags that are merged into provided configuration.
const _defaultFlags = CompilerFlags();

// Default extensions of the output `[.outline].template.dart` file(s).
const _templateExtension = '.template.dart';
const _outlineExtension = '.outline.template.dart';

/// Generates a temporary `.ng_placeholder` file for the compiler to use.
Builder templatePlaceholder(_) => const Placeholder();

/// Generates additional required Dart files for AngularDart.
///
/// * [defaultFlags]: Default compiler flags before merged with [options].
/// * [templateExtension]: Template extension to use when compiling.
/// * [outlineExtension]: Outline extension to use when `--outline-only` used.
Builder templateCompiler(
  BuilderOptions options, {
  CompilerFlags defaultFlags = _defaultFlags,
  String templateExtension = _templateExtension,
  String outlineExtension = _outlineExtension,
}) {
  final config = Map.of(options.config);
  // We may just run in outliner mode.
  //
  // In Bazel execution, whether or not we use "real" codegen or outlines is
  // determined in an action, and it's easier for them just to invoke us always
  // with the same builder, and we determine here whether to outline or not.
  final outline = config.remove(_useTemplateOutlinesInstead) != null;
  final flags = CompilerFlags.parseRaw(
    config,
    defaultFlags,
  );
  if (outline) {
    return TemplateOutliner(
      extension: outlineExtension,
      exportUserCodeFromTemplate: flags.exportUserCodeFromTemplate,
    );
  }
  return Compiler(flags, generate).asBuilder(extension: templateExtension);
}

/// Generates `.css.dart` files that are imported by the template compiler.
Builder stylesheetCompiler(BuilderOptions options) {
  final flags = CompilerFlags.parseRaw(options.config, _defaultFlags);
  return StylesheetCompiler(flags);
}

/// Generates an outline (API skeleton) instead of fully-generated code.
///
/// * [defaultFlags]: Default compiler flags before merged with [options].
/// * [extension]: Extension to use when compiling.
///
/// **NOTE**: Unused in google3. See [templateBuilder] instead.
Builder outlineCompiler(
  BuilderOptions options, {
  CompilerFlags defaultFlags = _defaultFlags,
  String extension = _outlineExtension,
}) {
  return TemplateOutliner(
    extension: extension,
    exportUserCodeFromTemplate: defaultFlags.exportUserCodeFromTemplate,
  );
}

/// Removes outputted `.ng_placeholder` files.
///
/// **NOTE**: Unused in google3.
PostProcessBuilder placeholderCleanup(_) {
  return const FileDeletingBuilder(['.ng_placeholder']);
}

/// Removes`.html` and `.css` files in `lib/`.
///
/// HTML or CSS files that are required at runtime can be exlcuded by glob.
///
/// **NOTE**: Unused in google3.
PostProcessBuilder componentSourceCleanup(BuilderOptions options) {
  return FileDeletingBuilder.withExcludes(
    const ['.html', '.css'],
    List<String>.from(
      options.config['exclude'] as List ?? const [],
    ),
    isEnabled: options.config['enabled'] == true,
  );
}
