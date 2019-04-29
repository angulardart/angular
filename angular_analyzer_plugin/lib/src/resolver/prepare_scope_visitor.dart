import 'package:analyzer/dart/ast/ast.dart' hide Directive;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/ast.dart';
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/model/navigable.dart';
import 'package:angular_analyzer_plugin/src/resolver/angular_scope_visitor.dart';
import 'package:angular_analyzer_plugin/src/resolver/dart_variable_manager.dart';
import 'package:angular_analyzer_plugin/src/resolver/internal_variable.dart';
import 'package:angular_analyzer_plugin/src/standard_components.dart';

/// Prepare AST nodes local scopes to be resolved in more detail later.
///
/// We have to collect all vars and their types before we can resolve the
/// bindings, since variables can be used before they are declared. This does
/// that.
///
/// It loads each node's [localVariables] property so that the resolver has
/// everything it needs, keeping those local variables around for autocomplete.
/// As the scope is built up it is attached to the nodes -- and thanks to
/// mutability + a shared reference, that works just fine.
///
/// However, `$event` vars require a copy of the scope, not a shared reference,
/// so that the `$event` can be added. Therefore this visitor does not handle
/// output bindings. That is [PrepareEventScopeVisitor]'s job, only to be
/// performed after this step has completed.
class PrepareScopeVisitor extends AngularScopeVisitor {
  static const _hashSymbol = '#';

  /// The full map of names to internal variables in the current scope
  final Map<String, InternalVariable> internalVariables;

  /// The full map of names to local variables in the current scope
  final Map<String, LocalVariable> localVariables;

  final Template template;
  final Source templateSource;
  final TypeProvider typeProvider;
  final DartVariableManager dartVariableManager;
  final AnalysisErrorListener errorListener;
  final StandardAngular standardAngular;

  PrepareScopeVisitor(
      this.internalVariables,
      this.localVariables,
      this.template,
      this.templateSource,
      this.typeProvider,
      this.dartVariableManager,
      this.errorListener,
      this.standardAngular);

  @override
  void visitBorderScopeTemplateAttribute(TemplateAttribute attr) {
    // Border to the next scope. Make sure the virtual properties are bound
    // to the scope we're building now. But nothing else.
    visitTemplateAttr(attr);
  }

  @override
  void visitBorderScopeTemplateElement(ElementInfo element) {
    final exportAsMap = _defineExportAsVariables(element.directives);
    _defineReferenceVariablesForAttributes(
        element.directives, element.attributes, exportAsMap);
    super.visitBorderScopeTemplateElement(element);
  }

  @override
  void visitElementInScope(ElementInfo element) {
    final exportAsMap = _defineExportAsVariables(element.directives);
    // Regular element or component. Look for `#var`s.
    _defineReferenceVariablesForAttributes(
        element.directives, element.attributes, exportAsMap);
    super.visitElementInScope(element);
  }

  @override
  void visitExpressionBoundAttr(ExpressionBoundAttribute attr) {
    attr.localVariables = localVariables;
  }

  @override
  void visitMustache(Mustache mustache) {
    mustache.localVariables = localVariables;
  }

  @override
  void visitScopeRootElementWithTemplateAttribute(ElementInfo element) {
    final templateAttr = element.templateAttribute;

    final exportAsMap = _defineExportAsVariables(element.directives);

    // If this is how our scope begins, like we're within an ngFor, then
    // let the ngFor alter the current scope.
    for (final directive in templateAttr.directives) {
      _defineNgForVariables(templateAttr.virtualAttributes, directive);
    }

    _defineLetVariablesForAttributes(templateAttr.virtualAttributes);

    // Make sure the regular element also alters the current scope
    for (final directive in element.directives) {
      // This must be here for <template> tags.
      _defineNgForVariables(element.attributes, directive);
    }

    _defineReferenceVariablesForAttributes(
        element.directives, element.attributes, exportAsMap);

    super.visitScopeRootElementWithTemplateAttribute(element);
  }

  @override
  void visitScopeRootTemplateElement(ElementInfo element) {
    final exportAsMap = _defineExportAsVariables(element.directives);
    for (final directive in element.directives) {
      // This must be here for <template> tags.
      _defineNgForVariables(element.attributes, directive);
    }

    _defineReferenceVariablesForAttributes(
        element.directives, element.attributes, exportAsMap);
    _defineLetVariablesForAttributes(element.attributes);

    super.visitScopeRootTemplateElement(element);
  }

  /// Build `exportAs` type/name mappings to handle let-bindings.
  ///
  /// Provides a map for 'exportAs' string to list of class element. Return type
  /// must be a class to later resolve conflicts should they exist. This is a
  /// shortlived variable existing only in the scope of element tag, therefore
  /// don't use [internalVariables].
  Map<String, List<InternalVariable>> _defineExportAsVariables(
      List<DirectiveBase> directives) {
    final exportAsMap = <String, List<InternalVariable>>{};
    for (final directive in directives) {
      final exportAs = directive.exportAs;
      if (exportAs != null && directive is Directive) {
        final name = exportAs.string;
        final type = directive.classElement.type;
        exportAsMap.putIfAbsent(name, () => <InternalVariable>[]);
        exportAsMap[name].add(InternalVariable(name, exportAs, type));
      }
    }
    return exportAsMap;
  }

  /// Define reference variables [localVariables] for `#name` attributes.
  ///
  /// Begin by defining the type as 'dynamic'.
  /// In cases of *ngFor, this dynamic type is overwritten only if
  /// the value is defined within [internalVariables]. If value is null,
  /// it defaults to '$implicit'. If value is provided but isn't one of
  /// known implicit variables of ngFor, we can't throw an error since
  /// the value could still be defined.
  /// if '$implicit' is not defined within [internalVariables], we again
  /// default it to dynamicType.
  void _defineLetVariablesForAttributes(List<AttributeInfo> attributes) {
    for (final attribute in attributes) {
      var offset = attribute.nameOffset;
      var name = attribute.name;
      final value = attribute.value;

      if (name.startsWith('let-')) {
        final prefixLength = 'let-'.length;
        name = name.substring(prefixLength);
        offset += prefixLength;
        var type = typeProvider.dynamicType;

        final internalVar = internalVariables[value ?? r'$implicit'];
        if (internalVar != null) {
          type = internalVar.type;
          if (value != null) {
            template.addRange(
              SourceRange(attribute.valueOffset, attribute.valueLength),
              internalVar.element,
            );
          }
        }

        final localVariableElement =
            dartVariableManager.newLocalVariableElement(-1, name, type);
        final localVariable = LocalVariable(name, localVariableElement,
            localRange: SourceRange(offset, name.length));
        localVariables[name] = localVariable;
        template.addRange(
          SourceRange(offset, name.length),
          localVariable,
        );
      }
    }
  }

  void _defineNgForVariables(
      List<AttributeInfo> attributes, DirectiveBase directive) {
    if (directive is Directive && directive.classElement.name == 'NgFor') {
      final dartElem = DartElement(directive.classElement);
      internalVariables['index'] =
          InternalVariable('index', dartElem, typeProvider.intType);
      internalVariables['even'] =
          InternalVariable('even', dartElem, typeProvider.boolType);
      internalVariables['odd'] =
          InternalVariable('odd', dartElem, typeProvider.boolType);
      internalVariables['first'] =
          InternalVariable('first', dartElem, typeProvider.boolType);
      internalVariables['last'] =
          InternalVariable('last', dartElem, typeProvider.boolType);
      for (final attribute in attributes) {
        if (attribute is ExpressionBoundAttribute &&
            attribute.name == 'ngForOf' &&
            attribute.expression != null) {
          final itemType = _getIterableItemType(attribute.expression);
          internalVariables[r'$implicit'] =
              InternalVariable(r'$implicit', dartElem, itemType);
        }
      }
    }
  }

  /// Define reference variables [localVariables] for `#name` attributes.
  void _defineReferenceVariablesForAttributes(
      List<DirectiveBase> directives,
      List<AttributeInfo> attributes,
      Map<String, List<InternalVariable>> exportAsMap) {
    for (final attribute in attributes) {
      var offset = attribute.nameOffset;
      var name = attribute.name;

      // check if defines local variable
      if (name.startsWith(_hashSymbol)) {
        final prefixLen = _hashSymbol.length;
        name = name.substring(prefixLen);
        offset += prefixLen;
        final refValue = attribute.value;

        // maybe an internal variable reference
        var type = typeProvider.dynamicType;
        Navigable angularElement;

        if (refValue == null) {
          // Find the corresponding Component to assign reference to.
          for (final directive in directives) {
            if (directive is Component) {
              var classElement = directive.classElement;
              if (classElement.name == 'TemplateElement') {
                classElement = standardAngular.templateRef;
              }
              type = classElement.type;
              angularElement = DartElement(classElement);
              break;
            }
          }
        } else {
          final internalVars = exportAsMap[refValue];
          if (internalVars == null || internalVars.isEmpty) {
            errorListener.onError(AnalysisError(
              templateSource,
              attribute.valueOffset,
              attribute.value.length,
              AngularWarningCode.NO_DIRECTIVE_EXPORTED_BY_SPECIFIED_NAME,
              [attribute.value],
            ));
          } else if (internalVars.length > 1) {
            errorListener.onError(AnalysisError(
              templateSource,
              attribute.valueOffset,
              attribute.value.length,
              AngularWarningCode.DIRECTIVE_EXPORTED_BY_AMBIGIOUS,
              [attribute.value],
            ));
          } else {
            final internalVar = internalVars[0];
            type = internalVar.type;
            angularElement = internalVar.element;
          }
        }

        if (attribute.value != null) {
          template.addRange(
            SourceRange(attribute.valueOffset, attribute.valueLength),
            angularElement,
          );
        }

        final localVariableElement =
            dartVariableManager.newLocalVariableElement(offset, name, type);
        final localVariable = LocalVariable(name, localVariableElement,
            localRange: SourceRange(offset, name.length));
        localVariables[name] = localVariable;
        template.addRange(
          SourceRange(localVariable.navigationRange.offset,
              localVariable.navigationRange.length),
          localVariable,
        );
      }
    }
  }

  DartType _getIterableItemType(Expression expression) {
    final itemsType = expression.staticType;
    if (itemsType is InterfaceType) {
      final iteratorType = _lookupGetterReturnType(itemsType, 'iterator');
      if (iteratorType is InterfaceType) {
        final currentType = _lookupGetterReturnType(iteratorType, 'current');
        if (currentType != null) {
          return currentType;
        }
      }
    }
    return typeProvider.dynamicType;
  }

  /// Safely look up a potentially inherited getter's return type.
  ///
  /// Return the return type of the executable element with the given [name].
  /// May return `null` if the [type] does not define one.
  DartType _lookupGetterReturnType(InterfaceType type, String name) =>
      type.lookUpInheritedGetter(name)?.returnType;
}
