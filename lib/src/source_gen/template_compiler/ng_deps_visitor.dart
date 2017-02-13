import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:angular2/src/compiler/compile_metadata.dart';
import 'package:angular2/src/core/metadata.dart';
import 'package:angular2/src/source_gen/common/annotation_matcher.dart'
    as annotation_matcher;
import 'package:angular2/src/source_gen/common/annotation_model.dart';
import 'package:angular2/src/source_gen/common/namespace_model.dart';
import 'package:angular2/src/source_gen/common/ng_deps_model.dart';
import 'package:angular2/src/source_gen/common/parameter_model.dart';
import 'package:angular2/src/source_gen/common/references.dart';
import 'package:angular2/src/source_gen/common/reflection_info_model.dart';
import 'package:angular2/src/source_gen/template_compiler/compile_metadata.dart';
import 'package:angular2/src/transform/common/names.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:logging/logging.dart';

/// Create an [NgDepsModel] for the [LibraryElement] supplied.
NgDepsModel extractNgDepsModel(LibraryElement element, BuildStep buildStep) {
  var reflectableVisitor = new ReflectableVisitor(buildStep);
  element.accept(reflectableVisitor);
  var namespaceVisitor = new NameSpaceVisitor(buildStep);
  element.accept(namespaceVisitor);
  return new NgDepsModel(
      reflectables: reflectableVisitor.reflectables,
      imports: namespaceVisitor.imports,
      exports: namespaceVisitor.exports,
      depImports: namespaceVisitor.depImports);
}

class NameSpaceVisitor extends RecursiveElementVisitor {
  final BuildStep _buildStep;
  List<ImportModel> imports = [];
  List<ImportModel> depImports = [];
  List<ExportModel> exports = [];

  NameSpaceVisitor(this._buildStep);

  @override
  void visitImportElement(ImportElement element) {
    if (element.uri != null) {
      var import = new ImportModel.fromElement(element);
      imports.add(import);
      if (_hasReflectables(element.importedLibrary)) {
        depImports.add(new ImportModel(
            uri: import.uri.replaceFirst('\.dart', TEMPLATE_EXTENSION)));
      }
    }
  }

  @override
  void visitExportElement(ExportElement element) {
    if (element.uri != null) {
      var export = new ExportModel.fromElement(element);
      exports.add(export);
      if (_hasReflectables(element.exportedLibrary)) {
        depImports.add(new ImportModel(
            uri: export.uri.replaceFirst('\.dart', TEMPLATE_EXTENSION)));
      }
    }
  }

  // TODO(alorenzen): Consider memoizing this to improve build performance.
  bool _hasReflectables(LibraryElement importedLibrary) {
    var visitor = new ReflectableVisitor(_buildStep, visitRecursive: true);
    importedLibrary.accept(visitor);
    return visitor.reflectables.isNotEmpty;
  }
}

/// An [ElementVisitor] which extracts all [ReflectableInfoModel]s found in the
/// given element or its children.
class ReflectableVisitor extends RecursiveElementVisitor {
  final BuildStep _buildStep;
  final bool _visitRecursive;
  final Set<String> _visited = new Set<String>();

  List<ReflectionInfoModel> _reflectables = [];

  ReflectableVisitor(this._buildStep, {bool visitRecursive: false})
      : _visitRecursive = visitRecursive;

  Logger get _logger => _buildStep.logger;

  List<ReflectionInfoModel> get reflectables =>
      _reflectables.where((model) => model != null).toList();

  // TODO(alorenzen): Determine if we need to visit part-files as well.
  @override
  void visitExportElement(ExportElement element) {
    if (_visitRecursive && _visited.add(element.exportedLibrary.identifier)) {
      element.exportedLibrary.accept(this);
    }
  }

  @override
  void visitImportElement(ImportElement element) {
    if (_visitRecursive && _visited.add(element.importedLibrary.identifier)) {
      element.importedLibrary.accept(this);
    }
  }

  @override
  void visitClassElement(ClassElement element) {
    var visitor = new CompileTypeMetadataVisitor(_logger);
    CompileTypeMetadata compileType = element.accept(visitor);
    if (compileType == null) return;
    var constructor = visitor.unnamedConstructor(element);
    if (constructor == null) return;
    _reflectables.add(new ReflectionInfoModel(
        isFunction: false,
        // TODO(alorenzen): Add import from source file, for proper scoping.
        type: reference(compileType.name),
        ctorName: constructor.name,
        parameters: _parameters(constructor),
        annotations: _annotationsFor(element),
        interfaces: _interfaces(element)));
  }

  @override
  void visitFunctionElement(FunctionElement element) {
    if (annotation_matcher.safeIsInjectable(element, _logger)) {
      _reflectables.add(new ReflectionInfoModel(
          isFunction: true,
          // TODO(alorenzen): Add import from source file, for proper scoping.
          type: reference(element.name),
          parameters: _parameters(element),
          annotations: _annotations(element.metadata, element)));
    }
  }

  List<ParameterModel> _parameters(ExecutableElement element) =>
      element.parameters
          .map((parameter) => new ParameterModel.fromElement(parameter))
          .toList();

  // TODO(alorenzen): Verify that this works for interfaces of superclasses.
  List<ReferenceBuilder> _interfaces(ClassElement element) => element.interfaces
      .map((interface) => toBuilder(interface, element.library.imports))
      .toList();

  /// Finds all annotations for the [element] that need to be registered with
  /// the reflector.
  ///
  /// Additionally, for each compiled template, add the compiled template class
  /// as an Annotation.
  List<AnnotationModel> _annotationsFor(ClassElement element) {
    var annotations = _annotations(element.metadata, element);
    if (element.metadata.any(annotation_matcher.safeMatcher(
      annotation_matcher.isComponent,
      _logger,
    ))) {
      annotations.add(new AnnotationModel(
          name: '${element.name}NgFactory', isConstObject: true));
    }
    return annotations;
  }

  List<AnnotationModel> _annotations(
          List<ElementAnnotation> metadata, Element element) =>
      metadata
          .where((annotation) => !annotation_matcher.safeMatcherTypes(const [
                Component,
                View,
                Directive,
                Deprecated,
                Pipe,
                Inject,
              ], _logger)(annotation))
          .map((annotation) =>
              new AnnotationModel.fromElement(annotation, element))
          .toList();
}
