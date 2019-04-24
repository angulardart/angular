import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:angular_analyzer_plugin/src/model/syntactic/annotated_class.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/component.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/content_child.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/directive.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/directive_base.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/functional_directive.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/ng_content.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/pipe.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/reference.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/top_level.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/input.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/output.dart';
import 'package:angular_analyzer_plugin/src/summary/format.dart';

/// Create a summary from the syntactic model of a dart file.
///
/// This summary can be cached for that dart file and linked to create the
/// resolved model. This is for a dart file which has dart top levels like
/// components, directives, and pipes, and inline templates. Also cache the
/// errors specific to creating a syntactic model from that dart file.
UnlinkedDartSummaryBuilder summarizeDartResult(
    List<TopLevel> topLevels, List<AnalysisError> errors) {
  final dirSums =
      _summarizeDirectives(topLevels.whereType<DirectiveBase>().toList());
  final pipeSums = _summarizePipes(topLevels.whereType<Pipe>().toList());
  final classSums = topLevels
      .whereType<AnnotatedClass>()
      .where((c) => c is! DirectiveBase)
      .map(_summarizeAnnotatedClass)
      .toList();
  final summary = UnlinkedDartSummaryBuilder()
    ..directiveSummaries = dirSums
    ..pipeSummaries = pipeSums
    ..annotatedClasses = classSums
    ..errors = summarizeErrors(errors);
  return summary;
}

/// Create a summary from the analysis errors of a file.
///
/// Dart and HTML files both will, in a fully resolved summary, contain
/// errors for that fully resolved state.
List<SummarizedAnalysisErrorBuilder> summarizeErrors(
        List<AnalysisError> errors) =>
    errors.map(summarizeError).toList();

/// Create a summary from a single analysis error.
///
/// This is used by [AngularDriver] to create linked html summaries, which
/// may have complicated [FromFilePrefixedError]s that have to be specially
/// summarized.
SummarizedAnalysisErrorBuilder summarizeError(AnalysisError error) =>
    SummarizedAnalysisErrorBuilder(
        offset: error.offset,
        length: error.length,
        errorCode: error.errorCode.uniqueName,
        message: error.message,
        correction: error.correction);

/// Create a summary from a set of [NgContent]s.
///
/// This is essentially the syntactic model of an HTML file. Since the
/// [NgContent]s of an html file may affect other analyses in other files, these
/// are summarized and cached to speed up those other analyses.
List<SummarizedNgContentBuilder> summarizeNgContents(
        List<NgContent> ngContents) =>
    ngContents
        .map((ngContent) => SummarizedNgContentBuilder()
          ..selectorStr = ngContent.selector?.originalString
          ..selectorOffset = ngContent.selector?.offset
          ..offset = ngContent.sourceRange.offset
          ..length = ngContent.sourceRange.length)
        .toList();

SummarizedBindableBuilder _summarizeInput(Input input) {
  final name = input.name;
  final nameOffset = input.nameRange.offset;
  final propName = input.setterName.replaceAll('=', '');
  final propNameOffset = input.setterRange.offset;
  return SummarizedBindableBuilder()
    ..name = name
    ..nameOffset = nameOffset
    ..propName = propName
    ..propNameOffset = propNameOffset;
}

SummarizedBindableBuilder _summarizeOutput(Output output) {
  final name = output.name;
  final nameOffset = output.nameRange.offset;
  final propName = output.getterName.replaceAll('=', '');
  final propNameOffset = output.getterRange.offset;
  return SummarizedBindableBuilder()
    ..name = name
    ..nameOffset = nameOffset
    ..propName = propName
    ..propNameOffset = propNameOffset;
}

SummarizedContentChildFieldBuilder _summarizeContentChildField(
        ContentChild childField) =>
    SummarizedContentChildFieldBuilder()
      ..fieldName = childField.fieldName
      ..nameOffset = childField.nameRange.offset
      ..nameLength = childField.nameRange.length
      ..typeOffset = childField.typeRange.offset
      ..typeLength = childField.typeRange.length;

SummarizedClassAnnotationsBuilder _summarizeAnnotatedClass(
    AnnotatedClass clazz) {
  final className = clazz.className;
  final inputs = clazz.inputs.map(_summarizeInput).toList();
  final outputs = clazz.outputs.map(_summarizeOutput).toList();
  final contentChildFields =
      clazz.contentChildFields.map(_summarizeContentChildField).toList();
  final contentChildrenFields =
      clazz.contentChildrenFields.map(_summarizeContentChildField).toList();
  return SummarizedClassAnnotationsBuilder()
    ..className = className
    ..inputs = inputs
    ..outputs = outputs
    ..contentChildFields = contentChildFields
    ..contentChildrenFields = contentChildrenFields;
}

List<SummarizedDirectiveBuilder> _summarizeDirectives(
    List<DirectiveBase> directives) {
  final dirSums = <SummarizedDirectiveBuilder>[];
  for (final directive in directives) {
    final selector = directive.selector.originalString;
    final selectorOffset = directive.selector.offset;
    final exports = directive is Component
        ? _summarizeExports(directive.exports)
        : <SummarizedExportedIdentifierBuilder>[];
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

      dirUseSums = _summarizeDirectiveReferences(directive.directives);
      pipeUseSums = _summarizePipeReferences(directive.pipes);

      if (directive.inlineNgContents != null) {
        ngContents.addAll(summarizeNgContents(directive.inlineNgContents));
      }
    }

    dirSums.add(SummarizedDirectiveBuilder()
      ..classAnnotations = directive is! FunctionalDirective
          ? _summarizeAnnotatedClass(directive as AnnotatedClass)
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

List<SummarizedPipeBuilder> _summarizePipes(List<Pipe> pipes) {
  final pipeSums = <SummarizedPipeBuilder>[];
  for (final pipe in pipes) {
    pipeSums.add(SummarizedPipeBuilder(
        pipeName: pipe.pipeName,
        pipeNameOffset: pipe.pipeNameRange.offset,
        decoratedClassName: pipe.className));
  }
  return pipeSums;
}

List<SummarizedDirectiveUseBuilder> _summarizeDirectiveReferences(
        ListOrReference directives) =>
    _toReferenceList(directives)
        .map((reference) => SummarizedDirectiveUseBuilder()
          ..name = reference.name
          ..prefix = reference.prefix
          ..offset = reference.range.offset
          ..length = reference.range.length)
        .toList();

List<SummarizedPipesUseBuilder> _summarizePipeReferences(
        ListOrReference pipes) =>
    _toReferenceList(pipes)
        .map((pipe) => SummarizedPipesUseBuilder()
          ..name = pipe.name
          ..prefix = pipe.prefix)
        .toList();

List<SummarizedExportedIdentifierBuilder> _summarizeExports(
        ListOrReference exports) =>
    _toReferenceList(exports)
        .map((export) => SummarizedExportedIdentifierBuilder()
          ..name = export.name
          ..prefix = export.prefix
          ..offset = export.range.offset
          ..length = export.range.length)
        .toList();

/// This is a sort of hack for backwards compatibility. The new syntactic model
/// has ListOrReference, which the summary model doesn't support. However, we
/// can treat references as a list of one reference. The only difference here is
/// we will fail to reject `pipes: myPipe` which should be either
/// `pipes: pipeList` or `pipes: [myPipe]`.
///
/// TODO(mfairhurst): does this matter? Does the analyzer catch that anyway?
/// Should the reference model be changed to just [List<Reference>]?
List<Reference> _toReferenceList(ListOrReference listOrReference) {
  if (listOrReference is Reference) {
    return [listOrReference];
  } else if (listOrReference is ListLiteral) {
    return listOrReference.items;
  } else if (listOrReference == null) {
    return [];
  }
  assert(false, 'unreachable');
  return [];
}
