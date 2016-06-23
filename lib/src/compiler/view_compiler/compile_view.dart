library angular2.src.compiler.view_compiler.compile_view;

import "package:angular2/src/facade/lang.dart" show isPresent, isBlank;
import "package:angular2/src/facade/collection.dart"
    show ListWrapper, StringMapWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "../output/output_ast.dart" as o;
import "../identifiers.dart" show Identifiers, identifierToken;
import "constants.dart" show EventHandlerVars;
import "compile_query.dart"
    show CompileQuery, createQueryList, addQueryToTokenMap;
import "expression_converter.dart" show NameResolver;
import "compile_element.dart" show CompileElement, CompileNode;
import "compile_method.dart" show CompileMethod;
import "package:angular2/src/core/linker/view_type.dart" show ViewType;
import "../compile_metadata.dart"
    show
        CompileDirectiveMetadata,
        CompilePipeMetadata,
        CompileIdentifierMetadata,
        CompileTokenMap;
import "util.dart"
    show
        getViewFactoryName,
        injectFromViewParentInjector,
        createDiTokenExpression,
        getPropertyInView;
import "../config.dart" show CompilerConfig;
import "compile_binding.dart" show CompileBinding;
import "lifecycle_binder.dart" show bindPipeDestroyLifecycleCallbacks;

class CompilePipe {
  CompilePipe() {}
}

class CompileView implements NameResolver {
  CompileDirectiveMetadata component;
  CompilerConfig genConfig;
  List<CompilePipeMetadata> pipeMetas;
  o.Expression styles;
  num viewIndex;
  CompileElement declarationElement;
  List<List<String>> templateVariableBindings;
  ViewType viewType;
  CompileTokenMap<List<CompileQuery>> viewQueries;
  List<CompileNode> nodes = [];
  // root nodes or AppElements for ViewContainers
  List<o.Expression> rootNodesOrAppElements = [];
  List<CompileBinding> bindings = [];
  List<o.Statement> classStatements = [];
  CompileMethod createMethod;
  CompileMethod injectorGetMethod;
  CompileMethod updateContentQueriesMethod;
  CompileMethod dirtyParentQueriesMethod;
  CompileMethod updateViewQueriesMethod;
  CompileMethod detectChangesInInputsMethod;
  CompileMethod detectChangesRenderPropertiesMethod;
  CompileMethod afterContentLifecycleCallbacksMethod;
  CompileMethod afterViewLifecycleCallbacksMethod;
  CompileMethod destroyMethod;
  List<o.ClassMethod> eventHandlerMethods = [];
  List<o.ClassField> fields = [];
  List<o.ClassGetter> getters = [];
  List<o.Expression> disposables = [];
  List<o.Expression> subscriptions = [];
  CompileView componentView;
  var pipes = new Map<String, o.Expression>();
  var variables = new Map<String, o.Expression>();
  String className;
  o.Type classType;
  o.ReadVarExpr viewFactory;
  var literalArrayCount = 0;
  var literalMapCount = 0;
  CompileView(this.component, this.genConfig, this.pipeMetas, this.styles,
      this.viewIndex, this.declarationElement, this.templateVariableBindings) {
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
    this.className = '''_View_${ component . type . name}${ viewIndex}''';
    this.classType =
        o.importType(new CompileIdentifierMetadata(name: this.className));
    this.viewFactory = o.variable(getViewFactoryName(component, viewIndex));
    if (identical(this.viewType, ViewType.COMPONENT) ||
        identical(this.viewType, ViewType.HOST)) {
      this.componentView = this;
    } else {
      this.componentView = this.declarationElement.view.componentView;
    }
    var viewQueries = new CompileTokenMap<List<CompileQuery>>();
    if (identical(this.viewType, ViewType.COMPONENT)) {
      var directiveInstance = o.THIS_EXPR.prop("context");
      ListWrapper.forEachWithIndex(this.component.viewQueries,
          (queryMeta, queryIndex) {
        var propName =
            '''_viewQuery_${ queryMeta . selectors [ 0 ] . name}_${ queryIndex}''';
        var queryList =
            createQueryList(queryMeta, directiveInstance, propName, this);
        var query =
            new CompileQuery(queryMeta, queryList, directiveInstance, this);
        addQueryToTokenMap(viewQueries, query);
      });
      var constructorViewQueryCount = 0;
      this.component.type.diDeps.forEach((dep) {
        if (isPresent(dep.viewQuery)) {
          var queryList = o.THIS_EXPR
              .prop("declarationAppElement")
              .prop("componentConstructorViewQueries")
              .key(o.literal(constructorViewQueryCount++));
          var query = new CompileQuery(dep.viewQuery, queryList, null, this);
          addQueryToTokenMap(viewQueries, query);
        }
      });
    }
    this.viewQueries = viewQueries;
    templateVariableBindings.forEach((entry) {
      this.variables[entry[1]] =
          o.THIS_EXPR.prop("locals").key(o.literal(entry[0]));
    });
    if (!this.declarationElement.isNull()) {
      this.declarationElement.setEmbeddedView(this);
    }
  }
  o.Expression createPipe(String name) {
    CompilePipeMetadata pipeMeta = null;
    for (var i = this.pipeMetas.length - 1; i >= 0; i--) {
      var localPipeMeta = this.pipeMetas[i];
      if (localPipeMeta.name == name) {
        pipeMeta = localPipeMeta;
        break;
      }
    }
    if (isBlank(pipeMeta)) {
      throw new BaseException(
          '''Illegal state: Could not find pipe ${ name} although the parser should have detected this error!''');
    }
    var pipeFieldName = pipeMeta.pure
        ? '''_pipe_${ name}'''
        : '''_pipe_${ name}_${ this . pipes . length}''';
    var pipeExpr = this.pipes[pipeFieldName];
    if (isBlank(pipeExpr)) {
      var deps = pipeMeta.type.diDeps.map((diDep) {
        if (diDep.token
            .equalsTo(identifierToken(Identifiers.ChangeDetectorRef))) {
          return o.THIS_EXPR.prop("ref");
        }
        return injectFromViewParentInjector(diDep.token, false);
      }).toList();
      this.fields.add(new o.ClassField(pipeFieldName,
          o.importType(pipeMeta.type), [o.StmtModifier.Private]));
      this.createMethod.resetDebugInfo(null, null);
      this.createMethod.addStmt(o.THIS_EXPR
          .prop(pipeFieldName)
          .set(o.importExpr(pipeMeta.type).instantiate(deps))
          .toStmt());
      pipeExpr = o.THIS_EXPR.prop(pipeFieldName);
      this.pipes[pipeFieldName] = pipeExpr;
      bindPipeDestroyLifecycleCallbacks(pipeMeta, pipeExpr, this);
    }
    return pipeExpr;
  }

  o.Expression getVariable(String name) {
    if (name == EventHandlerVars.event.name) {
      return EventHandlerVars.event;
    }
    CompileView currView = this;
    var result = currView.variables[name];
    var viewPath = [];
    while (isBlank(result) && isPresent(currView.declarationElement.view)) {
      currView = currView.declarationElement.view;
      result = currView.variables[name];
      viewPath.add(currView);
    }
    if (isPresent(result)) {
      return getPropertyInView(result, viewPath);
    } else {
      return null;
    }
  }

  o.Expression createLiteralArray(List<o.Expression> values) {
    return o.THIS_EXPR.callMethod("literalArray",
        [o.literal(this.literalArrayCount++), o.literalArr(values)]);
  }

  o.Expression createLiteralMap(
      List<List<dynamic /* String | o . Expression */ >> values) {
    return o.THIS_EXPR.callMethod("literalMap",
        [o.literal(this.literalMapCount++), o.literalMap(values)]);
  }

  afterNodes() {
    this.viewQueries.values().forEach((queries) => queries.forEach((query) =>
        query.afterChildren(this.createMethod, this.updateViewQueriesMethod)));
  }
}

ViewType getViewType(
    CompileDirectiveMetadata component, num embeddedTemplateIndex) {
  if (embeddedTemplateIndex > 0) {
    return ViewType.EMBEDDED;
  } else if (component.type.isHost) {
    return ViewType.HOST;
  } else {
    return ViewType.COMPONENT;
  }
}
