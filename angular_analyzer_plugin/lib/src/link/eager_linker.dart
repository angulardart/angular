import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/generated/source.dart' show SourceRange, Source;
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/src/link/binding_type_resolver.dart';
import 'package:angular_analyzer_plugin/src/link/content_child_linker.dart';
import 'package:angular_analyzer_plugin/src/link/directive_provider.dart';
import 'package:angular_analyzer_plugin/src/link/export_linker.dart';
import 'package:angular_analyzer_plugin/src/link/sub_directive_linker.dart';
import 'package:angular_analyzer_plugin/src/link/sub_pipe_linker.dart';
import 'package:angular_analyzer_plugin/src/link/top_level_linker.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/model/navigable.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/ng_content.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';
import 'package:angular_analyzer_plugin/src/selector/element_name_selector.dart';
import 'package:angular_analyzer_plugin/src/standard_components.dart';
import 'package:angular_analyzer_plugin/src/summary/idl.dart';

/// Eagerly link+resolve summaries into the resolved model.
///
/// This is used by the lazy linker, as well as by the driver in order to force-
/// -calculate element resolution errors.
///
/// This currently uses [PartialLinker] with [ResolvePartialModel]. However,
/// in an ideal implementation, those would not be distinct stages, and the
/// linker would not be distinct from resolution. That behavior would then all
/// exist here.
///
/// During template resolution, this should be created with [linkHtmlNgContents]
/// to false, as those can be discovered during template resolution and would
/// otherwise occur multiple times.
class EagerLinker implements TopLevelLinker {
  final TypeSystem _typeSystem;
  final DirectiveProvider _directiveProvider;
  final StandardAngular _standardAngular;
  final ErrorReporter _errorReporter;
  final ExportLinker _exportLinker;
  final SubDirectiveLinker _subDirectiveLinker;
  final SubPipeLinker _subPipeLinker;
  final ContentChildLinker _contentChildLinker;
  final bool linkHtmlNgContents;

  EagerLinker(this._typeSystem, this._standardAngular,
      StandardHtml standardHtml, this._errorReporter, this._directiveProvider,
      {this.linkHtmlNgContents = true})
      : _exportLinker = ExportLinker(_errorReporter),
        _subDirectiveLinker =
            SubDirectiveLinker(_directiveProvider, _errorReporter),
        _subPipeLinker = SubPipeLinker(_directiveProvider, _errorReporter),
        _contentChildLinker = ContentChildLinker(
            _typeSystem, _directiveProvider, standardHtml, _errorReporter);

  /// Fully link an [AngularAnnotatedClass] from a summary and a [ClassElement].
  @override
  AnnotatedClass annotatedClass(
      SummarizedClassAnnotations classSum, ClassElement classElement) {
    final bindingSynthesizer = BindingTypeResolver(
        classElement,
        classElement.context.typeProvider,
        classElement.context,
        _errorReporter);

    final inputs = classSum.inputs
        .map((inputSum) => input(inputSum, classElement, bindingSynthesizer))
        .where((inputSum) => inputSum != null)
        .toList();
    final outputs = classSum.outputs
        .map((outputSum) => output(outputSum, classElement, bindingSynthesizer))
        .where((outputSum) => outputSum != null)
        .toList();
    final contentChildFields = classSum.contentChildFields
        .map((contentChildField) => _contentChildLinker
            .link(contentChildField, classElement, isSingular: true))
        .where((child) => child != null)
        .toList();
    final contentChildrenFields = classSum.contentChildrenFields
        .map((contentChildField) => _contentChildLinker
            .link(contentChildField, classElement, isSingular: false))
        .where((children) => children != null)
        .toList();

    return AnnotatedClass(classElement,
        inputs: inputs,
        outputs: outputs,
        contentChildFields: contentChildFields,
        contentChildrenFields: contentChildrenFields);
  }

  /// Partially link a [Component] from a summary and a [ClassElement].
  @override
  Component component(SummarizedDirective dirSum, ClassElement classElement) {
    assert(dirSum.isComponent);
    final directiveInfo = directive(dirSum, classElement);

    final scope = LibraryScope(classElement.library);
    final exports = dirSum.exports
        .map((export) => _exportLinker.link(export, classElement, scope))
        .toList();
    final pipes = <Pipe>[];
    dirSum.pipesUse
        .forEach((pipeSum) => _subPipeLinker.link(pipeSum, scope, pipes));
    final subDirectives = <DirectiveBase>[];
    dirSum.subdirectives.forEach(
        (dirSum) => _subDirectiveLinker.link(dirSum, scope, subDirectives));
    Source templateUrlSource;
    SourceRange templateUrlRange;
    final ngContents = <NgContent>[];
    if (dirSum.templateUrl != '') {
      templateUrlSource = classElement.context.sourceFactory
          .resolveUri(classElement.library.source, dirSum.templateUrl);
      templateUrlRange =
          SourceRange(dirSum.templateUrlOffset, dirSum.templateUrlLength);
      if (templateUrlSource == null || !templateUrlSource.exists()) {
        _errorReporter.reportErrorForOffset(
          AngularWarningCode.REFERENCED_HTML_FILE_DOESNT_EXIST,
          dirSum.templateUrlOffset,
          dirSum.templateUrlLength,
        );
      } else if (linkHtmlNgContents) {
        ngContents.addAll(
            _directiveProvider.getHtmlNgContent(templateUrlSource.fullName));
      }
    }

    ngContents.addAll(dirSum.ngContents
        .map((ngContentSum) => ngContent(ngContentSum, directiveInfo.source)));

    return Component(
      classElement,
      attributes: _collectAttributes(classElement),
      isHtml: false,
      ngContents: ngContents,
      templateText: dirSum.templateText,
      templateTextRange:
          SourceRange(dirSum.templateOffset, dirSum.templateText.length),
      templateUrlSource: templateUrlSource,
      templateUrlRange: templateUrlRange,
      directives: subDirectives,
      exports: exports,
      pipes: pipes,
      contentChildFields: directiveInfo.contentChildFields,
      contentChildrenFields: directiveInfo.contentChildrenFields,
      exportAs: directiveInfo.exportAs,
      selector: directiveInfo.selector,
      inputs: directiveInfo.inputs,
      outputs: directiveInfo.outputs,
      looksLikeTemplate: directiveInfo.looksLikeTemplate,
    );
  }

  /// Partially link [Directive] from summary and [ClassElement].
  @override
  Directive directive(SummarizedDirective dirSum, ClassElement classElement) {
    assert(dirSum.functionName == "");

    final selector = SelectorParser(
            classElement.source, dirSum.selectorOffset, dirSum.selectorStr)
        .parse();
    final elementTags = <ElementNameSelector>[];
    final source = classElement.source;
    selector.recordElementNameSelectors(elementTags);
    final bindingSynthesizer = BindingTypeResolver(
        classElement,
        classElement.context.typeProvider,
        classElement.context,
        _errorReporter);

    final exportAs = dirSum.exportAs == ""
        ? null
        : NavigableString(dirSum.exportAs,
            SourceRange(dirSum.exportAsOffset, dirSum.exportAs.length), source);
    final inputs = dirSum.classAnnotations.inputs
        .map((inputSum) => input(inputSum, classElement, bindingSynthesizer))
        .where((inputSum) => inputSum != null)
        .toList();
    final outputs = dirSum.classAnnotations.outputs
        .map((outputSum) => output(outputSum, classElement, bindingSynthesizer))
        .where((outputSum) => outputSum != null)
        .toList();
    final contentChildFields = dirSum.classAnnotations.contentChildFields
        .map((contentChildField) => _contentChildLinker
            .link(contentChildField, classElement, isSingular: true))
        .where((child) => child != null)
        .toList();
    final contentChildrenFields = dirSum.classAnnotations.contentChildrenFields
        .map((contentChildField) => _contentChildLinker
            .link(contentChildField, classElement, isSingular: false))
        .where((children) => children != null)
        .toList();

    for (final supertype in classElement.allSupertypes) {
      final annotatedClass =
          _directiveProvider.getAngularTopLevel(supertype.element);

      // A top-level may be a pipe which does not have inputs/outputs
      if (annotatedClass is AnnotatedClass) {
        inputs.addAll(annotatedClass.inputs.map(
            (input) => _inheritInput(input, classElement, bindingSynthesizer)));
        outputs.addAll(annotatedClass.outputs.map((output) =>
            _inheritOutput(output, classElement, bindingSynthesizer)));
        contentChildFields.addAll(annotatedClass.contentChildFields);
        contentChildrenFields.addAll(annotatedClass.contentChildrenFields);
      }
    }

    return Directive(
      classElement,
      exportAs: exportAs,
      selector: selector,
      looksLikeTemplate: classElement.constructors.any((constructor) =>
          constructor.parameters
              .any((param) => param.type == _standardAngular.templateRef.type)),
      inputs: inputs,
      outputs: outputs,
      contentChildFields: contentChildFields,
      contentChildrenFields: contentChildrenFields,
    );
  }

  /// Partially link [FunctionalDirective] from summary and [FunctionEement].
  @override
  FunctionalDirective functionalDirective(
      SummarizedDirective dirSum, FunctionElement functionElement) {
    final selector = SelectorParser(
            functionElement.source, dirSum.selectorOffset, dirSum.selectorStr)
        .parse();
    assert(dirSum.functionName != "");
    assert(dirSum.classAnnotations == null);
    assert(dirSum.exportAs == "");
    assert(dirSum.isComponent == false);

    return FunctionalDirective(functionElement, selector,
        looksLikeTemplate: functionElement.parameters
            .any((param) => param.type == _standardAngular.templateRef.type));
  }

  /// Fully link an [Input] from a summary and a [ClassElement].
  Input input(SummarizedBindable inputSum, ClassElement classElement,
      BindingTypeResolver bindingSynthesizer) {
    // is this correct lookup?
    final setter =
        classElement.lookUpSetter(inputSum.propName, classElement.library);
    if (setter == null) {
      _errorReporter.reportErrorForOffset(
          AngularWarningCode.INPUT_ANNOTATION_PLACEMENT_INVALID,
          inputSum.nameOffset,
          inputSum.name.length,
          [inputSum.name]);
      return null;
    }
    return Input(
        name: inputSum.name,
        nameRange: SourceRange(inputSum.nameOffset, inputSum.name.length),
        setter: setter,
        setterType: bindingSynthesizer
            .getSetterType(setter)); // Don't think type is correct
  }

  NgContent ngContent(SummarizedNgContent ngContentSum, Source source) {
    final selector = ngContentSum.selectorStr == ""
        ? null
        : SelectorParser(
                source, ngContentSum.selectorOffset, ngContentSum.selectorStr)
            .parse();
    return NgContent.withSelector(
        SourceRange(ngContentSum.offset, ngContentSum.length),
        selector,
        SourceRange(selector?.offset, ngContentSum.selectorStr.length));
  }

  /// Fully link an [Output] from a summary and a [ClassElement].
  Output output(SummarizedBindable outputSum, ClassElement classElement,
      BindingTypeResolver bindingSynthesizer) {
    // is this correct lookup?
    final getter =
        classElement.lookUpGetter(outputSum.propName, classElement.library);
    if (getter == null) {
      return null;
    }
    return Output(
        name: outputSum.name,
        nameRange: SourceRange(outputSum.nameOffset, outputSum.name.length),
        getter: getter,
        eventType: bindingSynthesizer.getEventType(getter, getter.name));
  }

  /// Fully link a [Pipe] from a summary and a [ClassElement].
  @override
  Pipe pipe(SummarizedPipe pipeSum, ClassElement classElement) {
    // Check if 'extends PipeTransform' exists.
    if (!_typeSystem.isSubtypeOf(
        classElement.type, _standardAngular.pipeTransform.type)) {
      _errorReporter.reportErrorForOffset(
          AngularWarningCode.PIPE_REQUIRES_PIPETRANSFORM,
          pipeSum.pipeNameOffset,
          pipeSum.pipeName.length);
    }

    final transformMethod =
        classElement.lookUpMethod('transform', classElement.library);
    DartType requiredArgumentType;
    DartType transformReturnType;
    final optionalArgumentTypes = <DartType>[];

    if (transformMethod == null) {
      _errorReporter.reportErrorForElement(
          AngularWarningCode.PIPE_REQUIRES_TRANSFORM_METHOD, classElement);
    } else {
      transformReturnType = transformMethod.returnType;
      final parameters = transformMethod.parameters;
      if (parameters == null || parameters.isEmpty) {
        _errorReporter.reportErrorForElement(
            AngularWarningCode.PIPE_TRANSFORM_REQ_ONE_ARG, transformMethod);
      }
      for (final parameter in parameters) {
        // If named or positional
        if (parameter.isNamed) {
          _errorReporter.reportErrorForElement(
              AngularWarningCode.PIPE_TRANSFORM_NO_NAMED_ARGS, parameter);
          continue;
        }
        if (parameters.first == parameter) {
          requiredArgumentType = parameter.type;
        } else {
          optionalArgumentTypes.add(parameter.type);
        }
      }
    }
    return Pipe(
        pipeSum.pipeName,
        SourceRange(pipeSum.pipeNameOffset, pipeSum.pipeName.length),
        classElement,
        requiredArgumentType: requiredArgumentType,
        transformReturnType: transformReturnType,
        optionalArgumentTypes: optionalArgumentTypes);
  }

  List<NavigableString> _collectAttributes(ClassElement classElement) {
    final result = <NavigableString>[];
    for (final constructor in classElement.constructors) {
      for (final parameter in constructor.parameters) {
        for (final annotation in parameter.metadata) {
          if (annotation.element?.enclosingElement?.name != "Attribute") {
            continue;
          }

          final attributeName = annotation
              .computeConstantValue()
              ?.getField("attributeName")
              ?.toStringValue();
          if (attributeName == null) {
            continue;
            // TODO do we ever need to report an error here, or will DAS?
          }

          if (parameter.type.name != "String") {
            _errorReporter.reportErrorForOffset(
                AngularWarningCode.ATTRIBUTE_PARAMETER_MUST_BE_STRING,
                parameter.nameOffset,
                parameter.name.length);
          }

          result.add(NavigableString(
              attributeName,
              SourceRange(parameter.nameOffset, parameter.nameLength),
              parameter.source));
        }
      }
    }
    return result;
  }

  Input _inheritInput(Input input, ClassElement classElement,
      BindingTypeResolver bindingSynthesizer) {
    final setter = classElement.lookUpSetter(
        input.setter.displayName, classElement.library);
    if (setter == null) {
      _errorReporter.reportErrorForOffset(
          AngularWarningCode.INPUT_ANNOTATION_PLACEMENT_INVALID,
          input.nameRange.offset,
          input.nameRange.length,
          [input.name]);
      return input;
    }
    return Input(
        name: input.name,
        nameRange: input.nameRange,
        setter: setter,
        setterType: bindingSynthesizer.getSetterType(setter));
  }

  Output _inheritOutput(Output output, ClassElement classElement,
      BindingTypeResolver bindingSynthesizer) {
    final getter =
        classElement.lookUpGetter(output.getter.name, classElement.library);
    if (getter == null) {
      // Happens when an interface with an output isn't implemented correctly.
      // This will be accompanied by a dart error, so we can just return the
      // original without transformation to prevent cascading errors.
      return output;
    }
    return Output(
        name: output.name,
        nameRange: output.nameRange,
        getter: getter,
        eventType: bindingSynthesizer.getEventType(getter, output.name));
  }
}
