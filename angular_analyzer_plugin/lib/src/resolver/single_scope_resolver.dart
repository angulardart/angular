import 'package:analyzer/dart/ast/ast.dart' hide Directive;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/dart/resolver/resolution_visitor.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/ast.dart';
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/model/navigable.dart';
import 'package:angular_analyzer_plugin/src/resolver/angular_scope_visitor.dart';
import 'package:angular_analyzer_plugin/src/resolver/dart_references_recorder.dart';
import 'package:angular_analyzer_plugin/src/resolver/is_on_custom_tag.dart';
import 'package:angular_analyzer_plugin/src/resolver/angular_subset_visitor.dart';
import 'package:angular_analyzer_plugin/src/resolver/angular_resolver_visitor.dart';
import 'package:angular_analyzer_plugin/src/standard_components.dart';

/// Fully resolve a single scope in an angular template.
///
/// Once all the scopes for all the expressions & statements are prepared, we're
/// ready to resolve all the expressions inside and typecheck everything.
///
/// This will typecheck the contents of mustaches and attribute bindings against
/// their scopes, and ensure that all attribute bindings exist on a directive and
/// match the type of the binding where there is one. Then records references.
class SingleScopeResolver extends AngularScopeVisitor {
  static var styleWithPercent = <String>{
    'border-bottom-left-radius',
    'border-bottom-right-radius',
    'border-image-slice',
    'border-image-width',
    'border-radius',
    'border-top-left-radius',
    'border-top-right-radius',
    'bottom',
    'font-size',
    'height',
    'left',
    'line-height',
    'margin',
    'margin-bottom',
    'margin-left',
    'margin-right',
    'margin-top',
    'max-height',
    'max-width',
    'min-height',
    'min-width',
    'padding',
    'padding-bottom',
    'padding-left',
    'padding-right',
    'padding-top',
    'right',
    'text-indent',
    'top',
    'width',
  };

  /// Simple css identifier regex to validate `[style.x]` bindings.
  ///
  /// Doesn't handle unicode. They can start with a dash, but if so must be
  /// followed by an alphabetic or underscore or escaped character. Cannot start
  /// with a number.
  /// https://www.w3.org/TR/CSS21/syndata.html#value-def-identifier
  static final RegExp _cssIdentifierRegexp =
      RegExp(r"^(-?[a-zA-Z_]|\\.)([a-zA-Z0-9\-_]|\\.)*$");
  final Map<String, Input> standardHtmlAttributes;
  final List<Pipe> pipes;
  List<DirectiveBase> directives;
  Component component;
  Template template;
  Source templateSource;
  TypeProvider typeProvider;
  TypeSystem typeSystem;

  AnalysisErrorListener errorListener;

  ErrorReporter errorReporter;

  /// The full map of names to local variables in the current context
  Map<String, LocalVariable> localVariables;

  SingleScopeResolver(
      this.standardHtmlAttributes,
      this.pipes,
      this.component,
      this.template,
      this.templateSource,
      this.typeProvider,
      this.typeSystem,
      this.errorListener,
      this.errorReporter);

  @override
  void visitElementInfo(ElementInfo element) {
    directives = element.directives;
    super.visitElementInfo(element);
  }

  @override
  void visitEmptyStarBinding(EmptyStarBinding binding) {
    // When the first virtual attribute matches a binding (like `ngIf`), flag it
    // if its empty. Only for the first. All others (like `trackBy`) are checked
    // in [EmbeddedDartParser.parseTemplateVirtualAttributes]
    if (!binding.isPrefix) {
      return;
    }

    // catch *ngIf without a value
    if (binding.parent.boundDirectives
        .map((binding) => binding.boundDirective)
        // TODO enable this again for all directives, not just NgIf
        .where((directive) =>
            directive is Directive && directive.classElement.name == "NgIf")
        .any((directive) =>
            directive.inputs.any((input) => input.name == binding.name))) {
      errorListener.onError(AnalysisError(
          templateSource,
          binding.nameOffset,
          binding.name.length,
          AngularWarningCode.EMPTY_BINDING,
          [binding.name]));
    }
  }

  @override
  void visitExpressionBoundAttr(ExpressionBoundAttribute attribute) {
    localVariables = attribute.localVariables;
    _resolveDartExpression(attribute.expression);
    if (attribute.expression != null) {
      _recordAstNodeResolvedRanges(attribute.expression);
    }

    if (attribute.bound == ExpressionBoundType.twoWay) {
      _resolveTwoWayBoundAttributeValues(attribute);
    } else if (attribute.bound == ExpressionBoundType.input) {
      _resolveInputBoundAttributeValues(attribute);
    } else if (attribute.bound == ExpressionBoundType.clazz) {
      _resolveClassAttribute(attribute);
    } else if (attribute.bound == ExpressionBoundType.style) {
      _resolveStyleAttribute(attribute);
    } else if (attribute.bound == ExpressionBoundType.attr) {
      _resolveAttributeBoundAttribute(attribute);
    } else if (attribute.bound == ExpressionBoundType.attrIf) {
      _resolveAttributeBoundAttributeIf(attribute);
    }
  }

  @override
  void visitMustache(Mustache mustache) {
    localVariables = mustache.localVariables;
    _resolveDartExpression(mustache.expression);
    _recordAstNodeResolvedRanges(mustache.expression);
  }

  /// Resolve output-bound values of [attributes] as statements.
  @override
  void visitStatementsBoundAttr(StatementsBoundAttribute attribute) {
    localVariables = attribute.localVariables;
    _resolveDartExpressionStatements(attribute.statements);
    for (final statement in attribute.statements) {
      _recordAstNodeResolvedRanges(statement);
    }
  }

  @override
  void visitTemplateAttr(TemplateAttribute templateAttr) {
    directives = templateAttr.directives;
    super.visitTemplateAttr(templateAttr);
  }

  /// Resolve basic text attributes that carry any special angular meanings.
  ///
  /// Resolves [attributes] as strings, if they match an input. Marks navigation
  /// and ensure that input bindings are string-assingable. Note, this does not
  /// report an error for unmatched attributes.
  @override
  void visitTextAttr(TextAttribute attribute) {
    for (final directiveBinding in attribute.parent.boundDirectives) {
      for (final input in directiveBinding.boundDirective.inputs) {
        if (input.name != attribute.name) {
          continue;
        }

        if (!_checkTextAttrSecurity(attribute, input.securityContext)) {
          continue;
        }

        // Typecheck all but HTML inputs. For those, `width="10"` becomes
        // `setAttribute("width", "10")`, which is ok. But for directives and
        // components, this becomes `.someIntProp = "10"` which doesn't work.
        final inputType = input.setterType;

        // Some attr `foo` by itself, no brackets, as such, and no value, will
        // be bound "true" when its a boolean, which requires no typecheck.
        final booleanException =
            typeSystem.isSubtypeOf(input.setterType, typeProvider.boolType) &&
                attribute.value == null;

        if (!directiveBinding.boundDirective.isHtml &&
            !booleanException &&
            !typeSystem.isAssignableTo(typeProvider.stringType, inputType)) {
          errorListener.onError(AnalysisError(
              templateSource,
              attribute.nameOffset,
              attribute.name.length,
              AngularWarningCode.STRING_STYLE_INPUT_BINDING_INVALID,
              [input.name]));
        }

        final range = SourceRange(attribute.nameOffset, attribute.name.length);
        template.addRange(range, input);
        directiveBinding.inputBindings.add(InputBinding(input, attribute));
      }

      for (final elem in directiveBinding.boundDirective.attributes) {
        if (elem.string == attribute.name) {
          final range =
              SourceRange(attribute.nameOffset, attribute.name.length);
          template.addRange(range, elem);
        }
      }
    }

    final standardHtmlAttribute = standardHtmlAttributes[attribute.name];
    if (standardHtmlAttribute != null) {
      _checkTextAttrSecurity(attribute, standardHtmlAttribute.securityContext);
      // Don't typecheck html inputs. Those become attributes, not properties,
      // which means strings values are OK.
      final range = SourceRange(attribute.nameOffset, attribute.name.length);
      template.addRange(range, standardHtmlAttribute);
      attribute.parent.boundStandardInputs
          .add(InputBinding(standardHtmlAttribute, attribute));
    }

    // visit mustaches inside
    super.visitTextAttr(attribute);
  }

  bool _checkTextAttrSecurity(
      TextAttribute attribute, SecurityContext securityContext) {
    if (securityContext == null) {
      return true;
    }
    if (securityContext.sanitizationAvailable) {
      return true;
    }
    if (attribute.mustaches.isEmpty) {
      return true;
    }

    errorListener.onError(AnalysisError(
        templateSource,
        attribute.valueOffset,
        attribute.value.length,
        AngularWarningCode.UNSAFE_BINDING,
        [securityContext.safeTypes.join(' or ')]));
    return false;
  }

  /// Get a human-friendly name for a [Statement] type.
  ///
  /// Used to report [OUTPUT_STATEMENT_REQUIRES_EXPRESSION_STATEMENT].
  String _getOutputStatementErrorDescription(Statement stmt) {
    final potentialToken = stmt.beginToken.keyword.toString().toLowerCase();
    if (potentialToken != "null") {
      return "token '$potentialToken'";
    } else {
      return stmt.runtimeType.toString().replaceFirst("Impl", "");
    }
  }

  bool _isCssIdentifier(String input) => _cssIdentifierRegexp.hasMatch(input);

  /// Record [ResolvedRange]s for the given [AstNode].
  void _recordAstNodeResolvedRanges(AstNode astNode) {
    final dartVariables = <LocalVariableElement, LocalVariable>{};

    for (final localVariable in localVariables.values) {
      dartVariables[localVariable.dartVariable] = localVariable;
    }

    if (astNode != null) {
      astNode.accept(DartReferencesRecorder(template, dartVariables));
    }
  }

  /// Resolve attributes of type `[attribute.some-attribute]="someExpr"`
  void _resolveAttributeBoundAttribute(ExpressionBoundAttribute attribute) {
    // TODO validate the type? Or against a dictionary?
    // note that the attribute name is valid by definition as it was discovered
    // within an attribute! (took me a while to realize why I couldn't make any
    // failing tests for this)
  }

  /// Resolve attributes of type `[attribute.some-attribute]="someExpr"`
  void _resolveAttributeBoundAttributeIf(ExpressionBoundAttribute attribute) {
    if (attribute.parent is! ElementInfo) {
      assert(false, 'Got an attr-if bound attribute on non element! Aborting!');
      return;
    }

    final parent = attribute.parent as ElementInfo;

    // For the [attr.foo.if] attribute, find the matching [attr.foo] attribute.
    final matchingAttr = parent.attributes
        .where((attr) =>
            attr is ExpressionBoundAttribute &&
            attr.bound == ExpressionBoundType.attr)
        .firstWhere((attrAttr) => attrAttr.name == attribute.name,
            orElse: () => null);

    // Error: no matching attribute to make conditional via this attr-if.
    if (matchingAttr == null) {
      errorListener.onError(AnalysisError(
          templateSource,
          attribute.nameOffset,
          attribute.name.length,
          AngularWarningCode.UNMATCHED_ATTR_IF_BINDING,
          [attribute.name]));
      return;
    }

    // Add navigation from [attribute] (`[attr.foo.if]`) to [matchingAttr]
    // (`[attr.foo]`).
    final range = SourceRange(attribute.nameOffset, attribute.name.length);
    template.addRange(
        range,
        NavigableString(
            'attr.${attribute.name}',
            SourceRange(matchingAttr.nameOffset, matchingAttr.name.length),
            templateSource));

    // Ensure the if condition was a boolean.
    if (attribute.expression != null &&
        !typeSystem.isAssignableTo(
            attribute.expression.staticType, typeProvider.boolType)) {
      errorListener.onError(AnalysisError(
          templateSource,
          attribute.valueOffset,
          attribute.value.length,
          AngularWarningCode.ATTR_IF_BINDING_TYPE_ERROR,
          [attribute.name]));
    }
  }

  /// Resolve attributes of type `[class.some-class]="someBoolExpr"`.
  ///
  /// Ensure the class is a valid css identifier and that the expression is of
  /// boolean type.
  void _resolveClassAttribute(ExpressionBoundAttribute attribute) {
    if (!_isCssIdentifier(attribute.name)) {
      errorListener.onError(AnalysisError(
          templateSource,
          attribute.nameOffset,
          attribute.name.length,
          AngularWarningCode.INVALID_HTML_CLASSNAME,
          [attribute.name]));
    }

    // half-complete-code case: ensure the expression is actually there
    if (attribute.expression != null &&
        !typeSystem.isAssignableTo(
            attribute.expression.staticType ?? typeProvider.dynamicType,
            typeProvider.boolType)) {
      errorListener.onError(AnalysisError(
        templateSource,
        attribute.valueOffset,
        attribute.value.length,
        AngularWarningCode.CLASS_BINDING_NOT_BOOLEAN,
      ));
    }
  }

  /// Resolve the [AstNode] ([expression] or [statement]) and report errors.
  void _resolveDartAstNode(AstNode astNode, bool acceptAssignment) {
    final classElement = component.classElement;
    final unitElement = component.classElement.enclosingElement;
    final library = classElement.library;

    final libraryScope = LibraryScope(library);
    astNode.accept(
      ResolutionVisitor(
        unitElement: unitElement,
        errorListener: errorListener,
        featureSet: library.context.analysisOptions.contextFeatures,
        nameScope: libraryScope,
      ),
    );

    final inheritanceManager = InheritanceManager3(typeSystem);
    final resolver = AngularResolverVisitor(inheritanceManager, library,
        templateSource, typeProvider, errorListener,
        pipes: pipes);
    // fill the name scope
    final classScope = ClassScope(resolver.nameScope, classElement);
    final localScope = EnclosedScope(classScope);
    resolver
      ..nameScope = localScope
      ..enclosingClass = classElement;
    localVariables.values
        .forEach((local) => localScope.define(local.dartVariable));
    // do resolve
    astNode.accept(resolver);
    // verify
    final verifier = ErrorVerifier(
        errorReporter, library, typeProvider, inheritanceManager, true)
      ..enclosingClass = classElement;
    astNode.accept(verifier);
    // Check for concepts illegal to templates (for instance function literals).
    final angularSubsetChecker = AngularSubsetVisitor(
        errorReporter: errorReporter,
        acceptAssignment: acceptAssignment,
        owningComponent: component);
    astNode.accept(angularSubsetChecker);
  }

  /// Resolve the Dart expression with the given [code] at [offset].
  void _resolveDartExpression(Expression expression) {
    if (expression != null) {
      _resolveDartAstNode(expression, false);
    }
  }

  /// Resolve the Dart [ExpressionStatement] with the given [code] at [offset].
  void _resolveDartExpressionStatements(List<Statement> statements) {
    for (final statement in statements) {
      if (statement is! ExpressionStatement && statement is! EmptyStatement) {
        errorListener.onError(AnalysisError(
            templateSource,
            statement.offset,
            (statement.endToken.type == TokenType.SEMICOLON)
                ? statement.length - 1
                : statement.length,
            AngularWarningCode.OUTPUT_STATEMENT_REQUIRES_EXPRESSION_STATEMENT,
            [_getOutputStatementErrorDescription(statement)]));
      } else {
        _resolveDartAstNode(statement, true);
      }
    }
  }

  /// Resolve input-bound values of [attributes] as expressions.
  ///
  /// Also used by [_resolveTwoWayBoundAttributeValues].
  void _resolveInputBoundAttributeValues(ExpressionBoundAttribute attribute) {
    var inputMatched = false;

    // Check if input exists on bound directives.
    for (final directiveBinding in attribute.parent.boundDirectives) {
      for (final input in directiveBinding.boundDirective.inputs) {
        if (input.name == attribute.name) {
          _typecheckMatchingInput(attribute, input);

          final range =
              SourceRange(attribute.nameOffset, attribute.name.length);
          template.addRange(range, input);
          directiveBinding.inputBindings.add(InputBinding(input, attribute));

          inputMatched = true;
        }
      }
    }

    // Check if input exists from standard html attributes.
    if (!inputMatched) {
      final standardHtmlAttribute = standardHtmlAttributes[attribute.name];
      if (standardHtmlAttribute != null) {
        _typecheckMatchingInput(attribute, standardHtmlAttribute);
        final range = SourceRange(attribute.nameOffset, attribute.name.length);
        template.addRange(range, standardHtmlAttribute);
        attribute.parent.boundStandardInputs
            .add(InputBinding(standardHtmlAttribute, attribute));

        inputMatched = true;
      }
    }

    if (!inputMatched && !isOnCustomTag(attribute)) {
      errorListener.onError(AnalysisError(
          templateSource,
          attribute.nameOffset,
          attribute.name.length,
          AngularWarningCode.NONEXIST_INPUT_BOUND,
          [attribute.name]));
    }
  }

  /// Resolve attributes of type `[style.color]="someExpr"`.
  ///
  /// Also handles units, ie, `[style.background-width.px]="someNumExpr"`.
  void _resolveStyleAttribute(ExpressionBoundAttribute attribute) {
    var cssPropertyName = attribute.name;
    final dotpos = attribute.name.indexOf('.');
    if (dotpos != -1) {
      cssPropertyName = attribute.name.substring(0, dotpos);
      final cssUnitName = attribute.name.substring(dotpos + '.'.length);
      var validUnitName =
          styleWithPercent.contains(cssPropertyName) && cssUnitName == '%';
      validUnitName = validUnitName || _isCssIdentifier(cssUnitName);
      if (!validUnitName) {
        errorListener.onError(AnalysisError(
            templateSource,
            attribute.nameOffset + dotpos + 1,
            cssUnitName.length,
            AngularWarningCode.INVALID_CSS_UNIT_NAME,
            [cssUnitName]));
      }
      // half-complete-code case: ensure the expression is actually there
      if (attribute.expression != null &&
          !typeSystem.isAssignableTo(
              attribute.expression.staticType ?? typeProvider.dynamicType,
              typeProvider.numType)) {
        errorListener.onError(AnalysisError(
            templateSource,
            attribute.valueOffset,
            attribute.value.length,
            AngularWarningCode.CSS_UNIT_BINDING_NOT_NUMBER));
      }
    }

    if (!_isCssIdentifier(cssPropertyName)) {
      errorListener.onError(AnalysisError(
          templateSource,
          attribute.nameOffset,
          cssPropertyName.length,
          AngularWarningCode.INVALID_CSS_PROPERTY_NAME,
          [cssPropertyName]));
    }
  }

  /// Resolve TwoWay-bound values of [attributes] as expressions.
  void _resolveTwoWayBoundAttributeValues(ExpressionBoundAttribute attribute) {
    var outputMatched = false;

    // empty attribute error registered in converter. Just don't crash.
    if (attribute.expression != null && !attribute.expression.isAssignable) {
      errorListener.onError(AnalysisError(
          templateSource,
          attribute.valueOffset,
          attribute.value.length,
          AngularWarningCode.TWO_WAY_BINDING_NOT_ASSIGNABLE));
    }

    for (final directiveBinding in attribute.parent.boundDirectives) {
      for (final output in directiveBinding.boundDirective.outputs) {
        if (output.name == "${attribute.name}Change") {
          outputMatched = true;
          final eventType = output.eventType;
          directiveBinding.outputBindings.add(OutputBinding(output, attribute));

          // half-complete-code case: ensure the expression is actually there
          if (attribute.expression != null &&
              !typeSystem.isAssignableTo(
                  eventType,
                  attribute.expression.staticType ??
                      typeProvider.dynamicType)) {
            errorListener.onError(AnalysisError(
                templateSource,
                attribute.valueOffset,
                attribute.value.length,
                AngularWarningCode.TWO_WAY_BINDING_OUTPUT_TYPE_ERROR, [
              output.eventType,
              attribute.expression.staticType ?? typeProvider.dynamicType
            ]));
          }
        }
      }
    }

    if (!outputMatched && !isOnCustomTag(attribute)) {
      errorListener.onError(AnalysisError(
          templateSource,
          attribute.nameOffset,
          attribute.name.length,
          AngularWarningCode.NONEXIST_TWO_WAY_OUTPUT_BOUND,
          [attribute.name, "${attribute.name}Change"]));
    }

    _resolveInputBoundAttributeValues(attribute);
  }

  void _typecheckMatchingInput(ExpressionBoundAttribute attr, Input input) {
    // half-complete-code case: ensure the expression is actually there
    if (attr.expression != null) {
      final attrType = attr.expression.staticType ?? typeProvider.dynamicType;
      final inputType = input.setterType;
      final securityContext = input.securityContext;

      if (securityContext != null) {
        if (securityContext.safeTypes
            .any((safeType) => typeSystem.isAssignableTo(attrType, safeType))) {
          return;
        } else if (!securityContext.sanitizationAvailable) {
          errorListener.onError(AnalysisError(
              templateSource,
              attr.valueOffset,
              attr.value.length,
              AngularWarningCode.UNSAFE_BINDING,
              [securityContext.safeTypes.join(' or ')]));
          return;
        }
      }

      if (!typeSystem.isAssignableTo(attrType, inputType)) {
        errorListener.onError(AnalysisError(
            templateSource,
            attr.valueOffset,
            attr.value.length,
            AngularWarningCode.INPUT_BINDING_TYPE_ERROR,
            [attrType, inputType]));
      }
    }
  }
}
