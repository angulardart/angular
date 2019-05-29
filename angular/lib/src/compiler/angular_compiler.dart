import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular/src/compiler/ast_directive_normalizer.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/compiler/compiler_utils.dart';
import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/compiler/offline_compiler.dart';
import 'package:angular/src/compiler/semantic_analysis/directive_converter.dart';
import 'package:angular/src/compiler/source_module.dart';
import 'package:angular/src/compiler/template_ast.dart';
import 'package:angular/src/compiler/template_parser.dart';
import 'package:angular/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular/src/source_gen/template_compiler/component_visitor_exceptions.dart';
import 'package:angular/src/source_gen/template_compiler/find_components.dart';

/// The main compiler for the AngularDart framework.
class AngularCompiler {
  final AstDirectiveNormalizer _directiveNormalizer;
  final DirectiveConverter _directiveConverter;
  final OfflineCompiler templateCompiler;
  final TemplateParser _templateParser;

  AngularCompiler(
    this.templateCompiler,
    this._directiveNormalizer,
    this._directiveConverter,
    this._templateParser,
  );

  Future<SourceModule> compile(LibraryElement element) async {
    final exceptionHandler = ComponentVisitorExceptionHandler();
    // Parse Dart code for @Components and @Directives
    final compileComponentsData =
        findComponentsAndDirectives(LibraryReader(element), exceptionHandler);

    await exceptionHandler.maybeReportErrors();

    if (compileComponentsData.isEmpty) return null;

    // Convert the Components into an intermediate representation
    final components = <ir.Component>[];
    for (final component in compileComponentsData.components) {
      final normalizedComponent = await _normalizeComponent(component);
      final componentIR = _convertToIR(normalizedComponent);
      components.add(componentIR);
    }

    // Convert the Directives into an intermediate representation
    final directives = <ir.Directive>[];
    for (final directive in compileComponentsData.directives) {
      final directiveIR = _directiveConverter.convertDirectiveToIR(directive);
      directives.add(directiveIR);
    }

    // Compile the intermediate representation into the output dart template.
    final compiledTemplates = templateCompiler.compile(
      ir.Library(components, directives),
      _moduleUrlFor(compileComponentsData),
    );

    return compiledTemplates;
  }

  Future<NormalizedComponentWithViewDirectives> _normalizeComponent(
    NormalizedComponentWithViewDirectives component,
  ) async =>
      NormalizedComponentWithViewDirectives(
        component: await _directiveNormalizer.normalizeDirective(
          component.component,
        ),
        directives: await Future.wait(
          component.directives.map(_directiveNormalizer.normalizeDirective),
        ),
        directiveTypes: component.directiveTypes,
        pipes: component.pipes,
      );

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
      componentWithDirs.component.type.name,
      componentWithDirs.component.template.templateUrl,
    );
    return ir.ComponentView(
        cmpMetadata: componentWithDirs.component,
        directiveTypes: componentWithDirs.directiveTypes,
        parsedTemplate: parsedTemplate,
        pipes: componentWithDirs.pipes);
  }

  ir.View _hostView(CompileDirectiveMetadata component) {
    var hostMeta = createHostComponentMeta(
      component.type,
      component.selector,
      component.analyzedClass,
      component.template.preserveWhitespace,
    );
    var parsedTemplate = _templateParser.parse(
      hostMeta,
      hostMeta.template.template,
      [component],
      [],
      hostMeta.type.name,
      hostMeta.template.templateUrl,
    );
    return ir.HostView(null,
        cmpMetadata: hostMeta,
        parsedTemplate: parsedTemplate,
        directiveTypes: createHostDirectiveTypes(component.type));
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
}
