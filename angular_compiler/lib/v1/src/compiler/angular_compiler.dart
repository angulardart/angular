import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular/src/meta.dart';
import 'package:angular_compiler/v1/src/compiler/ast_directive_normalizer.dart';
import 'package:angular_compiler/v1/src/compiler/compile_metadata.dart';
import 'package:angular_compiler/v1/src/compiler/compiler_utils.dart';
import 'package:angular_compiler/v1/src/compiler/ir/model.dart' as ir;
import 'package:angular_compiler/v1/src/compiler/semantic_analysis/directive_converter.dart';
import 'package:angular_compiler/v1/src/compiler/source_module.dart';
import 'package:angular_compiler/v1/src/compiler/template_compiler.dart';
import 'package:angular_compiler/v1/src/compiler/template_parser/ast_template_parser.dart';
import 'package:angular_compiler/v1/src/source_gen/template_compiler/component_visitor_exceptions.dart';
import 'package:angular_compiler/v1/src/source_gen/template_compiler/find_components.dart';

/// The bulk of "compilation" for AngularDart's components and templates.
///
/// Ultimately, this class runs the set of smaller processes that take a `.dart`
/// library as input, finding (and parsing as necessary) any external `.html`
/// templates and building up internal data structures to represent the
/// generated code (referred to as "views").
class AngularCompiler {
  final AstDirectiveNormalizer _directiveNormalizer;
  final DirectiveConverter _directiveConverter;
  final TemplateCompiler _templateCompiler;
  final AstTemplateParser _templateParser;
  final Resolver _resolver;

  AngularCompiler(
    this._templateCompiler,
    this._directiveNormalizer,
    this._directiveConverter,
    this._templateParser,
    this._resolver,
  );

  /// Given a `.dart` library target [element], returns `.template.dart`.
  ///
  /// May return `Future(null)` to signify the compilation should result in no
  /// output (such as there were no `@Component()` annotations found in the
  /// target [element]).
  Future<DartSourceOutput?> compile(LibraryElement element) async {
    final exceptionHandler = ComponentVisitorExceptionHandler();

    // Parse Dart code for @Components and @Directives
    final compileComponentsData = findComponentsAndDirectives(
      LibraryReader(element),
      exceptionHandler,
    );

    // Some uncaught exceptions are handled asynchronously, so we need to await
    // and let those be resolved and emitted before continuing. If at least one
    // error occurs, this function will throw and not continue further in the
    // compiler.
    await exceptionHandler.maybeReportErrors(_resolver);

    final noRelevantAnnotationsFound = compileComponentsData.isEmpty;
    if (noRelevantAnnotationsFound) return null;

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

    // Compile and return intermediate representation into Dart source code.
    return _templateCompiler.compile(
      ir.Library(components, directives),
      _moduleUrlFor(compileComponentsData),
    );
  }

  /// Resolves external URLs and replaces the otherwise empty properties.
  Future<NormalizedComponentWithViewDirectives> _normalizeComponent(
    NormalizedComponentWithViewDirectives component,
  ) async {
    return NormalizedComponentWithViewDirectives(
      // Inline template, styles, some validation checks.
      component: await _directiveNormalizer.normalizeDirective(
        component.component,
      ),
      // This is a no-op, as directives are not currently normalized.
      directives: await Future.wait(
        component.directives.map(_directiveNormalizer.normalizeDirective),
      ),
      directiveTypes: component.directiveTypes,
      pipes: component.pipes,
    );
  }

  ir.Component _convertToIR(
    NormalizedComponentWithViewDirectives componentWithDirs,
  ) {
    return ir.Component(
      componentWithDirs.component.type!.name,
      encapsulation: _encapsulation(componentWithDirs),
      styles: componentWithDirs.component.template!.styles,
      styleUrls: componentWithDirs.component.template!.styleUrls,
      views: [
        _componentView(componentWithDirs),
        _hostView(componentWithDirs.component)
      ],
    );
  }

  ir.ViewEncapsulation _encapsulation(
    NormalizedComponentWithViewDirectives componentWithDirs,
  ) {
    switch (componentWithDirs.component.template!.encapsulation) {
      case ViewEncapsulation.Emulated:
        return ir.ViewEncapsulation.emulated;
      case ViewEncapsulation.None:
        return ir.ViewEncapsulation.none;
      default:
        throw ArgumentError.value(
          componentWithDirs.component.template!.encapsulation,
        );
    }
  }

  ir.View _componentView(
    NormalizedComponentWithViewDirectives componentWithDirs,
  ) {
    var parsedTemplate = _templateParser.parse(
      componentWithDirs.component,
      componentWithDirs.component.template!.template!,
      componentWithDirs.directives,
      componentWithDirs.pipes,
      componentWithDirs.component.type!.name,
      componentWithDirs.component.template!.templateUrl!,
    );
    return ir.ComponentView(
      cmpMetadata: componentWithDirs.component,
      directiveTypes: componentWithDirs.directiveTypes,
      parsedTemplate: parsedTemplate,
      pipes: componentWithDirs.pipes,
    );
  }

  ir.View _hostView(CompileDirectiveMetadata component) {
    var hostMeta = createHostComponentMeta(
      component.type!,
      component.selector!,
      component.analyzedClass,
      component.template!.preserveWhitespace,
    );
    var parsedTemplate = _templateParser.parse(
      hostMeta,
      hostMeta.template!.template!,
      [component],
      [],
      hostMeta.type!.name,
      hostMeta.template!.templateUrl!,
    );
    return ir.HostView(
      cmpMetadata: hostMeta,
      parsedTemplate: parsedTemplate,
      directiveTypes: createHostDirectiveTypes(component.type!),
    );
  }

  static String _moduleUrlFor(AngularArtifacts artifacts) {
    if (artifacts.components.isNotEmpty) {
      return templateModuleUrl(artifacts.components.first.component.type!);
    } else if (artifacts.directives.isNotEmpty) {
      return templateModuleUrl(artifacts.directives.first.type!);
    } else {
      throw StateError('No components nor injectorModules given');
    }
  }
}
