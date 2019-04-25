import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart' show TokenType;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/ast/token.dart'
    show SyntheticBeginToken, SyntheticToken;
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:angular_analyzer_plugin/ast.dart';
import 'package:angular_analyzer_plugin/src/converter.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/standard_components.dart';

class AngularCompletionRequest extends CompletionRequest {
  final List<Template> templates;
  final StandardHtml standardHtml;
  final String path;

  /// The targeted dart node, if the user is autocompleting a dart expression.
  ///
  /// Guaranteed to be unique (if it exists) for the given completion request.
  /// Therefore, lazy-calculate these fields.
  AstNode _dartSnippet;

  /// The targeted angular node, if the user is autocompleting html.
  ///
  /// Guaranteed to be unique (if it exists) for the given completion request.
  /// Therefore, lazy-calculate these fields.
  AngularAstNode _angularTarget;

  /// The dart [CompletionTarget] if the user is autocompleting dart.
  ///
  /// This is required by the dart completion contributors.
  ///
  /// Guaranteed to be unique (if it exists) for the given completion request.
  /// Therefore, lazy-calculate these fields.
  CompletionTarget _completionTarget;

  /// Flag checking if autocompletion targets have been calculated.
  ///
  /// Used to know if [_completionTarget], [_dartSnippet], and/or
  /// [_angularTarget] have been calculated. None that the lookup may fail and
  /// those fields may be left null, but calculation will not re-occur.
  var _entryPointCalculated = false;

  @override
  final int offset;

  @override
  final ResourceProvider resourceProvider;

  /// Flag indicating if completion has been aborted.
  bool _aborted = false;

  AngularCompletionRequest(this.offset, this.path, this.resourceProvider,
      List<Template> templates, this.standardHtml)
      : templates = templates
            .where((t) =>
                t.component.templateUrlSource != null ||
                (t.component.templateTextRange.contains(offset)))
            .toList() {
    for (final template in templates) {
      _calculateDartSnippet(template);
    }
  }

  AngularAstNode get angularTarget => _angularTarget;

  CompletionTarget get completionTarget => _completionTarget;

  AstNode get dartSnippet => _dartSnippet;

  /// Abort the current completion request.
  void abort() {
    _aborted = true;
  }

  @override
  void checkAborted() {
    if (_aborted) {
      // ignore: only_throw_errors
      throw AbortCompletion();
    }
  }

  AstNode _calculateDartSnippet(Template template) {
    if (!_entryPointCalculated) {
      _entryPointCalculated = true;
      final extractor = _CompletionTargetExtractor(offset);
      template.ast.accept(extractor);
      _dartSnippet = extractor.dartSnippet;
      _angularTarget = extractor.target;
      if (_dartSnippet != null) {
        if (_dartSnippet is Expression) {
          // wrap dart snippet in a ParenthesizedExpression, because the dart
          // completion engine expects all expressions to have parents.
          _dartSnippet = astFactory.parenthesizedExpression(
              SyntheticBeginToken(TokenType.OPEN_PAREN, _dartSnippet.offset)
                ..next = _dartSnippet.beginToken,
              _dartSnippet as Expression, // requires cast because reassigned
              SyntheticToken(TokenType.CLOSE_PAREN, _dartSnippet.end));
        }
        _completionTarget =
            CompletionTarget.forOffset(null, offset, entryPoint: _dartSnippet);
      }
    }
    return _dartSnippet;
  }
}

class _CompletionTargetExtractor implements AngularAstVisitor {
  AstNode dartSnippet;
  AngularAstNode target;
  final int offset;

  _CompletionTargetExtractor(this.offset);

  /// Explore the tree looking for the completion target, recursively.
  ///
  /// Check if the [node] contains a [child] node which contains the completion
  /// [offset]. If so, visit the [child] which likely will call this again.
  /// Otherwise, mark [node] as the [target].
  ///
  /// returns true if a [child] was selected, otherwise false.
  bool recurseToTarget(AngularAstNode node) {
    for (final child in node.children) {
      if (_offsetContained(offset, child.offset, child.length)) {
        child.accept(this);
        return true;
      }
    }

    target = node;
    return false;
  }

  @override
  void visitDocumentInfo(DocumentInfo document) {
    recurseToTarget(document);
  }

  @override
  void visitElementInfo(ElementInfo element) {
    // Don't choose tag two in `<tag-one<tag-two></tag-one>`
    if (_offsetContained(offset, element.openingNameSpan.offset,
        element.openingNameSpan.length)) {
      target = element;
      return;
    }

    recurseToTarget(element);
  }

  @override
  void visitEmptyStarBinding(EmptyStarBinding binding) {
    if (binding.isPrefix) {
      target = binding.parent;
    } else {
      visitTextAttr(binding);
    }
  }

  @override
  void visitExpressionBoundAttr(ExpressionBoundAttribute attr) {
    target = attr;
    if (attr.expression != null &&
        _offsetContained(
            offset, attr.expression.offset, attr.expression.length)) {
      dartSnippet = attr.expression;
    }
  }

  @override
  void visitMustache(Mustache mustache) {
    target = mustache;

    if (_offsetContained(
        offset, mustache.exprBegin, mustache.exprEnd - mustache.exprBegin)) {
      dartSnippet = mustache.expression;
    }
  }

  @override
  void visitStatementsBoundAttr(StatementsBoundAttribute attr) {
    target = attr;
    for (final statement in attr.statements) {
      if (_offsetContained(offset, statement.offset, statement.length)) {
        dartSnippet = statement;
      }
    }
  }

  @override
  void visitTemplateAttr(TemplateAttribute attr) {
    if (recurseToTarget(attr)) {
      return;
    }

    // if we visit this, we're in a template but after one of its attributes.
    AttributeInfo attributeToAppendTo;
    for (final subAttribute in attr.virtualAttributes) {
      if (subAttribute.valueOffset == null && subAttribute.offset < offset) {
        attributeToAppendTo = subAttribute;
      }
    }

    if (attributeToAppendTo != null &&
        attributeToAppendTo is EmptyStarBinding) {
      final analysisErrorListener = AnalysisErrorListener.NULL_LISTENER;
      final dartParser = EmbeddedDartParser(null, analysisErrorListener, null);
      dartSnippet =
          dartParser.parseDartExpression(offset, '', detectTrailing: false);
    }
  }

  @override
  void visitTextAttr(TextAttribute attr) {
    recurseToTarget(attr);
  }

  @override
  void visitTextInfo(TextInfo textInfo) {
    recurseToTarget(textInfo);
  }

  bool _offsetContained(int offset, int start, int length) =>
      start <= offset && start + length >= offset;
}
