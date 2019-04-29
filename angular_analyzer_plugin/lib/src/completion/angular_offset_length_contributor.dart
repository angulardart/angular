import 'dart:async';

import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:angular_analyzer_plugin/src/completion/offset_contained.dart';
import 'package:angular_analyzer_plugin/src/completion/request.dart';
import 'package:angular_analyzer_plugin/ast.dart';

/// Sets the replacement range on the completion collector for the suggestions.
///
/// Unlike most contributors which add suggestions, this performs the very
/// important job of telling the IDE which characters should be replaced with
/// those suggestions.
class AngularOffsetLengthContributor extends CompletionContributor {
  @override
  Future<Null> computeSuggestions(
      AngularCompletionRequest request, CompletionCollector collector) async {
    final replacementRangeCalculator = ReplacementRangeCalculator(request);
    final dartSnippet = request.dartSnippet;
    request.angularTarget?.accept(replacementRangeCalculator);
    if (dartSnippet != null) {
      final range =
          request.completionTarget.computeReplacementRange(request.offset);
      collector
        ..offset = range.offset
        ..length = range.length;
    } else if (request.angularTarget != null) {
      collector
        ..offset = replacementRangeCalculator.offset
        ..length = replacementRangeCalculator.length;
    }
  }
}

/// A visitor to calculate the replacement range based on the target offset.
///
/// This does not handle replacement ranges for dart expressions. Only HTML
/// replacement ranges.
///
/// Note that the replacement offset may differ from the request offset, as in
/// `<foo^` where `^` represents the cursor. Here, the suggestions would be tags
/// such as `<foo-component`, the replacement offset would be 0, and the
/// replacement length would be 4.
class ReplacementRangeCalculator implements AngularAstVisitor {
  /// Begins as the target offset of the completion, and gets set to the correct
  /// completion offset.
  int offset;

  /// The replacement range length.
  int length = 0;

  ReplacementRangeCalculator(CompletionRequest request) {
    offset = request.offset;
  }

  @override
  void visitDocumentInfo(DocumentInfo document) {}

  @override
  void visitElementInfo(ElementInfo element) {
    if (element.openingSpan == null) {
      return;
    }
    final nameSpanEnd =
        element.openingNameSpan.offset + element.openingNameSpan.length;
    if (offsetContained(offset, element.openingSpan.offset,
        nameSpanEnd - element.openingSpan.offset)) {
      offset = element.openingSpan.offset;
      length = element.localName.length + 1;
    }
  }

  @override
  void visitEmptyStarBinding(EmptyStarBinding binding) =>
      visitTextAttr(binding);

  @override
  void visitExpressionBoundAttr(ExpressionBoundAttribute attr) {
    if (offsetContained(
        offset, attr.originalNameOffset, attr.originalName.length)) {
      offset = attr.originalNameOffset;
      length = attr.originalName.length;
    }
  }

  @override
  void visitMustache(Mustache mustache) {}

  @override
  void visitStatementsBoundAttr(StatementsBoundAttribute attr) {
    if (offsetContained(
        offset, attr.originalNameOffset, attr.originalName.length)) {
      offset = attr.originalNameOffset;
      length = attr.originalName.length;
    }
  }

  @override
  void visitTemplateAttr(TemplateAttribute attr) {
    if (offsetContained(
        offset, attr.originalNameOffset, attr.originalName.length)) {
      offset = attr.originalNameOffset;
      length = attr.originalName.length;
    }
  }

  @override
  void visitTextAttr(TextAttribute attr) {
    if (attr.parent is TemplateAttribute && attr.name.startsWith('let-')) {
      return;
    }
    final inValueScope = attr.isReference &&
        attr.value != null &&
        offsetContained(offset, attr.valueOffset, attr.valueLength);
    offset = inValueScope ? attr.valueOffset : attr.offset;
    length = inValueScope ? attr.valueLength : attr.length;
  }

  @override
  void visitTextInfo(TextInfo textInfo) {
    if (offset > textInfo.offset &&
        textInfo.text[offset - textInfo.offset - 1] == '<') {
      offset--;
      length = 1;
    }
  }
}
