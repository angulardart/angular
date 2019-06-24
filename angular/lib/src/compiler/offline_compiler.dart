import 'package:meta/meta.dart';

import 'compile_metadata.dart'
    show CompileDirectiveMetadata, CompileTypedMetadata, CompilePipeMetadata;
import 'compiler_utils.dart' show stylesModuleUrl;
import 'ir/model.dart' as ir;
import 'output/abstract_emitter.dart' show OutputEmitter;
import 'output/output_ast.dart' as o;
import 'source_module.dart';
import 'stylesheet_compiler/style_compiler.dart' show StyleCompiler;
import 'view_compiler/directive_compiler.dart';
import 'view_compiler/view_compiler.dart' show ViewCompiler;

/// A collection of all components and directives in a given input module.
class AngularArtifacts {
  /// Processed `@Component`-annotated classes.
  final List<NormalizedComponentWithViewDirectives> components;

  /// Processed `@Directive`-annotated classes.
  final List<CompileDirectiveMetadata> directives;

  const AngularArtifacts({
    @required this.components,
    @required this.directives,
  })  : assert(components != null),
        assert(directives != null);

  /// Whether the input has no component and directives.
  bool get isEmpty => components.isEmpty && directives.isEmpty;
}

/// A processed `@Component`-annotated class with relevant metadata.
///
/// Contains the [component]'s metadata, as well as a link to the [directives],
/// [directiveTypes], and [pipes] that the component was configured to create
/// and use.
class NormalizedComponentWithViewDirectives {
  final CompileDirectiveMetadata component;
  final List<CompileDirectiveMetadata> directives;
  final List<CompileTypedMetadata> directiveTypes;
  final List<CompilePipeMetadata> pipes;

  const NormalizedComponentWithViewDirectives({
    @required this.component,
    @required this.directives,
    @required this.directiveTypes,
    @required this.pipes,
  })  : assert(component != null),
        assert(directives != null),
        assert(directiveTypes != null),
        assert(pipes != null);
}

/// Compiles a view template.
class OfflineCompiler {
  final StyleCompiler _styleCompiler;
  final ViewCompiler _viewCompiler;
  final DirectiveCompiler _directiveCompiler;
  final OutputEmitter _outputEmitter;

  /// Maps a moduleUrl to a library prefix. Deferred modules have defer###
  /// prefixes. The moduleUrl has asset: scheme or is a relative url.
  final Map<String, String> _deferredModules;

  OfflineCompiler(
    this._directiveCompiler,
    this._styleCompiler,
    this._viewCompiler,
    this._outputEmitter,
    this._deferredModules,
  );

  SourceModule compile(ir.Library library, String moduleUrl) {
    final statements = <o.Statement>[];
    for (final component in library.components) {
      _compileComponent(component, statements);
    }

    for (final directive in library.directives) {
      if (!directive.requiresDirectiveChangeDetector) continue;
      _compileDirective(directive, statements);
    }

    return _createSourceModule(moduleUrl, statements, _deferredModules);
  }

  void _compileComponent(ir.Component component, List<o.Statement> statements) {
    for (final view in component.views) {
      _compileView(component, view, statements);
    }
  }

  void _compileView(
    ir.Component component,
    ir.View view,
    List<o.Statement> statements,
  ) {
    final styleResult = view is ir.HostView
        ? _styleCompiler.compileHostComponent(component)
        : _styleCompiler.compileComponent(component);
    final viewResult = _viewCompiler.compileComponent(
      view,
      o.variable(styleResult.stylesVar),
      _deferredModules,
      registerComponentFactory: view is ir.ComponentView,
    );
    statements.addAll(styleResult.statements);
    statements.addAll(viewResult.statements);
  }

  List<SourceModule> compileStylesheet(String stylesheetUrl, String cssText) {
    final plainStyles =
        _styleCompiler.compileStylesheet(stylesheetUrl, cssText, false);
    final shimStyles =
        _styleCompiler.compileStylesheet(stylesheetUrl, cssText, true);
    return [
      _createSourceModule(
          stylesModuleUrl(stylesheetUrl, false), plainStyles.statements, {}),
      _createSourceModule(
          stylesModuleUrl(stylesheetUrl, true), shimStyles.statements, {})
    ];
  }

  void _compileDirective(ir.Directive directive, List<o.Statement> statements) {
    final result = _directiveCompiler.compile(directive);
    statements.addAll(result.statements);
  }

  SourceModule _createSourceModule(
    String moduleUrl,
    List<o.Statement> statements,
    Map<String, String> deferredModules,
  ) {
    final sourceCode = _outputEmitter.emitStatements(
      moduleUrl,
      statements,
      deferredModules,
    );
    return SourceModule(moduleUrl, sourceCode, deferredModules);
  }
}
