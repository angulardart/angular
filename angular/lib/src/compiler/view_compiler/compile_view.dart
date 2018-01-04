import 'package:source_span/source_span.dart';
import 'package:angular/src/core/change_detection/change_detection.dart'
    show ChangeDetectionStrategy, ChangeDetectorState;
import 'package:angular/src/core/linker/view_type.dart' show ViewType;
import "package:angular/src/core/metadata/view.dart" show ViewEncapsulation;
import 'package:angular/src/facade/exceptions.dart' show BaseException;
import 'package:angular/src/transform/common/names.dart'
    show toTemplateExtension;
import 'package:angular_compiler/angular_compiler.dart';

import '../compile_metadata.dart'
    show
        CompileDirectiveMetadata,
        CompileIdentifierMetadata,
        CompileTokenMetadata,
        CompilePipeMetadata,
        CompileProviderMetadata,
        CompileQueryMetadata,
        CompileTokenMap;
import '../identifiers.dart';
import '../output/output_ast.dart' as o;
import '../template_ast.dart'
    show
        AttrAst,
        TemplateAst,
        ElementAst,
        NgContentAst,
        ProviderAst,
        ProviderAstType,
        VariableAst;
import 'compile_binding.dart' show CompileBinding;
import 'compile_element.dart' show CompileElement, CompileNode;
import 'compile_method.dart' show CompileMethod;
import 'compile_pipe.dart' show CompilePipe;
import 'compile_query.dart' show CompileQuery, addQueryToTokenMap;
import 'constants.dart'
    show
        parentRenderNodeVar,
        appViewRootElementName,
        DetectChangesVars,
        ViewProperties,
        InjectMethodVars;
import 'perf_profiler.dart';
import 'view_compiler_utils.dart'
    show
        astAttribListToMap,
        createDbgElementCall,
        createDiTokenExpression,
        createSetAttributeStatement,
        cachedParentIndexVarName,
        getViewFactoryName,
        identifierFromTagName,
        injectFromViewParentInjector,
        mergeHtmlAndDirectiveAttrs,
        ViewCompileDependency;
import 'view_name_resolver.dart';

/// Visibility of NodeReference within AppView implementation.
enum NodeReferenceVisibility {
  classPublic, // Visible across build and change detectors or other closures.
  build, // Only visible inside DOM build process.
}

var NOT_THROW_ON_CHANGES = o.not(o.importExpr(Identifiers.throwOnChanges));

/// Reference to html node created during AppView build.
class NodeReference {
  final CompileElement parent;
  final int nodeIndex;
  final String _name;
  final TemplateAst _ast;

  NodeReferenceVisibility _visibility = NodeReferenceVisibility.classPublic;

  NodeReference(this.parent, this.nodeIndex, this._ast)
      : _name = '_el_$nodeIndex';
  NodeReference.textNode(this.parent, this.nodeIndex, this._ast)
      : _name = '_text_$nodeIndex';
  NodeReference.anchor(this.parent, this.nodeIndex, this._ast)
      : _name = '_anchor_$nodeIndex',
        _visibility = NodeReferenceVisibility.build;
  NodeReference.appViewRoot()
      : parent = null,
        nodeIndex = -1,
        _ast = null,
        _name = appViewRootElementName;

  void lockVisibility(NodeReferenceVisibility visibility) {
    if (_visibility != NodeReferenceVisibility.classPublic &&
        _visibility != visibility) {
      throw new ArgumentError('The reference was already restricted. '
          'Can\'t change access to reference.');
    }
    _visibility = visibility;
  }

  o.Expression toReadExpr() {
    assert(_ast != null);
    return _visibility == NodeReferenceVisibility.classPublic
        ? new o.ReadClassMemberExpr(_name)
        : o.variable(_name);
  }

  o.Expression toWriteExpr(o.Expression value) {
    return _visibility == NodeReferenceVisibility.classPublic
        ? new o.WriteClassMemberExpr(_name, value)
        : o.variable(_name).set(value);
  }
}

/// Reference to html node created during AppView build.
class AppViewReference {
  final CompileElement parent;
  final int nodeIndex;
  final String _name;

  AppViewReference(this.parent, this.nodeIndex)
      : _name = '_compView_$nodeIndex';

  o.Expression toReadExpr() {
    return new o.ReadClassMemberExpr(_name);
  }

  o.Expression toWriteExpr(o.Expression value) {
    return new o.WriteClassMemberExpr(_name, value);
  }
}

/// Interface to generate a build function for an AppView.
abstract class AppViewBuilder {
  /// Creates an unbound literal text node.
  NodeReference createTextNode(
      CompileElement parent, int nodeIndex, String text, TemplateAst ast);

  NodeReference createBoundTextNode(
      CompileElement parent, int nodeIndex, TemplateAst ast);

  /// Create an html node and appends to parent element.
  void createElement(CompileElement parent, NodeReference elementRef,
      int nodeIndex, String tagName, TemplateAst ast);

  /// Creates an html node with a namespace and appends to parent element.
  void createElementNs(CompileElement parent, NodeReference elementRef,
      int nodeIndex, String ns, String tagName, TemplateAst ast);

  /// Create a view container for a given node reference and index.
  ///
  /// isPrivate indicates that the view container is only used for an embedded
  /// view and is not publicly shared through injection or view query.
  o.Expression createViewContainer(
      NodeReference nodeReference, int nodeIndex, bool isPrivate,
      [int parentNodeIndex]);

  /// Locally caches node reference for component and appends to parent
  /// html node.
  AppViewReference createComponentNodeAndAppend(
      CompileDirectiveMetadata component,
      CompileElement parent,
      NodeReference elementRef,
      int nodeIndex,
      ElementAst ast,
      List<ViewCompileDependency> targetDependencies,
      {bool isDeferred});

  /// Creates call to AppView.create to build an AppView.
  ///
  /// contentNodesArray provides projectable nodes to be used during
  /// initialization.
  void createAppView(AppViewReference appViewRef,
      o.Expression componentInstance, o.Expression contentNodesArray);

  /// Projects projectables at sourceAstIndex into target element.
  void projectNodesIntoElement(
      CompileElement target, int sourceAstIndex, NgContentAst ast);

  /// Writes instruction to enable css encapsulation for a node.
  void shimCssForNode(NodeReference nodeReference, int nodeIndex,
      CompileIdentifierMetadata nodeType);

  /// Creates a field to store a stream subscription to be destroyed.
  void createSubscription(o.Expression streamReference, o.Expression handler,
      {bool isMockLike: false});

  /// Add DOM event listener.
  void addDomEventListener(
      NodeReference node, String eventName, o.Expression handler);

  /// Adds event listener that is routed through EventManager for custom
  /// events.
  void addCustomEventListener(
      NodeReference node, String eventName, o.Expression handler);

  /// Initializes query target on component at startup/build time.
  void updateQueryAtStartup(CompileQuery query);

  /// Writes code to update content query targets.
  void updateContentQuery(CompileQuery query);

  /// Creates a provider as a field or local expression.
  o.Expression createProvider(
      String propName,
      CompileDirectiveMetadata directiveMetadata,
      ProviderAst provider,
      List<o.Expression> providerValueExpressions,
      bool isMulti,
      bool isEager,
      CompileElement compileElement,
      {bool forceDynamic: false});

  /// Calls function directive on view startup.
  void callFunctionalDirective(
      CompileProviderMetadata provider, List<o.Expression> parameters);

  /// Creates a pipe and stores reference expression in fieldName.
  void createPipeInstance(String pipeFieldName, CompilePipeMetadata pipeMeta);

  /// Constructs a pure proxy and stores instance in class member.
  void createPureProxy(
      o.Expression fn, num argCount, o.ReadClassMemberExpr pureProxyProp);

  /// Writes literal attribute values on the element itself and those
  /// contributed from directives on the ast node.
  ///
  /// !Component level attributes are excluded since we want to avoid per
  ///  call site duplication.
  void writeLiteralAttributeValues(
      ElementAst elementAst,
      NodeReference elementRef,
      int nodeIndex,
      List<CompileDirectiveMetadata> directives);

  /// Writes code to start defer loading an embedded template.
  void deferLoadEmbeddedTemplate(
      CompileView deferredView, CompileElement targetElement);

  /// Finally writes build statements into target.
  void writeBuildStatements(List<o.Statement> targetStatements);

  /// Writes change detection code for detectChangesInternal method.
  List<o.Statement> writeChangeDetectionStatements();

  /// Adds reference to a provider by token type and nodeIndex range.
  void addInjectable(int nodeIndex, int childNodeCount, ProviderAst provider,
      o.Expression providerExpr, List<CompileTokenMetadata> aliases);

  o.ClassMethod writeInjectorGetMethod();
}

/// Represents data to generate a host, component or embedded AppView.
///
/// Members and method builders are populated by ViewBuilder.
class CompileView implements AppViewBuilder {
  final CompileDirectiveMetadata component;
  final CompilerFlags genConfig;
  final List<CompilePipeMetadata> pipeMetas;
  final o.Expression styles;
  final Map<String, String> deferredModules;
  final _cloneAnchorNodeExpr = o
      .importExpr(Identifiers.ngAnchor)
      .callMethod('clone', [o.literal(false)]);

  int viewIndex;
  CompileElement declarationElement;
  List<VariableAst> templateVariables;
  ViewType viewType;
  CompileTokenMap<List<CompileQuery>> viewQueries;

  /// Contains references to view children so we can generate code for
  /// change detection and destroy.
  final List<o.Expression> _viewChildren = [];

  /// Flat list of all nodes inside the template including text nodes.
  List<CompileNode> nodes = [];

  /// List of references to top level nodes in view.
  List<o.Expression> rootNodesOrViewContainers = [];

  /// List of references to view containers used by embedded templates
  /// and child components.
  List<o.Expression> viewContainers = [];
  final _bindings = <CompileBinding>[];
  List<o.Statement> classStatements = [];
  CompileMethod _createMethod;
  CompileMethod _injectorGetMethod;
  CompileMethod _updateContentQueriesMethod;
  CompileMethod _updateViewQueriesMethod;
  CompileMethod dirtyParentQueriesMethod;
  CompileMethod detectChangesInInputsMethod;
  CompileMethod detectChangesRenderPropertiesMethod;
  CompileMethod detectHostChangesMethod;
  CompileMethod afterContentLifecycleCallbacksMethod;
  CompileMethod afterViewLifecycleCallbacksMethod;
  CompileMethod destroyMethod;

  /// List of methods used to handle events with non standard parameters in
  /// handlers or events with multiple actions.
  List<o.ClassMethod> eventHandlerMethods = [];
  List<o.ClassGetter> getters = [];
  List<o.Expression> subscriptions = [];
  bool subscribesToMockLike = false;
  CompileView componentView;
  var purePipes = new Map<String, CompilePipe>();
  List<CompilePipe> pipes = [];
  String className;
  o.OutputType classType;
  o.ReadVarExpr viewFactory;
  bool requiresOnChangesCall = false;
  bool requiresAfterChangesCall = false;
  var pipeCount = 0;
  ViewNameResolver nameResolver;
  static final defaultDocVarName = 'doc';

  /// Local variable name used to refer to document. null if not created yet.
  String docVarName;

  CompileView(
      this.component,
      this.genConfig,
      this.pipeMetas,
      this.styles,
      this.viewIndex,
      this.declarationElement,
      this.templateVariables,
      this.deferredModules) {
    _createMethod = new CompileMethod(genDebugInfo);
    _injectorGetMethod = new CompileMethod(genDebugInfo);
    _updateContentQueriesMethod = new CompileMethod(genDebugInfo);
    dirtyParentQueriesMethod = new CompileMethod(genDebugInfo);
    _updateViewQueriesMethod = new CompileMethod(genDebugInfo);
    detectChangesInInputsMethod = new CompileMethod(genDebugInfo);
    detectChangesRenderPropertiesMethod = new CompileMethod(genDebugInfo);
    afterContentLifecycleCallbacksMethod = new CompileMethod(genDebugInfo);
    afterViewLifecycleCallbacksMethod = new CompileMethod(genDebugInfo);
    destroyMethod = new CompileMethod(genDebugInfo);
    nameResolver = new ViewNameResolver(this);
    viewType = getViewType(component, viewIndex);
    className = '${viewIndex == 0 && viewType != ViewType.HOST ? '' : '_'}'
        'View${component.type.name}$viewIndex';
    classType = o.importType(new CompileIdentifierMetadata(name: className));
    viewFactory = o.variable(getViewFactoryName(component, viewIndex));
    switch (viewType) {
      case ViewType.HOST:
      case ViewType.COMPONENT:
        componentView = this;
        break;
      default:
        // An embedded template uses it's declaration element's componentView.
        componentView = declarationElement.view.componentView;
        break;
    }
    viewQueries = new CompileTokenMap<List<CompileQuery>>();
    if (viewType == ViewType.COMPONENT) {
      var directiveInstance = new o.ReadClassMemberExpr('ctx');
      var queryIndex = -1;
      for (CompileQueryMetadata metadata in component.viewQueries) {
        queryIndex++;
        final query = new CompileQuery.viewQuery(
          metadata: metadata,
          queryRoot: this,
          boundField: directiveInstance,
          queryIndex: queryIndex,
        );
        nameResolver.addField(query.createClassField());
        addQueryToTokenMap(viewQueries, query);
      }
    }

    for (var variable in templateVariables) {
      nameResolver.addLocal(
        variable.name,
        new o.ReadClassMemberExpr('locals').key(o.literal(variable.value)),
        variable.type, // NgFor locals are augmented with type information.
      );
    }
    if (declarationElement.parent != null) {
      declarationElement.setEmbeddedView(this);
    }
    if (deferredModules == null) {
      throw new ArgumentError();
    }
  }

  bool get genDebugInfo => genConfig.genDebugInfo;

  // Adds reference to a child view.
  void addViewChild(o.Expression componentViewExpr) {
    _viewChildren.add(componentViewExpr);
  }

  // Returns list of references to view children.
  List<o.Expression> get viewChildren => _viewChildren;

  // Adds a binding to the view and returns binding index.
  int addBinding(CompileNode node, TemplateAst sourceAst) {
    _bindings.add(new CompileBinding(node, sourceAst));
    return _bindings.length - 1;
  }

  void afterNodes() {
    for (var pipe in pipes) {
      pipe.create();
    }
    for (var queries in viewQueries.values) {
      for (var query in queries) {
        updateQueryAtStartup(query);
        updateContentQuery(query);
      }
    }
  }

  @override
  NodeReference createTextNode(
      CompileElement parent, int nodeIndex, String text, TemplateAst ast) {
    var renderNode = new NodeReference.textNode(parent, nodeIndex, ast);
    renderNode.lockVisibility(NodeReferenceVisibility.build);
    _createMethod.addStmt(new o.DeclareVarStmt(
        renderNode._name,
        o.importExpr(Identifiers.HTML_TEXT_NODE).instantiate([o.literal(text)]),
        o.importType(Identifiers.HTML_TEXT_NODE)));
    var parentRenderNodeExpr = _getParentRenderNode(parent);
    if (parentRenderNodeExpr != null && parentRenderNodeExpr != o.NULL_EXPR) {
      // Write append code.
      _createMethod.addStmt(parentRenderNodeExpr
          .callMethod('append', [renderNode.toReadExpr()]).toStmt());
    }
    if (genConfig.genDebugInfo) {
      _createMethod.addStmt(
          createDbgElementCall(renderNode.toReadExpr(), nodeIndex, ast));
    }
    return renderNode;
  }

  @override
  NodeReference createBoundTextNode(
      CompileElement parent, int nodeIndex, TemplateAst ast) {
    // If Text field is bound, we need access to the renderNode beyond
    // build method and write reference to class member.
    NodeReference renderNode =
        new NodeReference.textNode(parent, nodeIndex, ast);
    nameResolver.addField(new o.ClassField(renderNode._name,
        outputType: o.importType(Identifiers.HTML_TEXT_NODE),
        modifiers: const [o.StmtModifier.Private]));

    var parentRenderNodeExpr = _getParentRenderNode(parent);
    var createRenderNodeExpr = renderNode.toWriteExpr(
        o.importExpr(Identifiers.HTML_TEXT_NODE).instantiate([o.literal('')]));
    _createMethod.addStmt(createRenderNodeExpr.toStmt());

    if (parentRenderNodeExpr != null && parentRenderNodeExpr != o.NULL_EXPR) {
      // Write append code.
      _createMethod.addStmt(parentRenderNodeExpr
          .callMethod('append', [renderNode.toReadExpr()]).toStmt());
    }
    if (genConfig.genDebugInfo) {
      _createMethod.addStmt(
          createDbgElementCall(renderNode.toReadExpr(), nodeIndex, ast));
    }
    return renderNode;
  }

  /// Create an html node and appends to parent element.
  void createElement(CompileElement parent, NodeReference elementRef,
      int nodeIndex, String tagName, TemplateAst ast) {
    var parentRenderNodeExpr = _getParentRenderNode(parent);
    final generateDebugInfo = genConfig.genDebugInfo;

    if (!_isRootNodeOfHost(nodeIndex)) {
      String name = (elementRef.toReadExpr() as o.ReadClassMemberExpr).name;
      nameResolver.addField(new o.ClassField(name,
          outputType: o.importType(identifierFromTagName(tagName)),
          modifiers: const [o.StmtModifier.Private]));
    }

    _createElementAndAppend(tagName, parentRenderNodeExpr, elementRef,
        generateDebugInfo, ast.sourceSpan, nodeIndex);
  }

  void _createElementAndAppend(
      String tagName,
      o.Expression parent,
      NodeReference elementRef,
      bool generateDebugInfo,
      SourceSpan debugSpan,
      int debugNodeIndex) {
    // No namespace just call [document.createElement].
    if (docVarName == null) {
      _createMethod.addStmt(_createLocalDocumentVar());
    }

    List<o.Expression> debugParams;
    if (generateDebugInfo) {
      debugParams = [
        o.literal(debugNodeIndex),
        debugSpan?.start == null
            ? o.NULL_EXPR
            : o.literal(debugSpan.start.line),
        debugSpan?.start == null
            ? o.NULL_EXPR
            : o.literal(debugSpan.start.column)
      ];
    }

    if (parent != null && parent != o.NULL_EXPR) {
      o.Expression createExpr;
      List<o.Expression> createParams;
      if (generateDebugInfo) {
        createParams = <o.Expression>[
          o.THIS_EXPR,
          new o.ReadVarExpr(docVarName)
        ];
      } else {
        createParams = <o.Expression>[new o.ReadVarExpr(docVarName)];
      }

      CompileIdentifierMetadata createAndAppendMethod;
      switch (tagName) {
        case 'div':
          createAndAppendMethod = generateDebugInfo
              ? Identifiers.createDivAndAppendDbg
              : Identifiers.createDivAndAppend;
          break;
        case 'span':
          createAndAppendMethod = generateDebugInfo
              ? Identifiers.createSpanAndAppendDbg
              : Identifiers.createSpanAndAppend;
          break;
        default:
          createAndAppendMethod = generateDebugInfo
              ? Identifiers.createAndAppendDbg
              : Identifiers.createAndAppend;
          createParams.add(o.literal(tagName));
          break;
      }
      createParams.add(parent);
      if (generateDebugInfo) {
        createParams.addAll(debugParams);
      }
      createExpr = o.importExpr(createAndAppendMethod).callFn(createParams);
      _createMethod.addStmt(elementRef.toWriteExpr(createExpr).toStmt());
    } else {
      // No parent node, just create element and assign.
      var createRenderNodeExpr = new o.ReadVarExpr(docVarName)
          .callMethod('createElement', [o.literal(tagName)]);
      _createMethod
          .addStmt(elementRef.toWriteExpr(createRenderNodeExpr).toStmt());
      if (generateDebugInfo) {
        _createMethod.addStmt(o
            .importExpr(Identifiers.dbgElm)
            .callFn(<o.Expression>[o.THIS_EXPR, elementRef.toReadExpr()]
              ..addAll(debugParams))
            .toStmt());
      }
    }
  }

  o.Statement _createLocalDocumentVar() {
    docVarName = defaultDocVarName;
    return new o.DeclareVarStmt(
        docVarName, o.importExpr(Identifiers.HTML_DOCUMENT));
  }

  /// Creates an html node with a namespace and appends to parent element.
  void createElementNs(CompileElement parent, NodeReference elementRef,
      int nodeIndex, String ns, String tagName, TemplateAst ast) {
    var parentRenderNodeExpr = _getParentRenderNode(parent);
    final generateDebugInfo = genConfig.genDebugInfo;
    if (docVarName == null) {
      _createMethod.addStmt(_createLocalDocumentVar());
    }

    if (!_isRootNodeOfHost(nodeIndex)) {
      String name = (elementRef.toReadExpr() as o.ReadClassMemberExpr).name;
      nameResolver.addField(new o.ClassField(name,
          outputType: o.importType(identifierFromTagName('$ns:$tagName')),
          modifiers: const [o.StmtModifier.Private]));
    }
    var createRenderNodeExpr = o
        .variable(docVarName)
        .callMethod('createElementNS', [o.literal(ns), o.literal(tagName)]);
    _createMethod
        .addStmt(elementRef.toWriteExpr(createRenderNodeExpr).toStmt());
    if (parentRenderNodeExpr != null && parentRenderNodeExpr != o.NULL_EXPR) {
      // Write code to append to parent node.
      _createMethod.addStmt(parentRenderNodeExpr
          .callMethod('append', [elementRef.toReadExpr()]).toStmt());
    }
    if (generateDebugInfo) {
      _createMethod.addStmt(
          createDbgElementCall(elementRef.toReadExpr(), nodeIndex, ast));
    }
  }

  /// Adds a field member that holds the reference to a child app view for
  /// a hosted component.
  AppViewReference _createAppViewNodeAndComponent(
      CompileElement parent,
      CompileDirectiveMetadata childComponent,
      NodeReference elementRef,
      int nodeIndex,
      bool isDeferred,
      ElementAst ast,
      List<ViewCompileDependency> targetDeps) {
    CompileIdentifierMetadata componentViewIdentifier =
        new CompileIdentifierMetadata(name: 'View${childComponent.type.name}0');
    targetDeps.add(
        new ViewCompileDependency(childComponent, componentViewIdentifier));

    bool isHostRootView = nodeIndex == 0 && viewType == ViewType.HOST;
    var elementType = isHostRootView
        ? Identifiers.HTML_HTML_ELEMENT
        : identifierFromTagName(ast.name);

    if (!isHostRootView) {
      nameResolver.addField(new o.ClassField(elementRef._name,
          outputType: o.importType(elementType),
          modifiers: const [o.StmtModifier.Private]));
    }

    AppViewReference appViewRef = new AppViewReference(parent, nodeIndex);

    var appViewType = isDeferred
        ? o.importType(Identifiers.AppView, null)
        : o.importType(componentViewIdentifier);

    nameResolver
        .addField(new o.ClassField(appViewRef._name, outputType: appViewType));

    if (isDeferred) {
      // When deferred, we use AppView<dynamic> as type to store instance
      // of component and create the instance using:
      // deferredLibName.viewFactory_SomeComponent(...)
      CompileIdentifierMetadata nestedComponentIdentifier =
          new CompileIdentifierMetadata(
              name: getViewFactoryName(childComponent, 0));
      targetDeps.add(
          new ViewCompileDependency(childComponent, nestedComponentIdentifier));

      var importExpr = o.importExpr(nestedComponentIdentifier);
      _createMethod.addStmt(new o.WriteClassMemberExpr(appViewRef._name,
          importExpr.callFn([o.THIS_EXPR, o.literal(nodeIndex)])).toStmt());
    } else {
      // Create instance of component using ViewSomeComponent0 AppView.
      var createComponentInstanceExpr = o
          .importExpr(componentViewIdentifier)
          .instantiate([o.THIS_EXPR, o.literal(nodeIndex)]);
      _createMethod.addStmt(new o.WriteClassMemberExpr(
              appViewRef._name, createComponentInstanceExpr)
          .toStmt());
    }
    return appViewRef;
  }

  NodeReference createViewContainerAnchor(
      CompileElement parent, int nodeIndex, TemplateAst ast) {
    NodeReference renderNode = new NodeReference.anchor(parent, nodeIndex, ast);
    var assignCloneAnchorNodeExpr =
        (renderNode.toReadExpr() as o.ReadVarExpr).set(_cloneAnchorNodeExpr);
    _createMethod.addStmt(assignCloneAnchorNodeExpr.toDeclStmt());
    var parentNode = _getParentRenderNode(parent);
    if (parentNode != o.NULL_EXPR) {
      var addCommentStmt =
          parentNode.callMethod('append', [renderNode.toReadExpr()]).toStmt();
      _createMethod.addStmt(addCommentStmt);
    }

    if (genConfig.genDebugInfo) {
      _createMethod.addStmt(
          createDbgElementCall(renderNode.toReadExpr(), nodeIndex, ast));
    }
    return renderNode;
  }

  @override
  o.Expression createViewContainer(
      NodeReference nodeReference, int nodeIndex, bool isPrivate,
      [int parentNodeIndex]) {
    o.Expression renderNode = nodeReference.toReadExpr();
    var fieldName = '_appEl_$nodeIndex';
    // Create instance field for app element.
    nameResolver.addField(new o.ClassField(fieldName,
        outputType: o.importType(Identifiers.ViewContainer),
        modifiers: [o.StmtModifier.Private]));

    // Write code to create an instance of ViewContainer.
    // Example:
    //     this._appEl_2 = new import7.ViewContainer(2,0,this,this._anchor_2);
    var statement = new o.WriteClassMemberExpr(
        fieldName,
        o.importExpr(Identifiers.ViewContainer).instantiate([
          o.literal(nodeIndex),
          o.literal(parentNodeIndex),
          o.THIS_EXPR,
          renderNode
        ])).toStmt();
    _createMethod.addStmt(statement);
    var appViewContainer = new o.ReadClassMemberExpr(fieldName);
    if (!isPrivate) {
      viewContainers.add(appViewContainer);
    }
    return appViewContainer;
  }

  @override
  AppViewReference createComponentNodeAndAppend(
      CompileDirectiveMetadata component,
      CompileElement parent,
      NodeReference elementRef,
      int nodeIndex,
      ElementAst ast,
      List<ViewCompileDependency> targetDependencies,
      {bool isDeferred}) {
    AppViewReference compAppViewExpr = _createAppViewNodeAndComponent(parent,
        component, elementRef, nodeIndex, isDeferred, ast, targetDependencies);

    if (_isRootNodeOfHost(nodeIndex)) {
      // Assign root element created by viewfactory call to our own root.
      _createMethod.addStmt(elementRef
          .toWriteExpr(
              compAppViewExpr.toReadExpr().prop(appViewRootElementName))
          .toStmt());
      if (genConfig.genDebugInfo) {
        _createMethod
            .addStmt(_createDbgIndexElementCall(elementRef, nodes.length));
      }
    } else {
      var parentRenderNodeExpr = _getParentRenderNode(parent);
      final generateDebugInfo = genConfig.genDebugInfo;
      _createMethod.addStmt(elementRef
          .toWriteExpr(
              compAppViewExpr.toReadExpr().prop(appViewRootElementName))
          .toStmt());
      if (parentRenderNodeExpr != null && parentRenderNodeExpr != o.NULL_EXPR) {
        // Write code to append to parent node.
        _createMethod.addStmt(parentRenderNodeExpr
            .callMethod('append', [elementRef.toReadExpr()]).toStmt());
      }
      if (generateDebugInfo) {
        _createMethod.addStmt(
            createDbgElementCall(elementRef.toReadExpr(), nodes.length, ast));
      }
    }
    return compAppViewExpr;
  }

  @override
  void createAppView(AppViewReference appViewRef,
      o.Expression componentInstance, o.Expression contentNodesArray) {
    _createMethod.addStmt(appViewRef
        .toReadExpr()
        .callMethod('create', [componentInstance, contentNodesArray]).toStmt());
  }

  o.Statement _createDbgIndexElementCall(NodeReference nodeRef, int nodeIndex) {
    return new o.InvokeMemberMethodExpr(
        'dbgIdx', [nodeRef.toReadExpr(), o.literal(nodeIndex)]).toStmt();
  }

  bool _isRootNodeOfHost(int nodeIndex) =>
      nodeIndex == 0 && viewType == ViewType.HOST;

  @override
  void projectNodesIntoElement(
      CompileElement target, int sourceAstIndex, NgContentAst ast) {
    // The projected nodes originate from a different view, so we don't
    // have debug information for them.
    _createMethod.resetDebugInfo(null, ast);
    var parentRenderNode = _getParentRenderNode(target);
    // AppView.projectableNodes property contains the list of nodes
    // to project for each NgContent.
    // Creates a call to project(parentNode, nodeIndex).
    var nodesExpression = ViewProperties.projectableNodes.key(
        o.literal(sourceAstIndex),
        new o.ArrayType(o.importType(Identifiers.HTML_NODE)));
    bool isRootNode = !identical(target.view, this);
    if (!identical(parentRenderNode, o.NULL_EXPR)) {
      _createMethod.addStmt(new o.InvokeMemberMethodExpr(
          'project', [parentRenderNode, o.literal(ast.index)]).toStmt());
    } else if (isRootNode) {
      if (!identical(viewType, ViewType.COMPONENT)) {
        // store root nodes only for embedded/host views
        rootNodesOrViewContainers.add(nodesExpression);
      }
    } else {
      if (target.component != null && ast.ngContentIndex != null) {
        target.addContentNode(ast.ngContentIndex, nodesExpression);
      }
    }
  }

  @override
  void shimCssForNode(NodeReference nodeReference, int nodeIndex,
      CompileIdentifierMetadata nodeType) {
    if (_isRootNodeOfHost(nodeIndex)) return;
    if (component.template.encapsulation == ViewEncapsulation.Emulated) {
      // Set ng_content class for CSS shim.
      String shimMethod =
          nodeType != Identifiers.HTML_ELEMENT ? 'addShimC' : 'addShimE';
      o.Expression shimClassExpr = new o.InvokeMemberMethodExpr(
          shimMethod, [nodeReference.toReadExpr()]);
      _createMethod.addStmt(shimClassExpr.toStmt());
    }
  }

  @override
  void createSubscription(o.Expression streamReference, o.Expression handler,
      {bool isMockLike: false}) {
    final subscription = o.variable('subscription_${subscriptions.length}');
    subscriptions.add(subscription);
    _createMethod.addStmt(subscription
        .set(streamReference.callMethod(
            o.BuiltinMethod.SubscribeObservable, [handler],
            checked: isMockLike))
        .toDeclStmt(null, [o.StmtModifier.Final]));
    if (isMockLike) {
      subscribesToMockLike = true;
    }
  }

  @override
  void addDomEventListener(
      NodeReference node, String eventName, o.Expression handler) {
    var listenExpr = node
        .toReadExpr()
        .callMethod('addEventListener', [o.literal(eventName), handler]);
    _createMethod.addStmt(listenExpr.toStmt());
  }

  @override
  void addCustomEventListener(
      NodeReference node, String eventName, o.Expression handler) {
    final appViewUtilsExpr = o.importExpr(Identifiers.appViewUtils);
    final eventManagerExpr = appViewUtilsExpr.prop('eventManager');
    var listenExpr = eventManagerExpr.callMethod(
        'addEventListener', [node.toReadExpr(), o.literal(eventName), handler]);
    _createMethod.addStmt(listenExpr.toStmt());
  }

  @override
  void updateQueryAtStartup(CompileQuery query) {
    _createMethod.addStmts(query.createImmediateUpdates());
  }

  @override
  void updateContentQuery(CompileQuery query) {
    _updateContentQueriesMethod.addStmts(query.createDynamicUpdates());
  }

  /// Creates a class field and assigns the resolvedProviderValueExpr.
  ///
  /// Eager Example:
  ///   _TemplateRef_9_4 =
  ///       new TemplateRef(_appEl_9,viewFactory_SampleComponent7);
  ///
  /// Lazy:
  ///
  /// TemplateRef _TemplateRef_9_4;
  ///
  @override
  o.Expression createProvider(
      String propName,
      CompileDirectiveMetadata directiveMetadata,
      ProviderAst provider,
      List<o.Expression> providerValueExpressions,
      bool isMulti,
      bool isEager,
      CompileElement compileElement,
      {bool forceDynamic: false}) {
    var resolvedProviderValueExpr;
    var type;
    if (isMulti) {
      resolvedProviderValueExpr = o.literalArr(providerValueExpressions);
      type = new o.ArrayType(provider.multiProviderType != null
          ? o.importType(provider.multiProviderType)
          : o.DYNAMIC_TYPE);
    } else {
      resolvedProviderValueExpr = providerValueExpressions[0];
      type = providerValueExpressions[0].type;
    }

    type ??= o.DYNAMIC_TYPE;

    bool providerHasChangeDetector =
        provider.providerType == ProviderAstType.Directive &&
            directiveMetadata != null &&
            directiveMetadata.requiresDirectiveChangeDetector;

    CompileIdentifierMetadata changeDetectorType;
    if (providerHasChangeDetector) {
      changeDetectorType = new CompileIdentifierMetadata(
          name: directiveMetadata.identifier.name + 'NgCd',
          moduleUrl:
              toTemplateExtension(directiveMetadata.identifier.moduleUrl));
    }

    List<o.Expression> changeDetectorParams;
    if (providerHasChangeDetector) {
      changeDetectorParams = [resolvedProviderValueExpr];
      if (directiveMetadata.changeDetection ==
          ChangeDetectionStrategy.Stateful) {
        changeDetectorParams.add(o.THIS_EXPR);
        changeDetectorParams.add(compileElement.renderNode.toReadExpr());
      }
    }

    if (isEager) {
      // Check if we need to reach this directive or component beyond the
      // contents of the build() function. Otherwise allocate locally.
      if (compileElement.publishesTemplateRef ||
          compileElement.hasTemplateRefQuery ||
          provider.dynamicallyReachable) {
        if (providerHasChangeDetector) {
          nameResolver.addField(new o.ClassField(propName,
              outputType: o.importType(changeDetectorType),
              modifiers: const [o.StmtModifier.Private]));
          _createMethod.addStmt(new o.WriteClassMemberExpr(
                  propName,
                  o
                      .importExpr(changeDetectorType)
                      .instantiate(changeDetectorParams))
              .toStmt());
          return new o.ReadPropExpr(
              new o.ReadClassMemberExpr(
                  propName, o.importType(changeDetectorType)),
              'instance',
              outputType: forceDynamic ? o.DYNAMIC_TYPE : type);
        } else {
          nameResolver.addField(new o.ClassField(propName,
              outputType: forceDynamic ? o.DYNAMIC_TYPE : type,
              modifiers: const [o.StmtModifier.Private]));
          _createMethod.addStmt(
              new o.WriteClassMemberExpr(propName, resolvedProviderValueExpr)
                  .toStmt());
        }
      } else {
        // Since provider is not dynamically reachable and we only need
        // the provider locally in build, create a local var.
        var localVar =
            o.variable(propName, forceDynamic ? o.DYNAMIC_TYPE : type);
        _createMethod
            .addStmt(localVar.set(resolvedProviderValueExpr).toDeclStmt());
        return localVar;
      }
    } else {
      // We don't have to eagerly initialize this object. Add an uninitialized
      // class field and provide a getter to construct the provider on demand.
      var internalField = '_$propName';
      nameResolver.addField(new o.ClassField(internalField,
          outputType: forceDynamic
              ? o.DYNAMIC_TYPE
              : (providerHasChangeDetector
                  ? o.importType(changeDetectorType)
                  : type),
          modifiers: const [o.StmtModifier.Private]));
      var getter = new CompileMethod(genDebugInfo);
      getter.resetDebugInfo(compileElement.nodeIndex, compileElement.sourceAst);

      if (providerHasChangeDetector) {
        resolvedProviderValueExpr =
            o.importExpr(changeDetectorType).instantiate(changeDetectorParams);
      }
      // Note: Equals is important for JS so that it also checks the undefined case!
      var statements = <o.Statement>[
        new o.WriteClassMemberExpr(internalField, resolvedProviderValueExpr)
            .toStmt()
      ];
      var readVars = o.findReadVarNames(statements);
      if (readVars.contains(cachedParentIndexVarName)) {
        statements.insert(
            0,
            new o.DeclareVarStmt(cachedParentIndexVarName,
                new o.ReadClassMemberExpr('viewData').prop('parentIndex')));
      }
      getter.addStmt(new o.IfStmt(
          new o.ReadClassMemberExpr(internalField).isBlank(), statements));
      getter.addStmt(
          new o.ReturnStatement(new o.ReadClassMemberExpr(internalField)));
      getters.add(new o.ClassGetter(
          propName,
          getter.finish(),
          forceDynamic
              ? o.DYNAMIC_TYPE
              : (providerHasChangeDetector ? changeDetectorType : type)));
    }
    return new o.ReadClassMemberExpr(propName);
  }

  @override
  void callFunctionalDirective(
      CompileProviderMetadata provider, List<o.Expression> parameters) {
    // Add functional directive invocation.
    final invokeExpr = o.importExpr(provider.useClass).callFn(parameters);
    _createMethod.addStmt(invokeExpr.toStmt());
  }

  @override
  void createPipeInstance(String name, CompilePipeMetadata pipeMeta) {
    var deps = pipeMeta.type.diDeps.map((diDep) {
      if (diDep.token
          .equalsTo(identifierToken(Identifiers.ChangeDetectorRef))) {
        return new o.ReadClassMemberExpr('ref');
      }
      return injectFromViewParentInjector(this, diDep.token, false);
    }).toList();
    nameResolver.addField(new o.ClassField(name,
        outputType: o.importType(pipeMeta.type),
        modifiers: [o.StmtModifier.Private]));
    _createMethod.resetDebugInfo(null, null);
    _createMethod.addStmt(new o.WriteClassMemberExpr(
            name, o.importExpr(pipeMeta.type).instantiate(deps))
        .toStmt());
  }

  @override
  void createPureProxy(
    o.Expression fn,
    num argCount,
    o.ReadClassMemberExpr pureProxyProp, {
    o.OutputType pureProxyType,
  }) {
    nameResolver.addField(
      new o.ClassField(
        pureProxyProp.name,
        outputType: pureProxyType,
        modifiers: const [o.StmtModifier.Private],
      ),
    );
    var pureProxyId = argCount < Identifiers.pureProxies.length
        ? Identifiers.pureProxies[argCount]
        : null;
    if (pureProxyId == null) {
      throw new BaseException(
          'Unsupported number of argument for pure functions: $argCount');
    }
    _createMethod.addStmt(new o.ReadClassMemberExpr(pureProxyProp.name)
        .set(o.importExpr(pureProxyId).callFn([fn]))
        .toStmt());
  }

  @override
  void writeLiteralAttributeValues(
      ElementAst elementAst,
      NodeReference nodeReference,
      int nodeIndex,
      List<CompileDirectiveMetadata> directives) {
    List<AttrAst> attrs = elementAst.attrs;
    var htmlAttrs = astAttribListToMap(attrs);
    // Create statements to initialize literal attribute values.
    // For example, a directive may have hostAttributes setting class name.
    var attrNameAndValues = mergeHtmlAndDirectiveAttrs(htmlAttrs, directives,
        excludeComponent: true);
    for (int i = 0, len = attrNameAndValues.length; i < len; i++) {
      o.Statement stmt = createSetAttributeStatement(
          elementAst.name,
          nodeReference.toReadExpr(),
          attrNameAndValues[i][0],
          attrNameAndValues[i][1]);
      _createMethod.addStmt(stmt);
    }
  }

  @override
  void deferLoadEmbeddedTemplate(
      CompileView deferredView, CompileElement targetElement) {
    var statements = <o.Statement>[];
    targetElement.writeDeferredLoader(
        deferredView, targetElement.appViewContainer, statements);
    _createMethod.addStmts(statements);
    detectChangesRenderPropertiesMethod.addStmt(targetElement.appViewContainer
        .callMethod('detectChangesInNestedViews', const []).toStmt());
  }

  @override
  void writeBuildStatements(List<o.Statement> targetStatements) {
    targetStatements.addAll(_createMethod.finish());
  }

  @override
  List<o.Statement> writeChangeDetectionStatements() {
    var statements = <o.Statement>[];
    if (detectChangesInInputsMethod.isEmpty &&
        _updateContentQueriesMethod.isEmpty &&
        afterContentLifecycleCallbacksMethod.isEmpty &&
        detectChangesRenderPropertiesMethod.isEmpty &&
        _updateViewQueriesMethod.isEmpty &&
        afterViewLifecycleCallbacksMethod.isEmpty &&
        viewChildren.isEmpty &&
        viewContainers.isEmpty) {
      return statements;
    }

    if (genConfig.profileFor == Profile.build) {
      genProfileCdStart(this, statements);
    }

    // Declare variables for locals used in this method.
    statements.addAll(nameResolver.getLocalDeclarations());

    // Add @Input change detectors.
    statements.addAll(detectChangesInInputsMethod.finish());

    // Add content child change detection calls.
    for (o.Expression contentChild in viewContainers) {
      statements.add(
          contentChild.callMethod('detectChangesInNestedViews', []).toStmt());
    }

    // Add Content query updates.
    List<o.Statement> afterContentStmts =
        new List.from(_updateContentQueriesMethod.finish())
          ..addAll(afterContentLifecycleCallbacksMethod.finish());
    if (afterContentStmts.isNotEmpty) {
      if (genConfig.genDebugInfo) {
        // Prevent query list updates when we run change detection for
        // second time to check if values are stabilized.
        statements.add(new o.IfStmt(NOT_THROW_ON_CHANGES, afterContentStmts));
      } else {
        statements.addAll(afterContentStmts);
      }
    }

    // Add render properties change detectors.
    statements.addAll(detectChangesRenderPropertiesMethod.finish());

    // Add view child change detection calls.
    for (o.Expression viewChild in viewChildren) {
      statements.add(viewChild.callMethod('detectChanges', []).toStmt());
    }

    List<o.Statement> afterViewStmts =
        new List.from(_updateViewQueriesMethod.finish())
          ..addAll(afterViewLifecycleCallbacksMethod.finish());
    if (afterViewStmts.isNotEmpty) {
      if (genConfig.genDebugInfo) {
        statements.add(new o.IfStmt(NOT_THROW_ON_CHANGES, afterViewStmts));
      } else {
        statements.addAll(afterViewStmts);
      }
    }
    var varStmts = [];
    var readVars = o.findReadVarNames(statements);
    var writeVars = o.findWriteVarNames(statements);
    if (readVars.contains(cachedParentIndexVarName)) {
      varStmts.add(new o.DeclareVarStmt(cachedParentIndexVarName,
          new o.ReadClassMemberExpr('viewData').prop('parentIndex')));
    }
    if (readVars.contains(DetectChangesVars.cachedCtx.name)) {
      // Cache [ctx] class field member as typed [_ctx] local for change
      // detection code to consume.
      var contextType =
          viewType != ViewType.HOST ? o.importType(component.type) : null;
      varStmts.add(o
          .variable(DetectChangesVars.cachedCtx.name)
          .set(new o.ReadClassMemberExpr('ctx'))
          .toDeclStmt(contextType, [o.StmtModifier.Final]));
    }
    if (readVars.contains(DetectChangesVars.changed.name) ||
        writeVars.contains(DetectChangesVars.changed.name)) {
      varStmts.add(DetectChangesVars.changed
          .set(o.literal(false))
          .toDeclStmt(o.BOOL_TYPE));
    }
    if (readVars.contains(DetectChangesVars.changes.name) ||
        requiresOnChangesCall) {
      varStmts.add(new o.DeclareVarStmt(DetectChangesVars.changes.name, null,
          new o.MapType(o.importType(Identifiers.SimpleChange))));
    }
    if (readVars.contains(DetectChangesVars.firstCheck.name)) {
      varStmts.add(new o.DeclareVarStmt(
          DetectChangesVars.firstCheck.name,
          o.THIS_EXPR
              .prop('cdState')
              .equals(o.literal(ChangeDetectorState.NeverChecked)),
          o.BOOL_TYPE));
    }
    if (genConfig.profileFor == Profile.build) {
      genProfileCdEnd(this, statements);
    }
    return new List.from(varStmts)..addAll(statements);
  }

  @override
  void addInjectable(int nodeIndex, int childNodeCount, ProviderAst provider,
      o.Expression providerExpr, List<CompileTokenMetadata> aliases) {
    var indexCondition;
    if (childNodeCount > 0) {
      indexCondition = o
          .literal(nodeIndex)
          .lowerEquals(InjectMethodVars.nodeIndex)
          .and(InjectMethodVars.nodeIndex
              .lowerEquals(o.literal(nodeIndex + childNodeCount)));
    } else {
      indexCondition = o.literal(nodeIndex).equals(InjectMethodVars.nodeIndex);
    }
    o.Expression tokenCondition = InjectMethodVars.token
        .identical(createDiTokenExpression(provider.token));
    if (aliases != null) {
      for (var alias in aliases) {
        tokenCondition = tokenCondition.or(
            InjectMethodVars.token.identical(createDiTokenExpression(alias)));
      }
    }
    _injectorGetMethod.addStmt(new o.IfStmt(tokenCondition.and(indexCondition),
        [new o.ReturnStatement(providerExpr)]));
  }

  @override
  o.ClassMethod writeInjectorGetMethod() {
    return new o.ClassMethod(
        "injectorGetInternal",
        [
          new o.FnParam(InjectMethodVars.token.name, o.DYNAMIC_TYPE),
          new o.FnParam(InjectMethodVars.nodeIndex.name, o.INT_TYPE),
          new o.FnParam(InjectMethodVars.notFoundResult.name, o.DYNAMIC_TYPE)
        ],
        _addReturnValueIfNotEmpty(
            _injectorGetMethod.finish(), InjectMethodVars.notFoundResult),
        o.DYNAMIC_TYPE,
        null,
        ['override']);
  }

  // Returns reference for compile element or null if compile element
  // has no attached node (root node of embedded or host view).
  o.Expression _getParentRenderNode(CompileElement parentElement) {
    bool isRootNode = !identical(parentElement.view, this);
    if (isRootNode) {
      if (viewType == ViewType.COMPONENT) {
        return parentRenderNodeVar;
      } else {
        // root node of an embedded/host view
        return o.NULL_EXPR;
      }
    } else {
      // If our parent element is a component, this is transcluded content
      // and we should return null since there is no physical element in
      // this view. Otherwise return the actual html node reference.
      return parentElement.component != null
          ? o.NULL_EXPR
          : parentElement.renderNode.toReadExpr();
    }
  }
}

ViewType getViewType(
    CompileDirectiveMetadata component, int embeddedTemplateIndex) {
  if (embeddedTemplateIndex > 0) {
    return ViewType.EMBEDDED;
  } else if (component.type.isHost) {
    return ViewType.HOST;
  } else {
    return ViewType.COMPONENT;
  }
}

List<o.Statement> _addReturnValueIfNotEmpty(
    List<o.Statement> statements, o.Expression value) {
  if (statements.isEmpty) {
    return statements;
  } else {
    return new List.from(statements)..addAll([new o.ReturnStatement(value)]);
  }
}
