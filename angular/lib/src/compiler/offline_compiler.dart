import 'dart:async';

import '../core/change_detection/change_detection.dart'
    show ChangeDetectionStrategy;
import '../core/metadata/lifecycle_hooks.dart' show LifecycleHooks;
import '../core/metadata/view.dart' show ViewEncapsulation;
import 'ast_directive_normalizer.dart' show AstDirectiveNormalizer;
import 'compile_metadata.dart'
    show
        CompileDirectiveMetadata,
        CompileTypedMetadata,
        CompilePipeMetadata,
        createHostComponentMeta,
        createHostDirectiveTypes;
import 'compiler_utils.dart' show stylesModuleUrl, templateModuleUrl;
import 'ir/model.dart' as ir;
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

/// Compiles a view template.
class OfflineCompiler {
  final AstDirectiveNormalizer _directiveNormalizer;
  final TemplateParser _templateParser;
  final StyleCompiler _styleCompiler;
  final ViewCompiler _viewCompiler;
  final DirectiveCompiler _directiveCompiler;
  final OutputEmitter _outputEmitter;

  /// Maps a moduleUrl to a library prefix. Deferred modules have defer###
  /// prefixes. The moduleUrl has asset: scheme or is a relative url.
  final Map<String, String> _deferredModules;

  OfflineCompiler(
    this._directiveNormalizer,
    this._templateParser,
    this._styleCompiler,
    this._viewCompiler,
    this._outputEmitter,
    this._deferredModules,
  ) : _directiveCompiler = DirectiveCompiler(_templateParser.schemaRegistry);

  Future<CompileDirectiveMetadata> normalizeDirectiveMetadata(
      CompileDirectiveMetadata directive) {
    return _directiveNormalizer.normalizeDirective(directive);
  }

  SourceModule compile(AngularArtifacts artifacts) {
    if (artifacts.isEmpty) {
      throw StateError('No components nor injectorModules given');
    }
    var statements = <o.Statement>[];
    for (var componentWithDirs in artifacts.components) {
      var component = _convertToIR(componentWithDirs);
      _compileComponent(component, statements);
    }

    for (CompileDirectiveMetadata directiveMeta in artifacts.directives) {
      var directive = _convertDirectiveToIR(directiveMeta);
      if (!directive.requiresDirectiveChangeDetector) continue;
      _compileDirective(directive, statements);
    }

    String moduleUrl = _moduleUrlFor(artifacts);
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
        styleResult,
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
      _createSourceModule(stylesModuleUrl(stylesheetUrl, false),
          plainStyles.statements, _deferredModules),
      _createSourceModule(stylesModuleUrl(stylesheetUrl, true),
          shimStyles.statements, _deferredModules)
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

  String _moduleUrlFor(AngularArtifacts artifacts) {
    if (artifacts.components.isNotEmpty) {
      return templateModuleUrl(artifacts.components.first.component.type);
    } else if (artifacts.directives.isNotEmpty) {
      return templateModuleUrl(artifacts.directives.first.type);
    } else {
      throw StateError('No components nor injectorModules given');
    }
  }

  ir.Component _convertToIR(
      NormalizedComponentWithViewDirectives componentWithDirs) {
    return ir.Component(componentWithDirs.component.type.name,
        encapsulation: _encapsulation(componentWithDirs),
        styles: componentWithDirs.component.template.styles,
        styleUrls: componentWithDirs.component.template.styleUrls,
        views: [
          _componentView(componentWithDirs),
          _hostView(componentWithDirs.component)
        ]);
  }

  ir.ViewEncapsulation _encapsulation(
      NormalizedComponentWithViewDirectives componentWithDirs) {
    switch (componentWithDirs.component.template.encapsulation) {
      case ViewEncapsulation.Emulated:
        return ir.ViewEncapsulation.emulated;
      case ViewEncapsulation.None:
        return ir.ViewEncapsulation.none;
      default:
        throw ArgumentError.value(
            componentWithDirs.component.template.encapsulation);
    }
  }

  ir.View _componentView(
      NormalizedComponentWithViewDirectives componentWithDirs) {
    List<TemplateAst> parsedTemplate = _templateParser.parse(
        componentWithDirs.component,
        componentWithDirs.component.template.template,
        componentWithDirs.directives,
        componentWithDirs.pipes,
        componentWithDirs.component.type.name);
    return ir.ComponentView(
        cmpMetadata: componentWithDirs.component,
        directiveTypes: componentWithDirs.directiveTypes,
        parsedTemplate: parsedTemplate,
        pipes: componentWithDirs.pipes);
  }

  ir.View _hostView(CompileDirectiveMetadata component) {
    var hostMeta = createHostComponentMeta(component.type, component.selector,
        component.template.preserveWhitespace);
    var parsedTemplate = _templateParser.parse(hostMeta,
        hostMeta.template.template, [component], [], hostMeta.type.name);
    return ir.HostView(null,
        cmpMetadata: hostMeta,
        parsedTemplate: parsedTemplate,
        directiveTypes: createHostDirectiveTypes(component.type));
  }

  ir.Directive _convertDirectiveToIR(CompileDirectiveMetadata directiveMeta) =>
      ir.Directive(
          name: directiveMeta.identifier.name,
          typeParameters: directiveMeta.originType.typeParameters,
          hostProperties: directiveMeta.hostProperties,
          metadata: directiveMeta,
          requiresDirectiveChangeDetector:
              directiveMeta.requiresDirectiveChangeDetector,
          implementsComponentState:
              directiveMeta.changeDetection == ChangeDetectionStrategy.Stateful,
          implementsOnChanges:
              directiveMeta.lifecycleHooks.contains(LifecycleHooks.onChanges));
}
