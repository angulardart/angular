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
    required this.components,
    required this.directives,
  });

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
    required this.component,
    required this.directives,
    required this.directiveTypes,
    required this.pipes,
  });
}

/// Compiles view templates for `@Component()`-annotated classes.
class TemplateCompiler {
  final StyleCompiler _styleCompiler;
  final ViewCompiler _viewCompiler;
  final DirectiveCompiler _directiveCompiler;
  final OutputEmitter _outputEmitter;

  TemplateCompiler(
    this._directiveCompiler,
    this._styleCompiler,
    this._viewCompiler,
    this._outputEmitter,
  );

  DartSourceOutput compile(ir.Library library, String moduleUrl) {
    /// Line-by-line (approximately) "statements" to write as dart source.
    final statements = <o.Statement>[];

    // Output *Views.
    for (final component in library.components) {
      _compileComponent(component, statements);
    }

    // Output DirectiveChangeDetector (for some Directives).
    for (final directive in library.directives) {
      if (directive.requiresDirectiveChangeDetector) {
        _compileDirective(directive, statements);
      }
    }

    return _createSourceModule(moduleUrl, statements);
  }

  void _compileComponent(ir.Component component, List<o.Statement> statements) {
    for (final view in component.views) {
      _compileView(component, view, statements);
    }
  }

  /// Compiles individual [view] for a [component].
  ///
  /// A [view] can be a [ir.HostView], [ir.ComponentView], or [ir.EmbeddedView].
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
      registerComponentFactory: view is ir.ComponentView,
    );
    statements.addAll(styleResult.statements);
    statements.addAll(viewResult.statements);
  }

  List<DartSourceOutput> compileStylesheet(
      String stylesheetUrl, String cssText) {
    final plainStyles =
        _styleCompiler.compileStylesheet(stylesheetUrl, cssText, false);
    final shimStyles =
        _styleCompiler.compileStylesheet(stylesheetUrl, cssText, true);
    return [
      _createSourceModule(
        stylesModuleUrl(stylesheetUrl, false),
        plainStyles.statements,
      ),
      _createSourceModule(
        stylesModuleUrl(stylesheetUrl, true),
        shimStyles.statements,
      ),
    ];
  }

  void _compileDirective(ir.Directive directive, List<o.Statement> statements) {
    final result = _directiveCompiler.compile(directive);
    statements.addAll(result.statements);
  }

  DartSourceOutput _createSourceModule(
    String moduleUrl,
    List<o.Statement> statements,
  ) {
    final sourceCode = _outputEmitter.emitStatements(
      moduleUrl,
      statements,
    );
    return DartSourceOutput(
      outputUrl: moduleUrl,
      sourceCode: sourceCode,
    );
  }
}
