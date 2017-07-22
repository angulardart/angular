import 'package:angular/src/core/linker/view_type.dart' show ViewType;
import 'package:angular_compiler/angular_compiler.dart';

import '../compile_metadata.dart'
    show
        CompileDirectiveMetadata,
        CompilePipeMetadata,
        CompileIdentifierMetadata,
        CompileQueryMetadata,
        CompileTokenMap;
import '../identifiers.dart' show Identifiers;
import '../output/output_ast.dart' as o;
import "../template_ast.dart" show TemplateAst;
import 'compile_binding.dart' show CompileBinding;
import 'compile_element.dart' show CompileElement, CompileNode;
import 'compile_method.dart' show CompileMethod;
import 'compile_pipe.dart' show CompilePipe;
import 'compile_query.dart'
    show CompileQuery, createQueryListField, addQueryToTokenMap;
import 'constants.dart' show EventHandlerVars;
import 'expression_converter.dart' show NameResolver;
import 'view_compiler_utils.dart'
    show getViewFactoryName, getPropertyInView, createPureProxy;

/// Represents data to generate a host, component or embedded AppView.
///
/// Members and method builders are populated by ViewBuilder.
class CompileView implements NameResolver {
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
  List<o.Expression> viewChildren = [];

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
  List<o.ClassField> fields = [];
  List<o.ClassGetter> getters = [];
  List<o.Expression> subscriptions = [];
  bool subscribesToMockLike = false;
  CompileView componentView;
  var purePipes = new Map<String, CompilePipe>();
  List<CompilePipe> pipes = [];
  var locals = new Map<String, o.Expression>();
  String className;
  o.OutputType classType;
  o.ReadVarExpr viewFactory;
  var literalArrayCount = 0;
  var literalMapCount = 0;
  var pipeCount = 0;

  /// Whether "ctx" needs to be cached in the "detectChangesInternal" method.
  /// This is essentially true only when statements refer to "_ctx" (the cached
  /// variable).
  var cacheCtxInDetectChangesMethod = false;

  CompileView(
      this.component,
      this.genConfig,
      this.pipeMetas,
      this.styles,
      this.viewIndex,
      this.declarationElement,
      this.templateVariableBindings,
      this.deferredModules) {
    this.createMethod = new CompileMethod(this);
    this.injectorGetMethod = new CompileMethod(this);
    this.updateContentQueriesMethod = new CompileMethod(this);
    this.dirtyParentQueriesMethod = new CompileMethod(this);
    this.updateViewQueriesMethod = new CompileMethod(this);
    this.detectChangesInInputsMethod = new CompileMethod(this);
    this.detectChangesRenderPropertiesMethod = new CompileMethod(this);
    this.afterContentLifecycleCallbacksMethod = new CompileMethod(this);
    this.afterViewLifecycleCallbacksMethod = new CompileMethod(this);
    this.destroyMethod = new CompileMethod(this);
    this.viewType = getViewType(component, viewIndex);
    this.className = 'View${component.type.name}$viewIndex';
    this.classType =
        o.importType(new CompileIdentifierMetadata(name: this.className));
    this.viewFactory = o.variable(getViewFactoryName(component, viewIndex));
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
      locals[entry[1]] =
          new o.ReadClassMemberExpr('locals').key(o.literal(entry[0]));
    }
    if (declarationElement.parent != null) {
      declarationElement.setEmbeddedView(this);
    }
    if (deferredModules == null) {
      throw new ArgumentError();
    }
  }

  // Adds a binding to the view and returns binding index.
  int addBinding(CompileNode node, TemplateAst sourceAst) {
    _bindings.add(new CompileBinding(node, sourceAst));
    return _bindings.length - 1;
  }

  o.Expression callPipe(
      String name, o.Expression input, List<o.Expression> args) {
    return CompilePipe.call(this, name, (new List.from([input])..addAll(args)));
  }

  o.Expression getLocal(String name) {
    if (name == EventHandlerVars.event.name) {
      return EventHandlerVars.event;
    }
    CompileView currView = this;
    var result = currView.locals[name];
    while (result == null && currView.declarationElement.view != null) {
      currView = currView.declarationElement.view;
      result = currView.locals[name];
    }
    if (result != null) {
      return getPropertyInView(result, this, currView);
    } else {
      return null;
    }
  }

  o.Expression createLiteralArray(List<o.Expression> values) {
    if (identical(values.length, 0)) {
      return o.importExpr(Identifiers.EMPTY_ARRAY);
    }
    var proxyExpr =
        new o.ReadClassMemberExpr('_arr_${ this . literalArrayCount ++}');
    List<o.FnParam> proxyParams = [];
    List<o.Expression> proxyReturnEntries = [];
    for (var i = 0; i < values.length; i++) {
      var paramName = 'p$i';
      proxyParams.add(new o.FnParam(paramName));
      proxyReturnEntries.add(o.variable(paramName));
    }
    createPureProxy(
        o.fn(
            proxyParams,
            [new o.ReturnStatement(o.literalArr(proxyReturnEntries))],
            new o.ArrayType(o.DYNAMIC_TYPE)),
        values.length,
        proxyExpr,
        this);
    return proxyExpr.callFn(values);
  }

  o.Expression createLiteralMap(
      List<List<dynamic /* String | o . Expression */ >> entries) {
    if (identical(entries.length, 0)) {
      return o.importExpr(Identifiers.EMPTY_MAP);
    }
    var proxyExpr = new o.ReadClassMemberExpr('_map_${this.literalMapCount++}');
    List<o.FnParam> proxyParams = [];
    List<List<dynamic /* String | o . Expression */ >> proxyReturnEntries = [];
    List<o.Expression> values = [];
    for (var i = 0; i < entries.length; i++) {
      var paramName = 'p$i';
      proxyParams.add(new o.FnParam(paramName));
      proxyReturnEntries.add([entries[i][0], o.variable(paramName)]);
      values.add((entries[i][1] as o.Expression));
    }
    createPureProxy(
        o.fn(
            proxyParams,
            [new o.ReturnStatement(o.literalMap(proxyReturnEntries))],
            new o.MapType(o.DYNAMIC_TYPE)),
        entries.length,
        proxyExpr,
        this);
    return proxyExpr.callFn(values);
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
