import 'dart:async';
import 'dart:convert';

import 'ast_directive_normalizer.dart' show AstDirectiveNormalizer;
import 'compile_metadata.dart'
    show
        CompileDirectiveMetadata,
        CompileTypedMetadata,
        CompilePipeMetadata,
        createHostComponentMeta,
        createHostDirectiveTypes;
import 'compiler_utils.dart' show stylesModuleUrl, templateModuleUrl;
import 'identifiers.dart';
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
  );

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
    List<NormalizedComponentWithViewDirectives> components =
        artifacts.components;
    if (_DEBUG_PRINT_COMPILATION) {
      _printDebugCompilation(components);
    }
    if (_isEmpty(components, artifacts)) {
      throw StateError('No components nor injectorModules given');
    }
    var statements = <o.Statement>[];
    var exportedVars = <String>[];
    for (var componentWithDirs in components) {
      CompileDirectiveMetadata compMeta = componentWithDirs.component;
      _assertComponent(compMeta);

      // Compile Component View and Embedded templates.
      var compViewFactoryVar = _compileComponent(
          compMeta,
          componentWithDirs.directives,
          componentWithDirs.directiveTypes,
          componentWithDirs.pipes,
          statements,
          _deferredModules);
      exportedVars.add(compViewFactoryVar);

      String hostViewFactoryVar = _compileComponentHost(compMeta, statements);

      var compFactoryVar =
          _registerComponentFactory(statements, compMeta, hostViewFactoryVar);
      exportedVars.add(compFactoryVar);
    }

    for (CompileDirectiveMetadata directive in artifacts.directives) {
      if (!directive.requiresDirectiveChangeDetector) continue;
      var changeDetectorClassName = _compileDirective(directive, statements);
      exportedVars.add(changeDetectorClassName);
    }

    String moduleUrl = _moduleUrlFor(components, artifacts);
    return _createSourceModule(
        moduleUrl, statements, exportedVars, _deferredModules);
  }

  List<SourceModule> compileStylesheet(String stylesheetUrl, String cssText) {
    var plainStyles =
        _styleCompiler.compileStylesheet(stylesheetUrl, cssText, false);
    var shimStyles =
        _styleCompiler.compileStylesheet(stylesheetUrl, cssText, true);
    return [
      _createSourceModule(stylesModuleUrl(stylesheetUrl, false),
          plainStyles.statements, [plainStyles.stylesVar], _deferredModules),
      _createSourceModule(stylesModuleUrl(stylesheetUrl, true),
          shimStyles.statements, [shimStyles.stylesVar], _deferredModules)
    ];
  }

  String _compileComponent(
      CompileDirectiveMetadata compMeta,
      List<CompileDirectiveMetadata> directives,
      List<CompileTypedMetadata> directiveTypes,
      List<CompilePipeMetadata> pipes,
      List<o.Statement> targetStatements,
      Map<String, String> deferredModules) {
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
        deferredModules);
    targetStatements.addAll(styleResult.statements);
    targetStatements.addAll(viewResult.statements);
    return viewResult.viewFactoryVar;
  }

  // Compile ComponentHost to be able to use dynamic component loader at
  // runtime.
  String _compileComponentHost(
      CompileDirectiveMetadata compMeta, List<o.Statement> statements) {
    var hostMeta = createHostComponentMeta(
        compMeta.type, compMeta.selector, compMeta.template.preserveWhitespace);
    var hostDirectiveTypes = createHostDirectiveTypes(compMeta.type);
    return _compileComponent(
      hostMeta,
      [compMeta],
      hostDirectiveTypes,
      [],
      statements,
      _deferredModules,
    );
  }

  // Adds const _FooNgFactory = const ComponentFactory<Foo>(...).
  // ComponentFactory<Foo> FooNgFactory get _FooNgFactory;
  //
  // This is referenced in `initReflector/METADATA` and by user-code.
  String _registerComponentFactory(List<o.Statement> statements,
      CompileDirectiveMetadata compMeta, String hostViewFactoryVar) {
    var compFactoryVar = '${compMeta.type.name}NgFactory';
    var factoryType = [o.importType(compMeta.type)];
    statements.add(o
        .variable('_$compFactoryVar')
        .set(o.importExpr(Identifiers.ComponentFactory).instantiate(
          <o.Expression>[
            o.literal(compMeta.selector),
            o.variable(hostViewFactoryVar),
          ],
          type: o.importType(
            Identifiers.ComponentFactory,
            factoryType,
            [o.TypeModifier.Const],
          ),
        ))
        .toDeclStmt(null, [o.StmtModifier.Const]));

    statements.add(
      o.fn(
        // No parameters.
        [],
        // Statements.
        [
          o.ReturnStatement(o.ReadVarExpr('_$compFactoryVar')),
        ],
        o.importType(
          Identifiers.ComponentFactory,
          factoryType,
        ),
      ).toGetter('$compFactoryVar'),
    );
    return compFactoryVar;
  }

  String _compileDirective(
      CompileDirectiveMetadata directive, List<o.Statement> statements) {
    DirectiveCompiler comp =
        DirectiveCompiler(directive, _templateParser.schemaRegistry);
    DirectiveCompileResult res = comp.compile();
    statements.addAll(res.statements);
    return comp.changeDetectorClassName;
  }

  SourceModule _createSourceModule(
      String moduleUrl,
      List<o.Statement> statements,
      List<String> exportedVars,
      Map<String, String> deferredModules) {
    String sourceCode = _outputEmitter.emitStatements(
        moduleUrl, statements, exportedVars, deferredModules);
    return SourceModule(moduleUrl, sourceCode, deferredModules);
  }

  bool _isEmpty(List<NormalizedComponentWithViewDirectives> components,
      AngularArtifacts artifacts) {
    return components.isEmpty && artifacts.directives.isEmpty;
  }

  String _moduleUrlFor(List<NormalizedComponentWithViewDirectives> components,
      AngularArtifacts artifacts) {
    if (components.isNotEmpty) {
      return templateModuleUrl(components[0].component.type);
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

void _assertComponent(CompileDirectiveMetadata meta) {
  if (!meta.isComponent) {
    throw StateError(
        "Could not compile '${meta.type.name}' because it is not a component.");
  }
}
