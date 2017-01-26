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

  bool _hasReflectables(LibraryElement importedLibrary) {
    var visitor = new ReflectableVisitor(_buildStep);
    importedLibrary.accept(visitor);
    return visitor.reflectables.isNotEmpty;
  }

  @override
  void visitExportElement(ExportElement element) {
    if (element.uri != null) {
      exports.add(new ExportModel.fromElement(element));
    }
  }
}

/// An [ElementVisitor] which extracts all [ReflectableInfoModel]s found in the
/// given element or its children.
class ReflectableVisitor extends RecursiveElementVisitor {
  final BuildStep _buildStep;
  List<ReflectionInfoModel> _reflectables = [];

  ReflectableVisitor(this._buildStep);

  Logger get _logger => _buildStep.logger;

  List<ReflectionInfoModel> get reflectables =>
      _reflectables.where((model) => model != null).toList();

  @override
  void visitClassElement(ClassElement element) {
    CompileTypeMetadata compileType =
        element.accept(new CompileTypeMetadataVisitor(_logger));
    if (compileType == null) return;
    var constructor = _constructor(element);
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
    if (annotation_matcher.isInjectable(element)) {
      _reflectables.add(new ReflectionInfoModel(
          isFunction: true,
          // TODO(alorenzen): Add import from source file, for proper scoping.
          type: reference(element.name),
          parameters: _parameters(element),
          annotations: _annotations(element.metadata, element)));
    }
  }

  /// Finds the unnamed constructor if it is present.
  ///
  /// Otherwise, use the first encountered.
  ConstructorElement _constructor(ClassElement element) {
    var constructors = element.constructors;
    if (constructors.isEmpty) {
      _logger.severe('Invalid @Injectable() annotation: '
          'No constructors found for class ${element.name}.');
      return null;
    }

    var constructor = constructors.firstWhere(
        (constructor) => constructor.name == null,
        orElse: () => constructors.first);

    if (constructor.isPrivate) {
      _logger.severe('Invalid @Injectable() annotation: '
          'Cannot use private constructor on class ${element.name}');
      return null;
    }
    if (element.isAbstract && !constructor.isFactory) {
      _logger.severe('Invalid @Injectable() annotation: '
          'Found a constructor for abstract class ${element.name} but it is '
          'not a "factory", and cannot be invoked');
      return null;
    }
    if (element.constructors.length > 1 && constructor.name != null) {
      _logger.warning(
          'Found ${element.constructors.length} constructors for class '
          '${element.name}; using constructor ${constructor.name}.');
    }
    return constructor;
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
    if (element.metadata.any(annotation_matcher.isComponent)) {
      annotations.add(new AnnotationModel(
          name: '${element.name}NgFactory', isConstObject: true));
    }
    return annotations;
  }

  List<AnnotationModel> _annotations(
          List<ElementAnnotation> metadata, Element element) =>
      metadata
          .where((annotation) => !annotation_matcher
              .matchTypes([Component, View, Directive], annotation))
          .map((annotation) =>
              new AnnotationModel.fromElement(annotation, element))
          .toList();
}
