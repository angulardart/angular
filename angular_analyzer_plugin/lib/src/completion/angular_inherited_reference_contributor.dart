import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart'
    show PropertyAccessorElement, FunctionElement, ClassElement, LibraryElement;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/src/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/completion/inherited_reference_contributor.dart';
import 'package:analyzer_plugin/utilities/completion/relevance.dart';
import 'package:angular_analyzer_plugin/src/completion/request.dart';
import 'package:angular_analyzer_plugin/src/completion/dart_resolve_result_shell.dart';
import 'package:angular_analyzer_plugin/src/completion/local_variables_extractor.dart';
import 'package:angular_analyzer_plugin/ast.dart';
import 'package:angular_analyzer_plugin/src/model.dart';

/// Completion contributor for inherited references in the template.
///
/// This is what enables members from the component class and its superclasses
/// to be suggested inside of dart expressions in the template.
///
/// Also expanded to suggest exported terms and local variables to the template.
///
/// Extension of [InheritedReferenceContributor] to allow for Dart-based
/// completion within Angular context. Triggered in [StatementsBoundAttribute],
/// [ExpressionsBoundAttribute], [Mustache], and [TemplateAttribute]
/// on identifier completion.
class AngularInheritedReferenceContributor extends CompletionContributor {
  final InheritedReferenceContributor _inheritedReferenceContributor =
      InheritedReferenceContributor();

  void addExportedPrefixSuggestions(
      CompletionCollector collector, Component component) {
    if (component.exports == null) {
      return;
    }

    component.exports
        .map((export) => export.prefix)
        .where((prefix) => prefix != '')
        .toSet()
        .map((prefix) => _addExportedPrefixSuggestion(
            prefix, _getPrefixedImport(component.classElement.library, prefix)))
        .forEach(collector.addSuggestion);
  }

  void addExportSuggestions(
      CompletionCollector collector, Component component, OpType optype,
      {String prefix}) {
    if (prefix == null) {
      collector.addSuggestion(_addExportedClassSuggestion(
          Export(
              component.classElement.name, null, null, component.classElement),
          component.classElement.type,
          ElementKind.CLASS,
          optype,
          relevance: DART_RELEVANCE_DEFAULT));
    }

    final exports = component.exports;
    if (exports == null) {
      return;
    }

    for (final export in exports) {
      if (prefix != null && export.prefix != prefix) {
        continue;
      }

      final element = export.element;
      if (element is PropertyAccessorElement) {
        collector.addSuggestion(_addExportedGetterSuggestion(
            export, element.variable.type, ElementKind.GETTER, optype,
            relevance: DART_RELEVANCE_DEFAULT, withPrefix: prefix == null));
      }
      if (element is FunctionElement) {
        collector.addSuggestion(_addExportedFunctionSuggestion(
            export, element.returnType, ElementKind.FUNCTION, optype,
            relevance: DART_RELEVANCE_DEFAULT, withPrefix: prefix == null));
      }
      if (element is ClassElement) {
        collector.addSuggestion(_addExportedClassSuggestion(
            export,
            element.type,
            element.isEnum ? ElementKind.ENUM : ElementKind.CLASS,
            optype,
            relevance: DART_RELEVANCE_DEFAULT,
            withPrefix: prefix == null));
      }
    }
  }

  void addLocalVariables(CompletionCollector collector,
      Map<String, LocalVariable> localVars, OpType optype) {
    for (final eachVar in localVars.values) {
      collector.addSuggestion(_addLocalVariableSuggestion(eachVar,
          eachVar.dartVariable.type, ElementKind.LOCAL_VARIABLE, optype,
          relevance: DART_RELEVANCE_LOCAL_VARIABLE));
    }
  }

  @override
  Future<Null> computeSuggestions(
      AngularCompletionRequest request, CompletionCollector collector) async {
    final templates = request.templates;

    for (final template in templates) {
      final context = template
          .component.classElement.enclosingElement.enclosingElement.context;
      final typeProvider = context.typeProvider;
      final typeSystem = context.typeSystem;
      final dartSnippet = request.dartSnippet;

      if (dartSnippet != null) {
        final angularTarget = request.angularTarget;
        final completionTarget = request.completionTarget;

        final optype =
            defineOpType(completionTarget, request.offset, dartSnippet);
        final classElement = template.component.classElement;
        final libraryElement = classElement.library;

        final dartResolveResult = DartResolveResultShell(request.path,
            libraryElement: libraryElement,
            typeProvider: typeProvider,
            typeSystem: typeSystem);
        final dartRequest = DartCompletionRequestImpl(
            request.resourceProvider, request.offset, dartResolveResult);
        await _inheritedReferenceContributor.computeSuggestionsForClass(
            dartRequest, collector, classElement,
            entryPoint: dartSnippet,
            target: completionTarget,
            optype: optype,
            skipChildClass: false);

        if (optype.includeIdentifiers) {
          final varExtractor = LocalVariablesExtractor();
          angularTarget.accept(varExtractor);
          if (varExtractor.variables != null) {
            addLocalVariables(
              collector,
              varExtractor.variables,
              optype,
            );
          }

          addExportedPrefixSuggestions(collector, template.component);
        }

        {
          final entity = completionTarget.entity;
          final containingNode = completionTarget.containingNode;
          if (entity is SimpleIdentifier &&
              containingNode is PrefixedIdentifier &&
              entity == containingNode?.identifier) {
            addExportSuggestions(collector, template.component, optype,
                prefix: containingNode.prefix.name);
          } else {
            addExportSuggestions(collector, template.component, optype);
          }
        }
      }
    }
  }

  OpType defineOpType(CompletionTarget target, int offset, AstNode entryPoint) {
    final optype = OpType.forCompletion(target, offset);

    // if the containing node IS the AST, it means the context decides what's
    // completable. In that case, that's in our court only.
    if (target.containingNode == entryPoint) {
      optype
        ..includeReturnValueSuggestions = true
        ..includeTypeNameSuggestions = true
        // expressions always have nonvoid returns
        ..includeVoidReturnSuggestions = !(entryPoint is Expression);
    }

    // NG Expressions (not statements) always must return something. We have to
    // force that ourselves here.
    if (entryPoint is Expression) {
      optype.includeVoidReturnSuggestions = false;
    }
    return optype;
  }

  CompletionSuggestion _addExportedClassSuggestion(
          Export export, DartType typeName, ElementKind elemKind, OpType optype,
          {int relevance = DART_RELEVANCE_DEFAULT, bool withPrefix = true}) =>
      _createExportSuggestion(
          export, relevance, typeName, _createExportElement(export, elemKind),
          withPrefix: withPrefix);

  CompletionSuggestion _addExportedFunctionSuggestion(
      Export export, DartType typeName, ElementKind elemKind, OpType optype,
      {int relevance = DART_RELEVANCE_DEFAULT, bool withPrefix = true}) {
    final element = export.element as FunctionElement;
    // ignore: parameter_assignments
    relevance = optype.returnValueSuggestionsFilter(element.type, relevance) ??
        DART_RELEVANCE_DEFAULT;
    return _createExportSuggestion(
        export,
        relevance,
        typeName,
        _createExportFunctionElement(element, elemKind, typeName)
          ..returnType = typeName.toString(),
        withPrefix: withPrefix)
      ..returnType = element.returnType.toString()
      ..parameterNames = element.parameters.map((param) => param.name).toList()
      ..parameterTypes =
          element.parameters.map((param) => param.type.toString()).toList()
      ..requiredParameterCount =
          element.parameters.where((param) => param.hasRequired).length
      ..hasNamedParameters =
          element.parameters.any((param) => param.name != null);
  }

  CompletionSuggestion _addExportedGetterSuggestion(
      Export export, DartType typeName, ElementKind elemKind, OpType optype,
      {int relevance = DART_RELEVANCE_DEFAULT, bool withPrefix = true}) {
    final element = export.element as PropertyAccessorElement;
    // ignore: parameter_assignments
    relevance =
        optype.returnValueSuggestionsFilter(element.variable.type, relevance) ??
            DART_RELEVANCE_DEFAULT;
    return _createExportSuggestion(
        export,
        relevance,
        typeName,
        _createExportElement(export, elemKind)
          ..returnType = typeName.toString(),
        withPrefix: withPrefix)
      ..returnType = element.returnType.toString();
  }

  CompletionSuggestion _addExportedPrefixSuggestion(
          String prefix, LibraryElement library) =>
      _createExportedPrefixSuggestion(prefix, DART_RELEVANCE_DEFAULT,
          _createExportedPrefixElement(prefix, library));

  CompletionSuggestion _addLocalVariableSuggestion(LocalVariable variable,
      DartType typeName, ElementKind elemKind, OpType optype,
      {int relevance = DART_RELEVANCE_DEFAULT}) {
    // ignore: parameter_assignments
    relevance = optype.returnValueSuggestionsFilter(
            variable.dartVariable.type, relevance) ??
        DART_RELEVANCE_DEFAULT;
    return _createLocalSuggestion(variable, relevance, typeName,
        _createLocalElement(variable, elemKind, typeName));
  }

  Element _createExportedPrefixElement(String prefix, LibraryElement library) {
    final flags = Element.makeFlags();
    final location = Location(
        library.source.fullName, library.nameOffset, library.nameLength, 0, 0);
    return Element(ElementKind.LIBRARY, prefix, flags, location: location);
  }

  CompletionSuggestion _createExportedPrefixSuggestion(
          String prefix, int defaultRelevance, Element element) =>
      CompletionSuggestion(CompletionSuggestionKind.IDENTIFIER,
          defaultRelevance, prefix, prefix.length, 0, false, false,
          element: element);

  Element _createExportElement(Export export, ElementKind kind) {
    final name = export.name;
    final location = Location(export.element.source.fullName,
        export.element.nameOffset, export.element.nameLength, 0, 0);
    final flags = Element.makeFlags();
    return Element(kind, name, flags, location: location);
  }

  Element _createExportFunctionElement(
      FunctionElement element, ElementKind kind, DartType type) {
    final name = element.name;
    final parameterString = element.parameters.join(', ');
    final location = Location(
        element.source.fullName, element.nameOffset, element.nameLength, 0, 0);
    final flags = Element.makeFlags();
    return Element(kind, name, flags,
        location: location,
        returnType: type.toString(),
        parameters: '($parameterString)');
  }

  CompletionSuggestion _createExportSuggestion(
      Export export, int defaultRelevance, DartType type, Element element,
      {bool withPrefix = true}) {
    final completion = (export.prefix ?? '').isEmpty || !withPrefix
        ? export.name
        : '${export.prefix}.${export.name}';
    return CompletionSuggestion(CompletionSuggestionKind.INVOCATION,
        defaultRelevance, completion, completion.length, 0, false, false,
        element: element);
  }

  Element _createLocalElement(
      LocalVariable localVar, ElementKind kind, DartType type) {
    final name = localVar.name;
    final location = Location(localVar.source.fullName,
        localVar.navigationRange.offset, localVar.navigationRange.length, 0, 0);
    final flags = Element.makeFlags();
    return Element(kind, name, flags,
        location: location, returnType: type.toString());
  }

  CompletionSuggestion _createLocalSuggestion(LocalVariable localVar,
      int defaultRelevance, DartType type, Element element) {
    final completion = localVar.name;
    return CompletionSuggestion(CompletionSuggestionKind.INVOCATION,
        defaultRelevance, completion, completion.length, 0, false, false,
        returnType: type.toString(), element: element);
  }

  LibraryElement _getPrefixedImport(LibraryElement library, String prefix) =>
      library.imports
          .where((import) => import.prefix != null)
          .where((import) => import.prefix.name == prefix)
          .first
          .library;
}
