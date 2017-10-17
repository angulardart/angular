import 'package:angular/src/core/linker/view_type.dart' show ViewType;
import 'package:angular_compiler/angular_compiler.dart';
import 'package:angular/src/facade/exceptions.dart' show BaseException;

import '../compile_metadata.dart'
    show
        CompileDirectiveMetadata,
        CompilePipeMetadata,
        CompileIdentifierMetadata,
        CompileQueryMetadata,
        CompileTokenMap;
import '../identifiers.dart';
import '../output/output_ast.dart' as o;
import '../template_ast.dart' show TemplateAst;
import 'compile_binding.dart' show CompileBinding;
import 'compile_element.dart' show CompileElement, CompileNode;
import 'compile_method.dart' show CompileMethod;
import 'compile_pipe.dart' show CompilePipe;
import 'compile_query.dart'
    show CompileQuery, createQueryListField, addQueryToTokenMap;
import 'constants.dart' show parentRenderNodeVar;
import 'view_compiler_utils.dart'
    show getViewFactoryName, injectFromViewParentInjector;
import 'view_name_resolver.dart';

/// Interface to generate a build function for an AppView.
abstract class AppViewBuilder {
  /// Creates a pipe and stores reference expression in fieldName.
  void createPipeInstance(String pipeFieldName, CompilePipeMetadata pipeMeta);

  /// Constructs a pure proxy and stores instance in class member.
  void createPureProxy(
      o.Expression fn, num argCount, o.ReadClassMemberExpr pureProxyProp);
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

  int viewIndex;
  CompileElement declarationElement;
  List<List<String>> templateVariableBindings;
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
  CompileMethod createMethod;
  CompileMethod injectorGetMethod;
  CompileMethod updateContentQueriesMethod;
  CompileMethod dirtyParentQueriesMethod;
  CompileMethod updateViewQueriesMethod;
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
  var pipeCount = 0;
  ViewNameResolver nameResolver;

  CompileView(
      this.component,
      this.genConfig,
      this.pipeMetas,
      this.styles,
      this.viewIndex,
      this.declarationElement,
      this.templateVariableBindings,
      this.deferredModules) {
    createMethod = new CompileMethod(genDebugInfo);
    injectorGetMethod = new CompileMethod(genDebugInfo);
    updateContentQueriesMethod = new CompileMethod(genDebugInfo);
    dirtyParentQueriesMethod = new CompileMethod(genDebugInfo);
    updateViewQueriesMethod = new CompileMethod(genDebugInfo);
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
      for (CompileQueryMetadata queryMeta in component.viewQueries) {
        queryIndex++;
        var propName = '_viewQuery_${queryMeta.selectors[0].name}_$queryIndex';
        var queryList =
            createQueryListField(queryMeta, directiveInstance, propName, this);
        var query =
            new CompileQuery(queryMeta, queryList, directiveInstance, this);
        addQueryToTokenMap(viewQueries, query);
      }
    }

    for (List<String> entry in templateVariableBindings) {
      nameResolver.addLocal(entry[1],
          new o.ReadClassMemberExpr('locals').key(o.literal(entry[0])));
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
        query.generateImmediateUpdate(createMethod);
        query.generateDynamicUpdate(updateContentQueriesMethod);
      }
    }
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
    createMethod.resetDebugInfo(null, null);
    createMethod.addStmt(new o.WriteClassMemberExpr(
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
    createMethod.addStmt(new o.ReadClassMemberExpr(pureProxyProp.name)
        .set(o.importExpr(pureProxyId).callFn([fn]))
        .toStmt());
  }

  bool _isRootNode(CompileElement parent) {
    return !identical(parent.view, this);
  }

  // TODO: make private after all call sites move into AppViewBuilder interface.
  // Returns reference for compile element or null if compile element
  // has no attached node (root node of embedded or host view).
  o.Expression getParentRenderNode(CompileElement parent) {
    if (_isRootNode(parent)) {
      if (viewType == ViewType.COMPONENT) {
        return parentRenderNodeVar;
      } else {
        // root node of an embedded/host view
        return o.NULL_EXPR;
      }
    } else {
      return parent.component != null ? o.NULL_EXPR : parent.renderNode;
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
