import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:angular_analyzer_plugin/src/angular_driver.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/annotated_class.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/component.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/directive.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/directive_base.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/functional_directive.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/ng_content.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/pipe.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/reference.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/top_level.dart';
import 'package:angular_analyzer_plugin/src/summary/format.dart';
import 'package:angular_analyzer_plugin/src/summary/idl.dart';

SummarizedClassAnnotationsBuilder summarizeAnnotatedClass(
    AnnotatedClass clazz) {
  final className = clazz.className;
  final inputs = <SummarizedBindableBuilder>[];
  final outputs = <SummarizedBindableBuilder>[];
  final contentChildFields = <SummarizedContentChildFieldBuilder>[];
  final contentChildrenFields = <SummarizedContentChildFieldBuilder>[];
  for (final input in clazz.inputs) {
    final name = input.name;
    final nameOffset = input.nameRange.offset;
    final propName = input.setterName.replaceAll('=', '');
    final propNameOffset = input.setterRange.offset;
    inputs.add(new SummarizedBindableBuilder()
      ..name = name
      ..nameOffset = nameOffset
      ..propName = propName
      ..propNameOffset = propNameOffset);
  }
  for (final output in clazz.outputs) {
    final name = output.name;
    final nameOffset = output.nameRange.offset;
    final propName = output.getterName.replaceAll('=', '');
    final propNameOffset = output.getterRange.offset;
    outputs.add(new SummarizedBindableBuilder()
      ..name = name
      ..nameOffset = nameOffset
      ..propName = propName
      ..propNameOffset = propNameOffset);
  }
  for (final childField in clazz.contentChildFields) {
    contentChildFields.add(new SummarizedContentChildFieldBuilder()
      ..fieldName = childField.fieldName
      ..nameOffset = childField.nameRange.offset
      ..nameLength = childField.nameRange.length
      ..typeOffset = childField.typeRange.offset
      ..typeLength = childField.typeRange.length);
  }
  for (final childrenField in clazz.contentChildrenFields) {
    contentChildrenFields.add(new SummarizedContentChildFieldBuilder()
      ..fieldName = childrenField.fieldName
      ..nameOffset = childrenField.nameRange.offset
      ..nameLength = childrenField.nameRange.length
      ..typeOffset = childrenField.typeRange.offset
      ..typeLength = childrenField.typeRange.length);
  }
  return new SummarizedClassAnnotationsBuilder()
    ..className = className
    ..inputs = inputs
    ..outputs = outputs
    ..contentChildFields = contentChildFields
    ..contentChildrenFields = contentChildrenFields;
}

UnlinkedDartSummaryBuilder summarizeDartResult(
    List<TopLevel> topLevels, List<AnalysisError> errors) {
  final dirSums =
      summarizeDirectives(topLevels.whereType<DirectiveBase>().toList());
  final pipeSums = summarizePipes(topLevels.whereType<Pipe>().toList());
  final classSums = topLevels
      .whereType<AnnotatedClass>()
      .where((c) => c is! DirectiveBase)
      .map(summarizeAnnotatedClass)
      .toList();
  final summary = new UnlinkedDartSummaryBuilder()
    ..directiveSummaries = dirSums
    ..pipeSummaries = pipeSums
    ..annotatedClasses = classSums
    ..errors = summarizeErrors(errors);
  return summary;
}

List<SummarizedDirectiveBuilder> summarizeDirectives(
    List<DirectiveBase> directives) {
  final dirSums = <SummarizedDirectiveBuilder>[];
  for (final directive in directives) {
    final selector = directive.selector.originalString;
    final selectorOffset = directive.selector.offset;
    final exports = <SummarizedExportedIdentifierBuilder>[];
    if (directive is Component) {
      for (final export in toReferenceList(directive.exports)) {
        exports.add(new SummarizedExportedIdentifierBuilder()
          ..name = export.name
          ..prefix = export.prefix
          ..offset = export.range.offset
          ..length = export.range.length);
      }
    }
    List<SummarizedDirectiveUseBuilder> dirUseSums;
    List<SummarizedPipesUseBuilder> pipeUseSums;
    final ngContents = <SummarizedNgContentBuilder>[];
    String templateUrl;
    int templateUrlOffset;
    int templateUrlLength;
    String templateText;
    int templateTextOffset;
    SourceRange constDirectivesSourceRange;
    String exportAs;
    int exportAsOffset;
    if (directive is Directive) {
      exportAs = directive?.exportAs;
      exportAsOffset = directive?.exportAsRange?.offset;
    }
    if (directive is Component) {
      templateUrl = directive.templateUrl;
      templateUrlOffset = directive.templateUrlRange?.offset;
      templateUrlLength = directive.templateUrlRange?.length;
      templateText = directive.templateText;
      templateTextOffset = directive.templateTextRange?.offset;

      final subdirectives = directive.directives;
      dirUseSums = subdirectives is ListLiteral
          ? subdirectives.items
              .map((reference) => new SummarizedDirectiveUseBuilder()
                ..name = reference.name
                ..prefix = reference.prefix
                ..offset = reference.range.offset
                ..length = reference.range.length)
              .toList()
          : null;

      // TODO(mfairhurst): replace "const directives" concept with
      // [ReferenceOrList] concept. See [toReferenceList] for details.
      constDirectivesSourceRange =
          subdirectives is Reference ? subdirectives.range : null;

      pipeUseSums = toReferenceList(directive.pipes)
          .map((pipe) => new SummarizedPipesUseBuilder()
            ..name = pipe.name
            ..prefix = pipe.prefix)
          .toList();

      if (directive.inlineNgContents != null) {
        ngContents.addAll(summarizeNgContents(directive.inlineNgContents));
      }
    }

    dirSums.add(new SummarizedDirectiveBuilder()
      ..classAnnotations = directive is! FunctionalDirective
          ? summarizeAnnotatedClass(directive as AnnotatedClass)
          : null
      ..isComponent = directive is Component
      ..functionName =
          directive is FunctionalDirective ? directive.functionName : null
      ..selectorStr = selector
      ..selectorOffset = selectorOffset
      ..exportAs = exportAs
      ..exportAsOffset = exportAsOffset
      ..templateText = templateText
      ..templateOffset = templateTextOffset
      ..templateUrl = templateUrl
      ..templateUrlOffset = templateUrlOffset
      ..templateUrlLength = templateUrlLength
      ..ngContents = ngContents
      ..exports = exports
      ..usesArrayOfDirectiveReferencesStrategy = dirUseSums != null
      ..subdirectives = dirUseSums
      ..pipesUse = pipeUseSums
      ..constDirectiveStrategyOffset = constDirectivesSourceRange?.offset
      ..constDirectiveStrategyLength = constDirectivesSourceRange?.length);
  }

  return dirSums;
}

SummarizedAnalysisErrorBuilder summarizeError(AnalysisError error) =>
    new SummarizedAnalysisErrorBuilder(
        offset: error.offset,
        length: error.length,
        errorCode: error.errorCode.uniqueName,
        message: error.message,
        correction: error.correction);

List<SummarizedAnalysisErrorBuilder> summarizeErrors(
        List<AnalysisError> errors) =>
    errors.map(summarizeError).toList();

List<SummarizedNgContentBuilder> summarizeNgContents(
        List<NgContent> ngContents) =>
    ngContents
        .map((ngContent) => new SummarizedNgContentBuilder()
          ..selectorStr = ngContent.selector?.originalString
          ..selectorOffset = ngContent.selector?.offset
          ..offset = ngContent.sourceRange.offset
          ..length = ngContent.sourceRange.length)
        .toList();

List<SummarizedPipeBuilder> summarizePipes(List<Pipe> pipes) {
  final pipeSums = <SummarizedPipeBuilder>[];
  for (final pipe in pipes) {
    pipeSums.add(new SummarizedPipeBuilder(
        pipeName: pipe.pipeName,
        pipeNameOffset: pipe.pipeNameRange.offset,
        decoratedClassName: pipe.className));
  }
  return pipeSums;
}

/// This is a sort of hack for backwards compatibility. The new syntactic model
/// has ListOrReference, which the summary model doesn't support. However, we
/// can treat references as a list of one reference. The only difference here is
/// we will fail to reject `pipes: myPipe` which should be either
/// `pipes: pipeList` or `pipes: [myPipe]`.
///
/// TODO(mfairhurst): does this matter? Does the analyzer catch that anyway?
/// Should the reference model be changed to just [List<Reference>]?
List<Reference> toReferenceList(ListOrReference listOrReference) {
  if (listOrReference is Reference) {
    return [listOrReference];
  } else if (listOrReference is ListLiteral) {
    return listOrReference.items;
  } else if (listOrReference == null) {
    return [];
  }
  throw 'unreachable';
}
