import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

import 'ast_directive_normalizer.dart' show AstDirectiveNormalizer;
import 'compile_metadata.dart'
    show
        CompileDirectiveMetadata,
        CompileTypedMetadata,
        CompilePipeMetadata,
        createHostComponentMeta,
        createHostDirectiveTypes;
import 'compiler_utils.dart' show stylesModuleUrl, templateModuleUrl;
import 'output/abstract_emitter.dart' show OutputEmitter;
import 'output/output_ast.dart' as o;
import 'source_module.dart';
import 'style_compiler.dart' show StyleCompiler;
import 'template_ast.dart';
import 'template_parser.dart' show TemplateParser;
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'class': 'NormalizedComponentWithViewDirectives',
        'component': component,
        'directives': directives,
        'directiveTypes': directiveTypes,
        'pipes': pipes,
      };
}

// Make this `true` in order to print what is being compiled.
const _DEBUG_PRINT_COMPILATION = false;

/// Compiles a view template.
class OfflineCompiler {
  final AstDirectiveNormalizer _directiveNormalizer;
  final TemplateParser _templateParser;
  final StyleCompiler _styleCompiler;
  final ViewCompiler _viewCompiler;
  final OutputEmitter _outputEmitter;

  /// Maps a moduleUrl to a library prefix. Deferred modules have defer###
  /// prefixes. The moduleUrl has asset: scheme or is a relative url.
  final Map<String, String> _deferredModules;

  const OfflineCompiler(
    this._directiveNormalizer,
    this._templateParser,
    this._styleCompiler,
    this._viewCompiler,
    this._outputEmitter,
    this._deferredModules,
  );

  Future<CompileDirectiveMetadata> normalizeDirectiveMetadata(
      CompileDirectiveMetadata directive) {
    return _directiveNormalizer.normalizeDirective(directive);
  }

  SourceModule compile(AngularArtifacts artifacts) {
    if (_DEBUG_PRINT_COMPILATION) {
      _printDebugCompilation(artifacts.components);
    }
    if (artifacts.isEmpty) {
      throw StateError('No components nor injectorModules given');
    }
    var statements = <o.Statement>[];
    for (var componentWithDirs in artifacts.components) {
      _compileComponent(componentWithDirs, statements);
    }

    for (CompileDirectiveMetadata directive in artifacts.directives) {
      if (!directive.requiresDirectiveChangeDetector) continue;
      _compileDirective(directive, statements);
    }

    String moduleUrl = _moduleUrlFor(artifacts);
    return _createSourceModule(moduleUrl, statements, _deferredModules);
  }

  void _compileComponent(
      NormalizedComponentWithViewDirectives componentWithDirs,
      List<o.Statement> statements) {
    var compMeta = componentWithDirs.component;
    // Compile Component View and Embedded templates.
    _compileComponentView(
      compMeta,
      componentWithDirs.directives,
      componentWithDirs.directiveTypes,
      componentWithDirs.pipes,
      statements,
      registerComponentFactory: true,
    );

    _compileComponentHost(compMeta, statements);
  }

  List<SourceModule> compileStylesheet(String stylesheetUrl, String cssText) {
    var plainStyles =
        _styleCompiler.compileStylesheet(stylesheetUrl, cssText, false);
    var shimStyles =
        _styleCompiler.compileStylesheet(stylesheetUrl, cssText, true);
    return [
      _createSourceModule(stylesModuleUrl(stylesheetUrl, false),
          plainStyles.statements, _deferredModules),
      _createSourceModule(stylesModuleUrl(stylesheetUrl, true),
          shimStyles.statements, _deferredModules)
    ];
  }

  void _compileComponentView(
      CompileDirectiveMetadata compMeta,
      List<CompileDirectiveMetadata> directives,
      List<CompileTypedMetadata> directiveTypes,
      List<CompilePipeMetadata> pipes,
      List<o.Statement> targetStatements,
      {@required bool registerComponentFactory}) {
    var styleResult = _styleCompiler.compileComponent(compMeta);
    List<TemplateAst> parsedTemplate = _templateParser.parse(compMeta,
        compMeta.template.template, directives, pipes, compMeta.type.name);
    var viewResult = _viewCompiler.compileComponent(
        compMeta,
        parsedTemplate,
        styleResult,
        o.variable(styleResult.stylesVar),
        directiveTypes,
        pipes,
        _deferredModules,
        registerComponentFactory: registerComponentFactory);
    targetStatements.addAll(styleResult.statements);
    targetStatements.addAll(viewResult.statements);
  }

  // Compile ComponentHost to be able to use dynamic component loader at
  // runtime.
  void _compileComponentHost(
      CompileDirectiveMetadata compMeta, List<o.Statement> statements) {
    var hostMeta = createHostComponentMeta(
        compMeta.type, compMeta.selector, compMeta.template.preserveWhitespace);
    var hostDirectiveTypes = createHostDirectiveTypes(compMeta.type);
    _compileComponentView(
      hostMeta,
      [compMeta],
      hostDirectiveTypes,
      [],
      statements,
      registerComponentFactory: false,
    );
  }

  void _compileDirective(
      CompileDirectiveMetadata directive, List<o.Statement> statements) {
    DirectiveCompiler comp =
        DirectiveCompiler(directive, _templateParser.schemaRegistry);
    DirectiveCompileResult res = comp.compile();
    statements.addAll(res.statements);
  }

  SourceModule _createSourceModule(String moduleUrl,
      List<o.Statement> statements, Map<String, String> deferredModules) {
    String sourceCode =
        _outputEmitter.emitStatements(moduleUrl, statements, deferredModules);
    return SourceModule(moduleUrl, sourceCode, deferredModules);
  }

  String _moduleUrlFor(AngularArtifacts artifacts) {
    if (artifacts.components.isNotEmpty) {
      return templateModuleUrl(artifacts.components.first.component.type);
    } else if (artifacts.directives.isNotEmpty) {
      return templateModuleUrl(artifacts.directives.first.type);
    } else {
      throw StateError('No components nor injectorModules given');
    }
  }

  void _printDebugCompilation(
      List<NormalizedComponentWithViewDirectives> components) {
    print(components.map((comp) {
      return const JsonEncoder.withIndent('  ').convert(comp.toJson());
    }).join('\n'));
  }
}
