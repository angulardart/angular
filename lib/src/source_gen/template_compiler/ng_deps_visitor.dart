import 'dart:async';

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
import 'package:angular2/src/transform/common/names.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';

import 'compile_metadata.dart';

/// Resolve and return an [NgDepsModel] from a [library].
///
/// To determine if imports/exports are tied to Angular code generation, the
/// functions [hasInput] (is a file part of the same build process) and
/// [isLibrary] (is a file a dart library generated or pre-existing in the file
/// system) are required.
Future<NgDepsModel> resolveNgDepsFor(
  LibraryElement library, {
  @required Future<bool> hasInput(String uri),
  @required bool isLibrary(String uri),
}) async {
  // Visit and find all 'reflectables'.
  final reflectableVisitor = new ReflectableVisitor();
  library.accept(reflectableVisitor);

  // Collect all import and exports, and see if we need additional metadata.
  final imports = <ImportModel>[];
  final exports = <ExportModel>[];
  final templateDeps = <ImportModel>[];
  final pendingResolution = <Future>[];

  Future resolveAndCheckUri(UriReferencedElement directive) async {
    final uri = directive.uri;
    if (uri == null) {
      return null;
    }
    if (directive is ImportElement) {
      imports.add(new ImportModel.fromElement(directive));
    } else {
      exports.add(new ExportModel.fromElement(directive));
    }
    if (uri.startsWith('dart:') || uri.endsWith(TEMPLATE_EXTENSION)) {
      return null;
    }
    final template = ''
        '${uri.substring(0, uri.length - '.dart'.length)}'
        '${TEMPLATE_EXTENSION}';
    if (isLibrary(template) || await hasInput(uri)) {
      templateDeps.add(new ImportModel(uri: template));
    }
  }

  pendingResolution
    ..addAll(library.imports.map(resolveAndCheckUri))
    ..addAll(library.exports.map(resolveAndCheckUri));

  await Future.wait(pendingResolution);

  return new NgDepsModel(
    reflectables: reflectableVisitor.reflectables,
    imports: imports,
    exports: exports,
    depImports: templateDeps,
  );
}

/// An [ElementVisitor] which extracts all [ReflectableInfoModel]s found in the
/// given element or its children.
class ReflectableVisitor extends RecursiveElementVisitor {
  final bool _visitRecursive;
  final Set<String> _visited = new Set<String>();

  List<ReflectionInfoModel> _reflectables = [];

  ReflectableVisitor({bool visitRecursive: false})
      : _visitRecursive = visitRecursive;

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
    var visitor = new CompileTypeMetadataVisitor(log);
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
    if (annotation_matcher.safeIsInjectable(element, log)) {
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
      log,
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
              ], log)(annotation))
          .map((annotation) =>
              new AnnotationModel.fromElement(annotation, element))
          .toList();
}
