import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/resolver.dart'
    show TypeProvider, TypeSystem;
import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/ast.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/options.dart';
import 'package:angular_analyzer_plugin/src/resolver/dart_variable_manager.dart';
import 'package:angular_analyzer_plugin/src/resolver/internal_variable.dart';
import 'package:angular_analyzer_plugin/src/resolver/directive_resolver.dart';
import 'package:angular_analyzer_plugin/src/resolver/component_content_resolver.dart';
import 'package:angular_analyzer_plugin/src/resolver/prepare_scope_visitor.dart';
import 'package:angular_analyzer_plugin/src/resolver/prepare_event_scope_visitor.dart';
import 'package:angular_analyzer_plugin/src/resolver/single_scope_resolver.dart';
import 'package:angular_analyzer_plugin/src/resolver/next_template_elements_search.dart';
import 'package:angular_analyzer_plugin/src/standard_components.dart';

/// [TemplateResolver]s resolve [Template]s; entrypoint of resolution.
class TemplateResolver {
  final TypeProvider typeProvider;
  final TypeSystem typeSystem;
  final List<Component> standardHtmlComponents;
  final Map<String, Output> standardHtmlEvents;
  final Map<String, Input> standardHtmlAttributes;
  final AngularOptions options;
  final AnalysisErrorListener errorListener;
  final StandardAngular standardAngular;
  final StandardHtml standardHtml;

  Template template;
  Component component;
  Source templateSource;
  ErrorReporter errorReporter;

  /// The full map of names to internal variables in the current template.
  var internalVariables = <String, InternalVariable>{};

  /// The full map of names to local variables in the current template.
  var localVariables = <String, LocalVariable>{};

  TemplateResolver(
      this.typeProvider,
      this.typeSystem,
      this.standardHtmlComponents,
      this.standardHtmlEvents,
      this.standardHtmlAttributes,
      this.standardAngular,
      this.standardHtml,
      this.errorListener,
      this.options);

  void resolve(Template template) {
    this.template = template;
    component = template.component;
    templateSource = component.templateSource;
    errorReporter = ErrorReporter(errorListener, templateSource);

    final root = template.ast;

    final allDirectives = <DirectiveBase>[
      ...standardHtmlComponents,
      ...component.directives
    ];

    final directiveResolver = DirectiveResolver(
        typeSystem,
        allDirectives,
        templateSource,
        template,
        standardAngular,
        standardHtml,
        errorReporter,
        errorListener,
        options.customTagNames.toSet());
    root.accept(directiveResolver);
    final contentResolver =
        ComponentContentResolver(templateSource, template, errorListener);
    root.accept(contentResolver);

    _resolveScope(root);
  }

  /// Fully resolve the given [element].
  ///
  /// This will either be a template or the root of the template, meaning it has
  /// its own scope. We have to resolve the outermost scopes first so that ngFor
  /// variables have types.
  ///
  /// See the comment block for [PrepareScopeVisitor] for the most detailed
  /// breakdown of what we do and why.
  ///
  /// Requires that we've already resolved the directives down the tree.
  void _resolveScope(ElementInfo element) {
    if (element == null) {
      return;
    }
    // apply template attributes
    final oldLocalVariables = localVariables;
    final oldInternalVariables = internalVariables;
    internalVariables = {...internalVariables};
    localVariables = {...localVariables};
    try {
      final dartVarManager =
          DartVariableManager(template, templateSource, errorListener);
      // Prepare the scopes
      element
        ..accept(PrepareScopeVisitor(
            internalVariables,
            localVariables,
            template,
            templateSource,
            typeProvider,
            dartVarManager,
            errorListener,
            standardAngular))
        // Load $event into the scopes
        ..accept(PrepareEventScopeVisitor(
            standardHtmlEvents,
            template,
            templateSource,
            localVariables,
            typeProvider,
            dartVarManager,
            errorListener))
        // Resolve the scopes
        ..accept(SingleScopeResolver(
            standardHtmlAttributes,
            component.pipes,
            component,
            template,
            templateSource,
            typeProvider,
            typeSystem,
            errorListener,
            errorReporter));

      // Now the next scope is ready to be resolved
      final tplSearch = NextTemplateElementsSearch();
      element.accept(tplSearch);
      for (final templateElement in tplSearch.results) {
        _resolveScope(templateElement);
      }
    } finally {
      internalVariables = oldInternalVariables;
      localVariables = oldLocalVariables;
    }
  }
}
