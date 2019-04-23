import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/utilities.dart' as utils;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/ast.dart';
import 'package:angular_analyzer_plugin/src/angular_ast_extraction.dart';
import 'package:angular_analyzer_plugin/src/converter.dart';
import 'package:angular_analyzer_plugin/src/ignoring_error_listener.dart';
import 'package:angular_analyzer_plugin/src/model/navigable.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/annotated_class.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/component.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/content_child.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/directive.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/functional_directive.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/input.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/ng_content.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/output.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/pipe.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/reference.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/top_level.dart';
import 'package:angular_analyzer_plugin/src/offsetting_constant_evaluator.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';
import 'package:angular_analyzer_plugin/src/selector/and_selector.dart';

/// Code to extract an angular definition from a raw (unresolved) AST.
class SyntacticDiscovery extends _AnnotationProcessorMixin {
  final ast.CompilationUnit _unit;
  final Source _source;

  /// The class being used to create the current component.
  ///
  /// Stored here for convenience, instead of being passed around everywhere.
  String _currentClassName;

  SyntacticDiscovery(this._unit, this._source) {
    initAnnotationProcessor(_source);
  }

  List<TopLevel> discoverTopLevels() {
    final declarations = <TopLevel>[];
    for (final unitMember in _unit.declarations) {
      if (unitMember is ast.ClassDeclaration) {
        final directive = _getAnnotatedClass(unitMember);
        if (directive != null) {
          declarations.add(directive);
        }
        for (final annotationNode in unitMember.metadata) {
          final pipe = _createPipe(unitMember, annotationNode);
          if (pipe != null) {
            declarations.add(pipe);
          }
        }
      } else if (unitMember is ast.FunctionDeclaration) {
        final directive = _getFunctionalDirective(unitMember);
        if (directive != null) {
          declarations.add(directive);
        }
      }
    }

    return declarations;
  }

  ListOrReference findReferences(ast.Expression listExpression,
      {ErrorCode unexpectedNodeError =
          AngularWarningCode.TYPE_LITERAL_EXPECTED}) {
    if (listExpression is ast.ListLiteral) {
      final directiveReferences = <Reference>[];
      for (final item in listExpression.elements) {
        if (item is ast.Identifier) {
          var name = item.name;
          var prefix = "";
          if (item is ast.PrefixedIdentifier) {
            name = item.identifier.name;
            prefix = item.prefix.name;
          }
          // LIST_OF_DIRECTIVES or TypeLiteral
          directiveReferences.add(
              Reference(name, prefix, SourceRange(item.offset, item.length)));
          continue;
        }
        // unknown
        errorReporter.reportErrorForNode(unexpectedNodeError, item);
      }
      return ListLiteral(directiveReferences);
    } else if (listExpression is ast.SimpleIdentifier) {
      return Reference(listExpression.name, null,
          SourceRange(listExpression?.offset, listExpression?.length));
    } else if (listExpression is ast.PrefixedIdentifier) {
      return Reference(
          listExpression.identifier.name,
          listExpression.prefix.name,
          SourceRange(listExpression?.offset, listExpression?.length));
    } else if (listExpression != null) {
      errorReporter.reportErrorForNode(unexpectedNodeError, listExpression);
    }
    return null;
  }

  ParsedTemplateText getTemplateText(ast.Annotation annotation) {
    // Try to find inline "template".
    String templateText;
    var templateOffset = 0;
    List<NgContent> inlineNgContents;
    final expression = getNamedArgument(annotation, 'template');
    if (expression == null) {
      return null;
    }
    templateOffset = expression.offset;
    final constantEvaluation = calculateStringWithOffsets(expression);

    // highly dynamically generated constant expressions can't be validated
    if (constantEvaluation == null ||
        !constantEvaluation.offsetsAreValid ||
        constantEvaluation.value is! String) {
      templateText = '';
    } else {
      templateText = constantEvaluation.value as String;
      inlineNgContents = [];
      final tplParser = TemplateParser()
        ..parse(templateText, _source, offset: templateOffset);

      final ignoringErrorListener = IgnoringErrorListener();
      final ignoringErrorReporter =
          ErrorReporter(ignoringErrorListener, _source);
      final parser = EmbeddedDartParser(
          _source, ignoringErrorListener, ignoringErrorReporter);

      HtmlTreeConverter(parser, _source, ignoringErrorListener)
          .convertFromAstList(tplParser.rawAst)
          .accept(NgContentRecorder(
              inlineNgContents, _source, ignoringErrorReporter));
    }

    return ParsedTemplateText(templateText,
        SourceRange(templateOffset, templateText.length), inlineNgContents);
  }

  ParsedTemplateUrl getTemplateUrl(ast.Annotation annotation) {
    // Template in a separate HTML file.
    final templateUrlExpression = getNamedArgument(annotation, 'templateUrl');
    final templateUrl = getExpressionString(templateUrlExpression);
    if (templateUrl == null) {
      return null;
    }

    final templateUrlRange =
        SourceRange(templateUrlExpression.offset, templateUrlExpression.length);

    return ParsedTemplateUrl(templateUrl, templateUrlRange);
  }

  void validateTemplateTypes(ast.Annotation annotation, Object templateUrlInfo,
      Object templateTextInfo) {
    if (templateUrlInfo != null && templateTextInfo != null) {
      errorReporter.reportErrorForNode(
          AngularWarningCode.TEMPLATE_URL_AND_TEMPLATE_DEFINED, annotation);

      return null;
    }

    if (templateUrlInfo == null && templateTextInfo == null) {
      errorReporter.reportErrorForNode(
          AngularWarningCode.NO_TEMPLATE_URL_OR_TEMPLATE_DEFINED, annotation);

      return null;
    }
  }

  /// Returns an Angular [Pipe] for the given [node].
  ///
  /// Returns `null` if not an Angular @Pipe annotation.
  Pipe _createPipe(ast.ClassDeclaration classDeclaration, ast.Annotation node) {
    if (isAngularAnnotation(node, 'Pipe')) {
      String pipeName;
      int pipeNameOffset;
      ast.Expression pipeNameExpression;

      // TODO(mfairhurst): load pipe name from the element model
      if (node.arguments != null && node.arguments.arguments.isNotEmpty) {
        pipeNameExpression = node.arguments.arguments.first;
        if (pipeNameExpression != null) {
          final constantEvaluation =
              calculateStringWithOffsets(pipeNameExpression);
          if (constantEvaluation != null &&
              constantEvaluation.value is String) {
            pipeName = (constantEvaluation.value as String).trim();
            pipeNameOffset = pipeNameExpression.offset;
          }
        }
      }

      if (pipeName == null) {
        errorReporter.reportErrorForNode(
            AngularWarningCode.PIPE_SINGLE_NAME_REQUIRED, node);
      }

      if (classDeclaration.abstractKeyword != null) {
        errorReporter.reportErrorForNode(
            AngularWarningCode.PIPE_CANNOT_BE_ABSTRACT, node);
      }

      return Pipe(pipeName, SourceRange(pipeNameOffset, pipeName?.length),
          classDeclaration.name.name, _source);
    }
    return null;
  }

  /// Find duplicate exports, and report them as errors.
  ///
  /// Note that unlike pipes and directives, duplicating exports is a completely
  /// syntactic error. Lists are not expanded, so `[foo, listContainingFoo]` is
  /// not a duplicate. And while `[sameFoo, prefixed.sameFoo]` is dubious, it's
  /// valid dart that exports the same reference under two names. Only
  /// `[foo, foo]` or `[p.foo, p.foo]` are duplicates, and that can be detected
  /// as such here.
  void _findDuplicateExports(ListOrReference exports) {
    if (exports is! ListLiteral) {
      return;
    }

    final exportSet = <String>{};

    for (final export in (exports as ListLiteral).items) {
      final asString = '${export.prefix}.${export.name}';
      if (exportSet.contains(asString)) {
        errorReporter.reportErrorForOffset(AngularWarningCode.DUPLICATE_EXPORT,
            export.range.offset, export.range.length, [export.name]);
      } else {
        exportSet.add(asString);
      }
    }
  }

  /// Returns an Angular [AnnotatedClass] for to the given [node].
  ///
  /// Returns `null` if class does not have any angular concepts.
  AnnotatedClass _getAnnotatedClass(ast.ClassDeclaration classDeclaration) {
    _currentClassName = classDeclaration.name.name;
    final componentNode = classDeclaration.metadata.firstWhere(
        (ann) => isAngularAnnotation(ann, 'Component'),
        orElse: () => null);
    final directiveNode = classDeclaration.metadata.firstWhere(
        (ann) => isAngularAnnotation(ann, 'Directive'),
        orElse: () => null);
    final annotationNode = componentNode ?? directiveNode;

    final inputs = <Input>[];
    final outputs = <Output>[];
    final contentChildFields = <ContentChild>[];
    final contentChildrenFields = <ContentChild>[];
    _parseContentChilds(
        classDeclaration, contentChildFields, contentChildrenFields);

    if (annotationNode != null) {
      // Don't fail to create a Component just because of a broken or missing
      // selector, that results in cascading errors.
      final selector = _parseSelector(annotationNode) ?? AndSelector([]);
      final exportAs = _parseExportAs(annotationNode);
      _parseMemberInputsAndOutputs(classDeclaration, inputs, outputs);
      if (componentNode != null) {
        final templateUrlInfo = getTemplateUrl(annotationNode);
        final templateTextInfo = getTemplateText(annotationNode);

        validateTemplateTypes(
            annotationNode, templateUrlInfo, templateTextInfo);

        final directives =
            findReferences(getNamedArgument(annotationNode, 'directives'));
        final pipes = findReferences(getNamedArgument(annotationNode, 'pipes'));
        final exports = findReferences(
            getNamedArgument(annotationNode, 'exports'),
            unexpectedNodeError:
                AngularWarningCode.EXPORTS_MUST_BE_PLAIN_IDENTIFIERS);

        _findDuplicateExports(exports);

        return Component(_currentClassName, _source,
            templateText: templateTextInfo?.text,
            templateTextRange: templateTextInfo?.sourceRange,
            inlineNgContents: templateTextInfo?.ngContents,
            templateUrl: templateUrlInfo?.templateUrl,
            templateUrlRange: templateUrlInfo?.sourceRange,
            directives: directives,
            pipes: pipes,
            exports: exports,
            exportAs: exportAs?.string,
            exportAsRange: exportAs?.navigationRange,
            inputs: inputs,
            outputs: outputs,
            selector: selector,
            contentChildFields: contentChildFields,
            contentChildrenFields: contentChildrenFields);
      }
      if (directiveNode != null) {
        return Directive(_currentClassName, _source,
            exportAs: exportAs?.string,
            exportAsRange: exportAs?.navigationRange,
            inputs: inputs,
            outputs: outputs,
            selector: selector,
            contentChildFields: contentChildFields,
            contentChildrenFields: contentChildrenFields);
      }
    }

    _parseMemberInputsAndOutputs(classDeclaration, inputs, outputs);
    if (inputs.isNotEmpty ||
        outputs.isNotEmpty ||
        contentChildFields.isNotEmpty ||
        contentChildrenFields.isNotEmpty) {
      return AnnotatedClass(_currentClassName, _source,
          inputs: inputs,
          outputs: outputs,
          contentChildFields: contentChildFields,
          contentChildrenFields: contentChildrenFields);
    }

    return null;
  }

  /// Returns an Angular [FunctionalDirective] for to the given [node].
  ///
  /// Returns `null` if not an Angular annotation.
  FunctionalDirective _getFunctionalDirective(
      ast.FunctionDeclaration functionDeclaration) {
    final functionName = functionDeclaration.name.name;
    final annotationNode = functionDeclaration.metadata.firstWhere(
        (ann) => isAngularAnnotation(ann, 'Directive'),
        orElse: () => null);

    if (annotationNode != null) {
      // Don't fail to create a directive just because of a broken or missing
      // selector, that results in cascading errors.
      final selector = _parseSelector(annotationNode) ?? AndSelector([]);
      final exportAs = getNamedArgument(annotationNode, 'exportAs');
      if (exportAs != null) {
        errorReporter.reportErrorForNode(
            AngularWarningCode.FUNCTIONAL_DIRECTIVES_CANT_BE_EXPORTED,
            exportAs);
      }
      return FunctionalDirective(functionName, _source, selector);
    }

    return null;
  }

  /// Parse fields labeled `@ContentChild`, noting their source ranges.
  ///
  /// The ranges of the type argument can be used to create an unlinked summary
  /// which can, at link time, check for errors and highlight the correct range.
  /// This is all we need from the AST itself, so all we should do here.
  void _parseContentChilds(
      ast.ClassDeclaration node,
      List<ContentChild> contentChildFields,
      List<ContentChild> contentChildrenFields) {
    for (final member in node.members) {
      for (final annotation in member.metadata) {
        List<ContentChild> targetList;
        if (isAngularAnnotation(annotation, 'ContentChild')) {
          targetList = contentChildFields;
        } else if (isAngularAnnotation(annotation, 'ContentChildren')) {
          targetList = contentChildrenFields;
        } else {
          continue;
        }

        final annotationArgs = annotation?.arguments?.arguments;
        if (annotationArgs == null) {
          // This happens for invalid dart code. Ignore
          continue;
        }

        if (annotationArgs.isEmpty) {
          // No need to report an error, dart does that already.
          continue;
        }

        final offset = annotationArgs[0].offset;
        final length = annotationArgs[0].length;
        var setterTypeOffset = member.offset; // fallback option
        var setterTypeLength = member.length; // fallback option

        String name;
        if (member is ast.FieldDeclaration) {
          name = member.fields.variables[0].name.toString();

          if (member.fields.type != null) {
            setterTypeOffset = member.fields.type.offset;
            setterTypeLength = member.fields.type.length;
          }
        } else if (member is ast.MethodDeclaration) {
          name = member.name.toString();

          final parameters = member.parameters?.parameters;
          if (parameters != null && parameters.isNotEmpty) {
            final parameter = parameters[0];
            if (parameter is ast.SimpleFormalParameter &&
                parameter.type != null) {
              setterTypeOffset = parameter.type.offset;
              setterTypeLength = parameter.type.length;
            }
          }
        }

        if (name != null) {
          targetList.add(ContentChild(name,
              nameRange: SourceRange(offset, length),
              typeRange: SourceRange(setterTypeOffset, setterTypeLength)));
        }
      }
    }
  }

  NavigableString _parseExportAs(ast.Annotation node) {
    // Find the "exportAs" argument.
    final expression = getNamedArgument(node, 'exportAs');
    if (expression == null) {
      return null;
    }

    // Extract its content.
    final name = getExpressionString(expression);
    if (name == null) {
      return null;
    }

    int offset;
    if (expression is ast.SimpleStringLiteral) {
      offset = expression.contentsOffset;
    } else {
      offset = expression.offset;
    }

    return NavigableString(name, SourceRange(offset, name.length), _source);
  }

  /// Try to extract an [Input] or [Output] from the member.
  ///
  /// Create a new input or output for the given class member [node] with
  /// the given `@Input` or `@Output` [annotation], and add it to the
  /// [inputs] or [outputs] array.
  void _parseMemberInputOrOutput(ast.ClassMember node,
      ast.Annotation annotation, List<Input> inputs, List<Output> outputs) {
    // analyze the annotation
    final isInput = isAngularAnnotation(annotation, 'Input');
    final isOutput = isAngularAnnotation(annotation, 'Output');
    if ((!isInput && !isOutput) || annotation.arguments == null) {
      return null;
    }

    // analyze the class member
    String name;
    int nameOffset;
    if (node is ast.FieldDeclaration && node.fields.variables.length == 1) {
      name = node.fields.variables[0].name.name;
      nameOffset = node.fields.variables[0].name.offset;
    } else if (node is ast.MethodDeclaration) {
      if ((isInput && node.isSetter) || (isOutput && node.isGetter)) {
        name = node.name.name;
        nameOffset = node.name.offset;
      }
    }

    if (name == null) {
      errorReporter.reportErrorForOffset(
          isInput
              ? AngularWarningCode.INPUT_ANNOTATION_PLACEMENT_INVALID
              : AngularWarningCode.OUTPUT_ANNOTATION_PLACEMENT_INVALID,
          annotation.offset,
          annotation.length);
      return null;
    }

    final arguments = annotation.arguments.arguments;

    // Extract the annotated name, ie, `@Input("foo")`.
    // TODO(mfairhurst): extract this from constant model
    var annotatedName = name;
    var annotatedNameOffset = nameOffset;
    if (arguments.isNotEmpty) {
      final nameArgument = arguments[0];
      if (nameArgument is ast.SimpleStringLiteral) {
        annotatedName = nameArgument.value;
        annotatedNameOffset = nameArgument.contentsOffset;
      } else {
        errorReporter.reportErrorForNode(
            AngularWarningCode.STRING_VALUE_EXPECTED, nameArgument);
      }
      if (name == null) {
        return null;
      }
    }

    if (isInput) {
      inputs.add(Input(
          name: annotatedName,
          nameRange: SourceRange(annotatedNameOffset, annotatedName.length),
          setterName: name,
          setterRange: SourceRange(nameOffset, name.length)));
    } else {
      outputs.add(Output(
          name: annotatedName,
          nameRange: SourceRange(annotatedNameOffset, annotatedName.length),
          getterName: name,
          getterRange: SourceRange(nameOffset, name.length)));
    }
  }

  /// Collect inputs and outputs for all class members.
  void _parseMemberInputsAndOutputs(
      ast.ClassDeclaration node, List<Input> inputs, List<Output> outputs) {
    for (final member in node.members) {
      for (final annotation in member.metadata) {
        _parseMemberInputOrOutput(member, annotation, inputs, outputs);
      }
    }
  }

  Selector _parseSelector(ast.Annotation node) {
    // Find the "selector" argument.
    final expression = getNamedArgument(node, 'selector');
    if (expression == null) {
      errorReporter.reportErrorForNode(
          AngularWarningCode.ARGUMENT_SELECTOR_MISSING, node);
      return null;
    }
    // Compute the selector text. Careful! Offsets may not be valid after this,
    // however, at the moment we don't use them anyway.
    final constantEvaluation = calculateStringWithOffsets(expression);
    if (constantEvaluation == null || constantEvaluation.value is! String) {
      return null;
    }

    final selectorStr = constantEvaluation.value as String;
    final selectorOffset = expression.offset;
    // Parse the selector text.
    try {
      final selector =
          SelectorParser(_source, selectorOffset, selectorStr).parse();
      if (selector == null) {
        errorReporter.reportErrorForNode(
            AngularWarningCode.CANNOT_PARSE_SELECTOR,
            expression,
            [selectorStr]);
      }
      return selector;
    } on SelectorParseError catch (e) {
      errorReporter.reportErrorForOffset(
          AngularWarningCode.CANNOT_PARSE_SELECTOR,
          e.offset,
          e.length,
          [e.message]);
    }

    return null;
  }
}

/// Helper for processing Angular annotations.
class _AnnotationProcessorMixin {
  var errorListener = RecordingErrorListener();
  ErrorReporter errorReporter;

  /// The evaluator of constant values, such as annotation arguments.
  final utils.ConstantEvaluator _constantEvaluator = utils.ConstantEvaluator();

  /// Returns the [String] value of the given [expression].
  ///
  /// If [expression] does not have a [String] value, reports an error
  /// and returns `null`.
  OffsettingConstantEvaluator calculateStringWithOffsets(
      ast.Expression expression) {
    if (expression != null) {
      final evaluator = OffsettingConstantEvaluator();
      evaluator.value = expression.accept(evaluator);

      if (!evaluator.offsetsAreValid) {
        errorReporter.reportErrorForNode(
            AngularHintCode.OFFSETS_CANNOT_BE_CREATED,
            evaluator.lastUnoffsettableNode);
      } else if (evaluator.value is! String &&
          evaluator.value != utils.ConstantEvaluator.NOT_A_CONSTANT) {
        errorReporter.reportErrorForNode(
            AngularWarningCode.STRING_VALUE_EXPECTED, expression);
      }
      return evaluator;
    }
    return null;
  }

  /// Returns the [String] value of the given [expression].
  ///
  /// If [expression] does not have a [String] value, reports an error
  /// and returns `null`.
  String getExpressionString(ast.Expression expression) {
    if (expression != null) {
      // ignore: omit_local_variable_types
      final Object value = expression.accept(_constantEvaluator);
      if (value is String) {
        return value;
      }
      errorReporter.reportErrorForNode(
          AngularWarningCode.STRING_VALUE_EXPECTED, expression);
    }
    return null;
  }

  /// Returns the value of the argument with the given [name].
  ///
  /// Returns `null` if not found.
  ast.Expression getNamedArgument(ast.Annotation node, String name) {
    if (node.arguments != null) {
      final arguments = node.arguments.arguments;
      for (var argument in arguments) {
        if (argument is ast.NamedExpression &&
            argument.name != null &&
            argument.name.label != null &&
            argument.name.label.name == name) {
          return argument.expression;
        }
      }
    }
    return null;
  }

  /// Initialize the processor working in the given [target].
  void initAnnotationProcessor(Source source) {
    assert(errorReporter == null);
    errorReporter = ErrorReporter(errorListener, source);
  }

  /// Returns `true` if the given [node] matches the expected angular [name].
  bool isAngularAnnotation(ast.Annotation node, String name) =>
      node.name.name == name;
}

class NgContentRecorder extends AngularAstVisitor {
  final List<NgContent> ngContents;
  final Source source;
  final ErrorReporter errorReporter;

  NgContentRecorder(this.ngContents, this.source, this.errorReporter);

  @override
  void visitElementInfo(ElementInfo element) {
    if (element.localName != 'ng-content') {
      for (final child in element.childNodes) {
        child.accept(this);
      }

      return;
    }

    final selectorAttrs = element.attributes.where((a) => a.name == 'select');

    for (final child in element.childNodes) {
      if (!child.isSynthetic) {
        errorReporter.reportErrorForOffset(
            AngularWarningCode.NG_CONTENT_MUST_BE_EMPTY,
            element.openingSpan.offset,
            element.openingSpan.length);
      }
    }

    if (selectorAttrs.isEmpty) {
      ngContents.add(NgContent(SourceRange(element.offset, element.length)));
      return;
    }

    // We don't actually check if selectors.length > 2, because the parser
    // reports that.
    try {
      final selectorAttr = selectorAttrs.first;
      if (selectorAttr.value == null) {
        // TODO(mfairhust) report different error for a missing selector
        errorReporter.reportErrorForOffset(
            AngularWarningCode.CANNOT_PARSE_SELECTOR,
            selectorAttr.nameOffset,
            selectorAttr.name.length,
            ['missing']);
      } else if (selectorAttr.value == "") {
        // TODO(mfairhust) report different error for a missing selector
        errorReporter.reportErrorForOffset(
            AngularWarningCode.CANNOT_PARSE_SELECTOR,
            selectorAttr.valueOffset - 1,
            2,
            ['missing']);
      } else {
        final selector =
            SelectorParser(source, selectorAttr.valueOffset, selectorAttr.value)
                .parse();
        ngContents.add(NgContent.withSelector(
            SourceRange(element.offset, element.length),
            selector,
            SourceRange(selectorAttr.valueOffset, selectorAttr.value.length)));
      }
    } on SelectorParseError catch (e) {
      errorReporter.reportErrorForOffset(
          AngularWarningCode.CANNOT_PARSE_SELECTOR,
          e.offset,
          e.length,
          [e.message]);
    }
  }
}

class ParsedTemplateText {
  final String text;
  final SourceRange sourceRange;
  final List<NgContent> ngContents;

  ParsedTemplateText(this.text, this.sourceRange, this.ngContents);
}

class ParsedTemplateUrl {
  final String templateUrl;
  final SourceRange sourceRange;

  ParsedTemplateUrl(this.templateUrl, this.sourceRange);
}
