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

/// List of components and directives in source module.
class AngularArtifacts {
  final List<NormalizedComponentWithViewDirectives> components;
  final List<CompileDirectiveMetadata> directives;

  AngularArtifacts(this.components, this.directives);

  bool get isEmpty => components.isEmpty && directives.isEmpty;
}

class NormalizedComponentWithViewDirectives {
  CompileDirectiveMetadata component;
  List<CompileDirectiveMetadata> directives;
  List<CompileTypedMetadata> directiveTypes;
  List<CompilePipeMetadata> pipes;

  NormalizedComponentWithViewDirectives(
    this.component,
    this.directives,
    this.directiveTypes,
    this.pipes,
  ) {
    _assertComponent(component);
  }

  static void _assertComponent(CompileDirectiveMetadata meta) {
    if (!meta.isComponent) {
      throw StateError(
          'Could not compile \'${meta.type.name}\' because it is not a '
          'component.');
    }
  }
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
    var statements = <o.Statement>[];
    for (var component in library.components) {
      _compileComponent(component, statements);
    }

    for (var directive in library.directives) {
      if (!directive.requiresDirectiveChangeDetector) continue;
      _compileDirective(directive, statements);
    }

    return _createSourceModule(moduleUrl, statements, _deferredModules);
  }

  void _compileComponent(ir.Component component, List<o.Statement> statements) {
    for (var view in component.views) {
      _compileView(component, view, statements);
    }
  }

  void _compileView(
      ir.Component component, ir.View view, List<o.Statement> statements) {
    var styleResult = view is ir.HostView
        ? _styleCompiler.compileHostComponent(component)
        : _styleCompiler.compileComponent(component);
    var viewResult = _viewCompiler.compileComponent(
        view.cmpMetadata,
        view.parsedTemplate,
        o.variable(styleResult.stylesVar),
        view.directiveTypes,
        view.pipes,
        _deferredModules,
        registerComponentFactory: view is ir.ComponentView);
    statements.addAll(styleResult.statements);
    statements.addAll(viewResult.statements);
  }

  List<SourceModule> compileStylesheet(String stylesheetUrl, String cssText) {
    var plainStyles =
        _styleCompiler.compileStylesheet(stylesheetUrl, cssText, false);
    var shimStyles =
        _styleCompiler.compileStylesheet(stylesheetUrl, cssText, true);
    return [
      _createSourceModule(
          stylesModuleUrl(stylesheetUrl, false), plainStyles.statements, {}),
      _createSourceModule(
          stylesModuleUrl(stylesheetUrl, true), shimStyles.statements, {})
    ];
  }

  void _compileDirective(ir.Directive directive, List<o.Statement> statements) {
    var result = _directiveCompiler.compile(directive);
    statements.addAll(result.statements);
  }

  SourceModule _createSourceModule(String moduleUrl,
      List<o.Statement> statements, Map<String, String> deferredModules) {
    String sourceCode =
        _outputEmitter.emitStatements(moduleUrl, statements, deferredModules);
    return SourceModule(moduleUrl, sourceCode, deferredModules);
  }
}
