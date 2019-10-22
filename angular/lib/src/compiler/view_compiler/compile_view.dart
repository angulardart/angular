import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/core/linker/view_type.dart' show ViewType;
import "package:angular/src/core/metadata/view.dart" show ViewEncapsulation;
import 'package:angular/src/source_gen/common/url_resolver.dart'
    show toTemplateExtension;
import 'package:angular_compiler/cli.dart';

import '../compile_metadata.dart'
    show
        CompileDirectiveMetadata,
        CompileIdentifierMetadata,
        CompilePipeMetadata,
        CompileQueryMetadata,
        CompileTokenMap,
        CompileTypeMetadata,
        CompileTypedMetadata;
import '../compiler_utils.dart';
import '../i18n/message.dart';
import '../identifiers.dart';
import '../output/output_ast.dart' as o;
import '../template_ast.dart'
    show
        ElementAst,
        EmbeddedTemplateAst,
        ProviderAst,
        ProviderAstType,
        ReferenceAst,
        TemplateAst,
        VariableAst;
import 'compile_element.dart' show CompileElement, CompileNode;
import 'compile_method.dart' show CompileMethod;
import 'compile_pipe.dart' show CompilePipe;
import 'compile_query.dart' show CompileQuery, addQueryToTokenMap;
import 'constants.dart'
    show
        DetectChangesVars,
        EventHandlerVars,
        ViewProperties,
        InjectMethodVars,
        componentViewRootElementFieldName,
        hostViewComponentFieldName,
        parentRenderNodeVar;
import 'expression_converter.dart';
import 'ir/provider_resolver.dart';
import 'ir/view_storage.dart';
import 'provider_forest.dart' show ProviderForest;
import 'update_statement_visitor.dart' show bindingToUpdateStatement;
import 'view_compiler_utils.dart'
    show
        debugInjectorEnter,
        debugInjectorLeave,
        getViewFactory,
        getViewFactoryName,
        injectFromViewParentInjector,
        maybeCachedCtxDeclarationStatement;
import 'view_name_resolver.dart';

/// Visibility of NodeReference within AppView implementation.
enum NodeReferenceVisibility {
  classPublic, // Visible across build and change detectors or other closures.
  build, // Only visible inside DOM build process.
}

final notThrowOnChanges = o.not(o.importExpr(Runtime.debugThrowIfChanged));

/// A reference to an HTML, Text, or View node created during `AppView.build()`.
class NodeReference {
  final CompileViewStorage _storage;
  final o.Expression _initialValue;
  final o.OutputType _type;
  final String _name;

  NodeReferenceVisibility _visibility = NodeReferenceVisibility.build;

  /// Create a [NodeReference] with a defined [o.OutputType].
  ///
  /// In practice, this is used for `ElementRef`, and nothing else.
  NodeReference(
    this._storage,
    this._type,
    int nodeIndex,
  )   : _name = '_el_$nodeIndex',
        _initialValue = null;

  /// Create a [NodeReference] for an HTML fragment (for i18n).
  NodeReference.html(
    this._storage,
    int nodeIndex,
  )   : _type = o.importType(Identifiers.HTML_DOCUMENT_FRAGMENT),
        _name = '_html_$nodeIndex',
        _initialValue = null;

  /// Create a [NodeReference] for a `Text` node.
  NodeReference.textNode(
    this._storage,
    int nodeIndex, {
    o.Expression initialValue,
  })  : _type = o.importType(Identifiers.HTML_TEXT_NODE),
        _name = '_text_$nodeIndex',
        _initialValue = initialValue;

  /// Create a [NodeReference] for a `TextBinding` node.
  NodeReference._textBindingNode(this._storage, int nodeIndex)
      : _type = o.importType(Interpolation.textBinding),
        _name = '_textBinding_$nodeIndex',
        _initialValue = o.importExpr(Interpolation.textBinding).callFn([]);

  /// Create a [NodeReference] for an anchor node for view containers.
  NodeReference.anchor(
    this._storage,
    int nodeIndex, [
    this._visibility = NodeReferenceVisibility.build,
  ])  : _type = o.importType(Identifiers.HTML_COMMENT_NODE),
        _name = '_anchor_$nodeIndex',
        _initialValue = null;

  /// Create a [NodeReference] for the root element of a view.
  NodeReference.rootElement()
      : _storage = null,
        _type = o.importType(Identifiers.HTML_ELEMENT),
        _name = componentViewRootElementFieldName,
        _visibility = NodeReferenceVisibility.classPublic,
        _initialValue = null;

  /// Create a [NodeReference] for a node passed as a parameter.
  factory NodeReference.parameter(
          CompileViewStorage _storage, o.OutputType type, String name) =
      _ParameterNodeReference;

  NodeReference._parameter(this._storage, this._type, this._name)
      : _initialValue = null;

  NodeReference._subscription(this._name)
      : _storage = null,
        _type = null,
        _initialValue = null;

  /// Returns an expression that reads from this variable or field.
  o.Expression toReadExpr() => ReadNodeReferenceExpr(this);

  /// Returns an expression that writes [value] to this variable or field.
  o.Statement toWriteStmt(o.Expression value) =>
      WriteNodeReferenceStmt(this, value);

  /// If accessed outside of `build()`, makes a variable into a class field.
  void promoteToClassMember() {
    if (_visibility != NodeReferenceVisibility.classPublic) {
      _visibility = NodeReferenceVisibility.classPublic;
      _storage.allocate(
        this._name,
        outputType: _type,
        // All of our NodeReferences are shallowly immutable, that is, they are
        // initialized lazily, but the instance does not change after that. If
        // we have an initialValue (for example "Text('')"), it is effectively
        // final.
        modifiers: _initialValue != null ? const [o.StmtModifier.Final] : null,
        initializer: _initialValue,
      );
    }
  }
}

/// A [NodeReference] for a node that is passed into detectChanges() as a
/// parameter.
///
/// This is used in DirectiveChangeDetector.
class _ParameterNodeReference extends NodeReference {
  _ParameterNodeReference(
      CompileViewStorage storage, o.OutputType type, String name)
      : super._parameter(storage, type, name);

  @override
  o.Expression toReadExpr() => o.ReadVarExpr(_name);
  @override
  o.Statement toWriteStmt(o.Expression value) =>
      o.WriteClassMemberExpr(_name, value).toStmt();
}

// Wraps references to HTML Text nodes in a [TextBinding] helper class.
class TextBindingNodeReference extends NodeReference {
  TextBindingNodeReference(CompileViewStorage storage, int nodeIndex)
      : super._textBindingNode(storage, nodeIndex);

  @override
  o.Expression toReadExpr() => ReadNodeReferenceExpr(this).prop('element');
  o.Expression updateExpr(o.Expression newValueExpr) =>
      ReadNodeReferenceExpr(this).callMethod('updateText', [newValueExpr]);
}

/// An AST expression that reads the value of a NodeReference.
///
/// When visited it behaves as a ReadVarExpr or ReadClassMemberExpr depending on
/// the visibility of the NodeReference.
class ReadNodeReferenceExpr extends o.ReadVarExpr {
  final NodeReference node;

  ReadNodeReferenceExpr(this.node) : super(node._name, null);

  @override
  R visitExpression<R, C>(o.ExpressionVisitor<R, C> visitor, C context) {
    return node._visibility == NodeReferenceVisibility.classPublic
        ? o.ReadClassMemberExpr(name, type).visitExpression(visitor, context)
        : visitor.visitReadVarExpr(this, context);
  }
}

/// An AST statement that writes the value of a NodeReference.
///
/// When visited it behaves as a DeclareVarStmt or WriteClassMemberStmt
/// depending on the visibility of the NodeReference.
class WriteNodeReferenceStmt extends o.DeclareVarStmt {
  final NodeReference node;

  WriteNodeReferenceStmt(this.node, o.Expression value)
      : super(node._name, value, null, const [o.StmtModifier.Final]);

  @override
  R visitStatement<R, C>(o.StatementVisitor<R, C> visitor, C context) {
    return node._visibility == NodeReferenceVisibility.classPublic
        ? o.WriteClassMemberExpr(name, value)
            .toStmt()
            .visitStatement(visitor, context)
        : visitor.visitDeclareVarStmt(this, context);
  }

  @override
  WriteNodeReferenceStmt withValue(o.Expression replacement) {
    return WriteNodeReferenceStmt(node, replacement);
  }
}

/// AST visitor which promotes inaccessible NodeReferences to class members.
class NodeReferenceStorageVisitor extends o.RecursiveExpressionVisitor<void> {
  final NodeReferenceStorageVisitor parent;
  final scope = <NodeReference>{};

  NodeReferenceStorageVisitor(this.parent);

  @override
  o.Expression visitReadVarExpr(o.ReadVarExpr ast, _) {
    if (ast is ReadNodeReferenceExpr) {
      NodeReference node = ast.node;
      NodeReferenceStorageVisitor visitor = this;
      while (visitor != null && !visitor.scope.contains(node)) {
        visitor = visitor.parent;
      }
      if (visitor == null) node.promoteToClassMember();
    }
    return ast;
  }

  @override
  o.Expression visitFunctionExpr(o.FunctionExpr ast, _) {
    visitScopedStatements(ast.statements, this);
    return ast;
  }

  @override
  o.Statement visitDeclareVarStmt(o.DeclareVarStmt stmt, _) {
    stmt.value?.visitExpression(this, null);
    if (stmt is WriteNodeReferenceStmt) scope.add(stmt.node);
    return stmt;
  }

  @override
  o.Statement visitDeclareFunctionStmt(o.DeclareFunctionStmt stmt, _) {
    visitScopedStatements(stmt.statements, this);
    return stmt;
  }

  @override
  o.Statement visitIfStmt(o.IfStmt stmt, _) {
    stmt.condition.visitExpression(this, null);
    visitScopedStatements(stmt.trueCase, this);
    visitScopedStatements(stmt.falseCase, this);
    return stmt;
  }

  @override
  o.Statement visitTryCatchStmt(o.TryCatchStmt stmt, _) {
    visitScopedStatements(stmt.bodyStmts, this);
    visitScopedStatements(stmt.catchStmts, this);
    return stmt;
  }

  static void visitScopedStatements(List<o.Statement> stmts,
      [NodeReferenceStorageVisitor parent]) {
    final visitor = NodeReferenceStorageVisitor(parent);
    for (var stmt in stmts) {
      stmt.visitStatement(visitor, null);
    }
  }
}

/// Reference to html node created during AppView build.
class AppViewReference {
  final CompileElement parent;
  final int nodeIndex;
  final String _name;

  AppViewReference(this.parent, this.nodeIndex)
      : _name = '_compView_$nodeIndex';

  o.ReadClassMemberExpr toReadExpr() {
    return o.ReadClassMemberExpr(_name);
  }

  o.Statement toWriteStmt(o.Expression value) {
    return o.WriteClassMemberExpr(_name, value).toStmt();
  }

  void allocate(CompileViewStorage storage,
      {o.OutputType outputType, List<o.StmtModifier> modifiers}) {
    storage.allocate(_name, outputType: outputType, modifiers: modifiers);
  }
}

/// Represents data to generate a host, component or embedded AppView.
///
/// Members and method builders are populated by ViewBuilder.
class CompileView {
  final CompileDirectiveMetadata component;
  final CompilerFlags genConfig;
  final List<CompilePipeMetadata> pipeMetas;
  final o.Expression styles;
  final Map<String, String> deferredModules;

  /// Defines type arguments for generic directives in this view.
  final List<CompileTypedMetadata> directiveTypes;

  /// Internationalized messages declared in this view.
  ///
  /// Message expressions are keyed by their metadata and contents, so that any
  /// duplicate messages will use the same generated message.
  final _i18nMessages = <I18nMessage, o.Expression>{};

  /// A representation of this view's dependency injection hierarchy.
  ///
  /// When assigned, this field is used to generate the `injectorGetInternal()`
  /// method.
  ProviderForest providers;

  int viewIndex;
  CompileElement declarationElement;
  List<VariableAst> templateVariables;
  ViewType viewType;
  CompileTokenMap<List<CompileQuery>> viewQueries;
  CompileViewStorage storage;

  /// Contains references to view children so we can generate code for
  /// change detection and destroy.
  final List<CompileElement> _viewChildren = [];

  /// Flat list of all nodes inside the template including text nodes.
  List<CompileNode> nodes = [];

  /// List of references to top level nodes in view.
  List<o.Expression> rootNodesOrViewContainers = [];

  /// List of references to view containers used by embedded templates
  /// and child components.
  List<o.Expression> viewContainers = [];
  List<o.Statement> classStatements = [];

  final _createMethod = CompileMethod();
  final _updateContentQueriesMethod = CompileMethod();
  final _updateViewQueriesMethod = CompileMethod();
  final dirtyParentQueriesMethod = CompileMethod();
  final detectChangesInInputsMethod = CompileMethod();
  final detectChangesRenderPropertiesMethod = CompileMethod();
  CompileMethod detectHostChangesMethod;
  final afterContentLifecycleCallbacksMethod = CompileMethod();
  final afterViewLifecycleCallbacksMethod = CompileMethod();
  final destroyMethod = CompileMethod();

  /// Methods generated during view compilation.
  ///
  /// These include event handlers with non-standard parameters or multiple
  /// actions, and internationalized messages with arguments.
  List<o.ClassMethod> methods = [];
  List<o.ClassGetter> getters = [];
  List<o.Expression> subscriptions = [];
  bool subscribesToMockLike = false;
  CompileView componentView;
  var purePipes = Map<String, CompilePipe>();
  List<CompilePipe> pipes = [];
  String className;
  o.OutputType classType;
  o.Expression viewFactory;
  String viewFactoryName;
  var pipeCount = 0;
  ViewNameResolver nameResolver;
  static final defaultDocVarName = 'doc';

  /// Local variable name used to refer to document. null if not created yet.
  String docVarName;

  CompileView(
    this.component,
    this.genConfig,
    this.directiveTypes,
    this.pipeMetas,
    this.styles,
    this.viewIndex,
    this.declarationElement,
    this.templateVariables,
    this.deferredModules,
  ) {
    nameResolver = ViewNameResolver(this);
    storage = CompileViewStorage();
    viewType = _getViewType(component, viewIndex);
    className = '${viewIndex == 0 && viewType != ViewType.host ? '' : '_'}'
        'View${component.type.name}$viewIndex';
    classType = o.importType(CompileIdentifierMetadata(name: className));
    viewFactoryName = getViewFactoryName(component, viewIndex);
    viewFactory = getViewFactory(component, viewFactoryName);
    switch (viewType) {
      case ViewType.host:
      case ViewType.component:
        componentView = this;
        break;
      default:
        // An embedded template uses it's declaration element's componentView.
        componentView = declarationElement.view.componentView;
        break;
    }
    viewQueries = CompileTokenMap<List<CompileQuery>>();
    if (viewType == ViewType.component) {
      var directiveInstance = BuiltInSource(
          identifierToken(this.component.type), DetectChangesVars.cachedCtx);
      var queryIndex = -1;
      for (CompileQueryMetadata metadata in component.viewQueries) {
        queryIndex++;
        final query = CompileQuery.viewQuery(
          metadata: metadata,
          storage: storage,
          queryRoot: this,
          boundDirective: directiveInstance,
          queryIndex: queryIndex,
        );
        addQueryToTokenMap(viewQueries, query);
      }
    }

    for (var variable in templateVariables) {
      nameResolver.addLocal(
        variable.name,
        o.ReadClassMemberExpr('locals').key(o.literal(variable.value)),
        variable.type, // NgFor locals are augmented with type information.
      );
    }
    if (declarationElement.parent != null) {
      declarationElement.setEmbeddedView(this);
    }
    if (deferredModules == null) {
      throw ArgumentError();
    }
  }

  // Adds reference to a child view.
  void addViewChild(CompileElement viewChild) {
    _viewChildren.add(viewChild);
  }

  // Returns list of references to view children.
  List<CompileElement> get viewChildren => _viewChildren;

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

  /// Generates code to internationalize [message].
  ///
  /// Returns an expression that evaluates to the internationalized message. May
  /// reuse an existing generated expression if a duplicate [message] has
  /// already been created.
  o.Expression createI18nMessage(I18nMessage message) {
    if (_i18nMessages.containsKey(message)) {
      return _i18nMessages[message];
    }
    final args = [
      _textExpression(message),
      o.NamedExpr('desc', o.literal(message.metadata.description)),
      if (message.metadata.locale != null)
        o.NamedExpr('locale', o.literal(message.metadata.locale)),
      if (message.metadata.meaning != null)
        o.NamedExpr('meaning', o.literal(message.metadata.meaning)),
      if (message.metadata.skip) o.NamedExpr('skip', o.literal(true)),
    ];
    final i18n = o.importExpr(Identifiers.Intl);
    final name = '_message_${_i18nMessages.length}';
    o.Expression messageExpression;
    if (message.containsHtml) {
      // A message with arguments is generated as a static method.
      // These are passed to `args` in `Intl.message()`.
      final messageArgs = <o.ReadVarExpr>[];
      // These are passed to `examples` in `Intl.message()`.
      final messageExamples = <List<dynamic>>[];
      final messageExamplesType = o.MapType(null, [o.TypeModifier.Const]);
      // These are the arguments used to invoke the generated method.
      final methodArgs = <o.LiteralExpr>[];
      // These are the parameters of the generated method.
      final methodParameters = <o.FnParam>[];
      for (final parameter in message.args.keys) {
        final argument = o.literal(message.args[parameter]);
        messageArgs.add(o.variable(parameter));
        messageExamples.add([parameter, argument]);
        methodArgs.add(argument);
        methodParameters.add(o.FnParam(parameter, o.STRING_TYPE));
      }
      args
        ..add(o.NamedExpr('name', o.literal('${className}_$name')))
        ..add(o.NamedExpr('args', o.literalArr(messageArgs)))
        ..add(o.NamedExpr(
          'examples',
          o.literalMap(messageExamples, messageExamplesType),
        ));
      final value = i18n.callMethod('message', args);
      final method = o.ClassMethod(
        name,
        methodParameters,
        [o.ReturnStatement(value)],
        o.STRING_TYPE,
        [o.StmtModifier.Static, o.StmtModifier.Private],
      );
      methods.add(method);
      // A hack to invoke a static class method.
      messageExpression = o.InvokeFunctionExpr(
        o.ReadStaticMemberExpr(name),
        methodArgs,
        [],
        type: o.STRING_TYPE,
      );
    } else {
      // A message with no arguments is generated as a static final field.
      final value = i18n.callMethod('message', args);
      final item = storage.allocate(
        name,
        outputType: o.STRING_TYPE,
        initializer: value,
        modifiers: const [
          o.StmtModifier.Static,
          o.StmtModifier.Final,
          o.StmtModifier.Private,
        ],
      );
      messageExpression = storage.buildReadExpr(item);
    }
    return _i18nMessages[message] = messageExpression;
  }

  NodeReference createHtml(
    ir.BindingSource html,
    CompileElement parent,
    int nodeIndex,
  ) {
    final renderNode = NodeReference.html(storage, nodeIndex);
    _initializeAndAppendNode(parent, renderNode,
        o.importExpr(Identifiers.createTrustedHtml).callFn([_textValue(html)]));
    return renderNode;
  }

  NodeReference createTextBinding(
    ir.BindingSource text,
    CompileElement parent,
    int nodeIndex,
  ) {
    final renderNode = _textNode(text, nodeIndex);
    final parentNode = _getParentRenderNode(parent);
    final isImmutable = text.isImmutable;
    if (parentNode != o.NULL_EXPR) {
      if (isImmutable) {
        // We do not create a class-level member, effectively "one-time".
        //
        // class V {
        //   build() {
        //     _el_0 = ...;
        //     appendText(_el_0, '...');
        //   }
        // }
        final appendText = o.importExpr(DomHelpers.appendText).callFn([
          parentNode,
          _textValue(text),
        ]);
        _createMethod.addStmt(renderNode.toWriteStmt(appendText));
      } else {
        // A class-level member is created in a previous phase, and all we need
        // to do is append it to its parent (and detectChanges will handle
        // updating it).
        //
        // class V {
        //   final _text_0 = Text('');
        //
        //   build() {
        //     _el_0 = ...;
        //     _el_0.append(_text_0);
        //   }
        // }
        _createMethod.addStmt(
          parentNode.callMethod('append', [renderNode.toReadExpr()]).toStmt(),
        );
      }
    } else if (isImmutable) {
      // Text is being appended or otherwise used somewhere else in the build
      // (it does not start attached). This is similar to the "isImmutable"
      // case above, but does not append the text.
      //
      // class V {
      //   build() {
      //     _text_0 = createText('...')
      //   }
      // }
      final createText = o.importExpr(DomHelpers.createText).callFn([
        _textValue(text),
      ]);
      _createMethod.addStmt(renderNode.toWriteStmt(createText));
    } else {
      // A mutable string without being appended to anything.
      //
      // class V {
      //   final _text_0 = Text('');
      // }
      //
      // For example, text nodes that are attached to the root node use the
      // initN(...) function to append themselves, and not ".append". We may
      // be able to refactor this case in the future.
    }
    return renderNode;
  }

  NodeReference _textNode(ir.BindingSource source, int nodeIndex) {
    if (source.isImmutable) {
      return NodeReference.textNode(storage, nodeIndex);
    } else {
      return TextBindingNodeReference(storage, nodeIndex);
    }
  }

  /// Returns an expression for the text content of [message].
  o.Expression _textExpression(I18nMessage message) {
    if (message.containsHtml) {
      // If the message contains HTML, it will be parsed into a document
      // fragment. To prevent any manually escaped '<' and '>' characters (that
      // were decoded during template parsing) from being interpreted as HTML
      // tags, we must escape them again.
      final htmlEscape = const HtmlEscape(HtmlEscapeMode.element);
      final text = htmlEscape.convert(message.text);
      // Messages that contain HTML are escaped manually during construction
      // to preserve the interpolations used to render the HTML tags.
      return o.escapedString(text);
    }
    // Normal messages are escaped during code generation like any other literal
    // text.
    return o.literal(message.text);
  }

  o.Expression _textValue(ir.BindingSource source) =>
      _toExpression(source, DetectChangesVars.cachedCtx);

  o.Expression _toExpression(
      ir.BindingSource source, o.Expression implicitReceiver) {
    if (source is ir.StringLiteral) {
      return o.literal(source.value);
    } else if (source is ir.BoundI18nMessage) {
      return createI18nMessage(source.value);
    } else if (source is ir.BoundExpression) {
      return convertCdExpressionToIr(
        nameResolver,
        implicitReceiver,
        source.expression.ast,
        source.sourceSpan,
        component,
        boundType: o.STRING_TYPE,
      );
    } else {
      throw ArgumentError.value(source, 'source', 'Unsupported source type');
    }
  }

  int _eventHandlerCount = 0;

  // TODO(alorenzen): Convert to NodeReference.
  o.Expression createEventHandler(List<o.Statement> stmts,
      {List<o.Statement> localDeclarations = const []}) {
    var methodName = '_handleEvent_${_eventHandlerCount++}';
    methods.add(_createEventHandlerMethod(
      methodName,
      stmts,
      localDeclarations,
    ));
    return o.ReadClassMemberExpr(methodName);
  }

  o.ClassMethod _createEventHandlerMethod(String methodName,
          List<o.Statement> stmts, List<o.Statement> localDeclarations) =>
      o.ClassMethod(
          methodName,
          [_eventParam],
          [
            ...localDeclarations,
            ...maybeCachedCtxDeclarationStatement(statements: stmts),
            ...stmts,
          ],
          null,
          [o.StmtModifier.Private]);

  final _eventParam = o.FnParam(
    EventHandlerVars.event.name,
    o.importType(null),
  );

  /// Create an html node and appends to parent element.
  void createElement(CompileElement parent, NodeReference elementRef,
      int nodeIndex, String tagName, TemplateAst ast) {
    var parentRenderNodeExpr = _getParentRenderNode(parent);

    _createElementAndAppend(
      tagName,
      parentRenderNodeExpr,
      elementRef,
    );
  }

  void _createElementAndAppend(
    String tagName,
    o.Expression parent,
    NodeReference elementRef,
  ) {
    // No namespace just call [document.createElement].
    if (docVarName == null) {
      _createMethod.addStmt(_createLocalDocumentVar());
    }
    if (parent != null && parent != o.NULL_EXPR) {
      o.Expression createExpr;
      final createParams = <o.Expression>[o.ReadVarExpr(docVarName), parent];

      CompileIdentifierMetadata createAndAppendMethod;
      switch (tagName) {
        case 'div':
          createAndAppendMethod = DomHelpers.appendDiv;
          break;
        case 'span':
          createAndAppendMethod = DomHelpers.appendSpan;
          break;
        default:
          createAndAppendMethod = DomHelpers.appendElement;
          createParams.add(o.literal(tagName));
          break;
      }
      createExpr = o.importExpr(createAndAppendMethod).callFn(createParams);
      _createMethod.addStmt(elementRef.toWriteStmt(createExpr));
    } else {
      // No parent node, just create element and assign.
      final createRenderNodeExpr = o.ReadVarExpr(docVarName).callMethod(
        'createElement',
        [o.literal(tagName)],
      );
      _createMethod.addStmt(elementRef.toWriteStmt(createRenderNodeExpr));
    }
  }

  o.Statement _createLocalDocumentVar() {
    docVarName = defaultDocVarName;
    return o.DeclareVarStmt(
      docVarName,
      o.importExpr(Identifiers.HTML_DOCUMENT),
      null,
      const [o.StmtModifier.Final],
    );
  }

  /// Creates an html node with a namespace and appends to parent element.
  void createElementNs(CompileElement parent, NodeReference elementRef,
      int nodeIndex, String ns, String tagName, TemplateAst ast) {
    if (docVarName == null) {
      _createMethod.addStmt(_createLocalDocumentVar());
    }
    var createRenderNodeExpr = o
        .variable(docVarName)
        .callMethod('createElementNS', [o.literal(ns), o.literal(tagName)]);
    _initializeAndAppendNode(parent, elementRef, createRenderNodeExpr);
  }

  /// Initializes a component view for [childComponent].
  ///
  /// This will allocate a field member for the component view if necessary.
  ///
  /// Returns an expression that references the initialized component view.
  o.Expression _createAppViewNodeAndComponent(
      CompileElement parent,
      CompileDirectiveMetadata childComponent,
      NodeReference elementRef,
      int nodeIndex,
      bool isDeferred,
      ElementAst ast) {
    CompileIdentifierMetadata componentViewIdentifier =
        CompileIdentifierMetadata(
            name: 'View${childComponent.type.name}0',
            moduleUrl: templateModuleUrl(childComponent.type));

    // For non-deferred generic components, these type arguments (if any) can
    // be applied to the field that stores the view. However, for deferred
    // components, the field can't be explicitly typed so these type arguments
    // are instead applied to the constructor invocation.
    final componentTypeArguments =
        lookupTypeArgumentsOf(childComponent.type, ast);

    o.ReadClassMemberExpr componentViewExpr;
    if (viewType == ViewType.host) {
      // Unlike other view types, host views always have exactly component view,
      // for which they already have a dedicated field named `componentView`.
      componentViewExpr = o.ReadClassMemberExpr('componentView');
    } else {
      final appViewRef = AppViewReference(parent, nodeIndex);

      // If the component is deferred, we can't type the field which stores it.
      final componentViewType = isDeferred
          ? o.importType(Views.componentView)
          : o.importType(componentViewIdentifier, componentTypeArguments);

      // Create the field which stores the component view:
      //
      //   ViewSomeComponent0 _compView_0;
      //
      appViewRef.allocate(storage, outputType: componentViewType);
      componentViewExpr = appViewRef.toReadExpr();
    }

    // If the component is deferred, its type arguments can't be inferred from
    // the field to which it's assigned.
    final constructorTypeArguments = isDeferred ? componentTypeArguments : null;

    // Instantiate the component view:
    //
    //   _compView_0 = ViewSomeComponent0(this, 0);
    //
    final createComponentInstanceExpr = o
        .importExpr(componentViewIdentifier)
        .instantiate([o.THIS_EXPR, o.literal(nodeIndex)],
            genericTypes: constructorTypeArguments);

    _createMethod.addStmt(o.CommentStmt(
      'Child component ${childComponent.toPrettyString()}',
    ));

    _createMethod
        .addStmt(componentViewExpr.set(createComponentInstanceExpr).toStmt());
    return componentViewExpr;
  }

  /// Creates a node 'anchor' to mark the insertion point for dynamically
  /// created elements.
  NodeReference createViewContainerAnchor(
    CompileElement parent,
    int nodeIndex,
    TemplateAst ast,
  ) {
    final renderNode = NodeReference.anchor(storage, nodeIndex);
    final parentNode = _getParentRenderNode(parent);
    if (parentNode != o.NULL_EXPR) {
      final appendAnchor = o.importExpr(DomHelpers.appendAnchor).callFn([
        parentNode,
      ]);
      _createMethod.addStmt(renderNode.toWriteStmt(appendAnchor));
    } else {
      final createAnchor = o.importExpr(DomHelpers.createAnchor).callFn([]);
      _createMethod.addStmt(renderNode.toWriteStmt(createAnchor));
    }
    return renderNode;
  }

  o.ReadClassMemberExpr createViewContainer(
      NodeReference nodeReference, int nodeIndex, bool isPrivate,
      [int parentNodeIndex]) {
    o.Expression renderNode = nodeReference.toReadExpr();
    var fieldName = '_appEl_$nodeIndex';
    // Create instance field for app element.
    storage.allocate(fieldName,
        outputType: o.importType(Identifiers.ViewContainer),
        modifiers: [o.StmtModifier.Private]);

    // Write code to create an instance of ViewContainer.
    // Example:
    //     this._appEl_2 = new import7.ViewContainer(2,0,this,this._anchor_2);
    var statement = o.WriteClassMemberExpr(
        fieldName,
        o.importExpr(Identifiers.ViewContainer).instantiate([
          o.literal(nodeIndex),
          o.literal(parentNodeIndex),
          o.THIS_EXPR,
          renderNode
        ])).toStmt();
    _createMethod.addStmt(statement);
    var appViewContainer = o.ReadClassMemberExpr(fieldName);
    if (!isPrivate) {
      viewContainers.add(appViewContainer);
    }
    return appViewContainer;
  }

  o.Expression createComponentNodeAndAppend(
      CompileDirectiveMetadata component,
      CompileElement parent,
      NodeReference elementRef,
      int nodeIndex,
      ElementAst ast,
      {bool isDeferred}) {
    final componentViewExpr = _createAppViewNodeAndComponent(
        parent, component, elementRef, nodeIndex, isDeferred, ast);

    final root = componentViewExpr.prop(componentViewRootElementFieldName);
    if (isRootNodeOfHost(nodeIndex)) {
      // Assign the root element of the component view to a local variable. The
      // host view will use this as its root node, or the host element of a root
      // view container.
      _createMethod.addStmt(elementRef.toWriteStmt(root));
    } else {
      _initializeAndAppendNode(parent, elementRef, root);
    }
    return componentViewExpr;
  }

  void createComponentView(
    o.Expression componentViewExpr,
    o.Expression componentExpr,
    o.Expression projectedNodes,
  ) {
    final createExpr =
        projectedNodes is o.LiteralArrayExpr && projectedNodes.entries.isEmpty
            ? componentViewExpr.callMethod('create', [componentExpr])
            : componentViewExpr.callMethod('createAndProject', [
                componentExpr,
                projectedNodes,
              ]);
    _createMethod.addStmt(createExpr.toStmt());
  }

  bool isRootNodeOfHost(int nodeIndex) =>
      nodeIndex == 0 && viewType == ViewType.host;

  void projectNodesIntoElement(
      CompileElement target, int sourceAstIndex, int ngContentIndex) {
    // The projected nodes originate from a different view, so we don't
    // have debug information for them.
    var parentRenderNode = _getParentRenderNode(target);
    // AppView.projectableNodes property contains the list of nodes
    // to project for each NgContent.
    // Creates a call to project(parentNode, nodeIndex).
    var nodesExpression = ViewProperties.projectedNodes.key(
        o.literal(sourceAstIndex),
        o.ArrayType(o.importType(Identifiers.HTML_NODE)));
    bool isRootNode = !identical(target.view, this);
    if (!identical(parentRenderNode, o.NULL_EXPR)) {
      _createMethod.addStmt(o.InvokeMemberMethodExpr(
          'project', [parentRenderNode, o.literal(sourceAstIndex)]).toStmt());
    } else if (isRootNode) {
      if (!identical(viewType, ViewType.component)) {
        // store root nodes only for embedded/host views
        rootNodesOrViewContainers.add(nodesExpression);
      }
    } else {
      if (target.component != null && ngContentIndex != null) {
        target.addContentNode(ngContentIndex, nodesExpression);
      }
    }
  }

  void shimCssForNode(NodeReference nodeReference, int nodeIndex,
      CompileIdentifierMetadata nodeType) {
    if (isRootNodeOfHost(nodeIndex)) return;
    if (component.template.encapsulation == ViewEncapsulation.Emulated) {
      // Set ng_content class for CSS shim.
      String shimMethod =
          nodeType != Identifiers.HTML_ELEMENT ? 'addShimC' : 'addShimE';
      o.Expression shimClassExpr =
          o.InvokeMemberMethodExpr(shimMethod, [nodeReference.toReadExpr()]);
      _createMethod.addStmt(shimClassExpr.toStmt());
    }
  }

  NodeReference createSubscription({bool isMockLike = false}) {
    final subscription =
        NodeReference._subscription('subscription_${subscriptions.length}');
    subscriptions.add(subscription.toReadExpr());
    if (isMockLike) {
      subscribesToMockLike = true;
    }
    return subscription;
  }

  void addEventListener(
    NodeReference node,
    ir.Binding binding,
    o.Expression handler, [
    o.Expression directiveInstance,
  ]) {
    _createMethod.addStmt(bindingToUpdateStatement(
        binding, directiveInstance, node, false, handler));
  }

  void updateQueryAtStartup(CompileQuery query) {
    _createMethod.addStmts(query.createImmediateUpdates());
  }

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
  o.Expression createProvider(
      String propName,
      CompileDirectiveMetadata directiveMetadata,
      ProviderAst provider,
      List<o.Expression> providerValueExpressions,
      bool isMulti,
      bool isEager,
      CompileElement compileElement,
      {bool forceDynamic = false}) {
    o.Expression resolvedProviderValueExpr;
    o.OutputType type;
    if (isMulti) {
      resolvedProviderValueExpr = o.literalArr(providerValueExpressions);
      type = o.ArrayType(provider.typeArgument != null
          ? o.importType(
              provider.typeArgument,
              provider.typeArgument.typeArguments,
            )
          : o.DYNAMIC_TYPE);
    } else {
      resolvedProviderValueExpr = providerValueExpressions.first;
      if (directiveMetadata != null) {
        // If the provider is backed by a directive, use the directive type
        // alongside any specified type arguments to type the field.
        type = o.importType(
          directiveMetadata.originType,
          lookupTypeArgumentsOf(
            directiveMetadata.originType,
            compileElement.sourceAst,
          ),
        );
      } else if (provider.typeArgument != null) {
        type = o.importType(
          provider.typeArgument,
          provider.typeArgument.typeArguments,
        );
      } else {
        type = resolvedProviderValueExpr.type;
      }
    }

    type ??= o.DYNAMIC_TYPE;

    bool providerHasChangeDetector =
        provider.providerType == ProviderAstType.Directive &&
            directiveMetadata != null &&
            directiveMetadata.requiresDirectiveChangeDetector;

    CompileIdentifierMetadata changeDetectorClass;
    o.OutputType changeDetectorType;
    if (providerHasChangeDetector) {
      changeDetectorClass = CompileIdentifierMetadata(
          name: directiveMetadata.identifier.name + 'NgCd',
          moduleUrl:
              toTemplateExtension(directiveMetadata.identifier.moduleUrl));
      changeDetectorType = o.importType(
        changeDetectorClass,
        lookupTypeArgumentsOf(
          directiveMetadata.originType,
          compileElement.sourceAst,
        ),
      );
    }

    List<o.Expression> changeDetectorParams;
    if (providerHasChangeDetector) {
      changeDetectorParams = [resolvedProviderValueExpr];
    }

    if (isEager) {
      // Check if we need to reach this directive or component beyond the
      // contents of the build() function. Otherwise allocate locally.
      if (provider.isReferencedOutsideBuild) {
        if (providerHasChangeDetector) {
          ViewStorageItem item = storage.allocate(propName,
              outputType: changeDetectorType,
              modifiers: const [o.StmtModifier.Private]);
          _createMethod.addStmt(storage
              .buildWriteExpr(
                  item,
                  o
                      .importExpr(changeDetectorClass)
                      .instantiate(changeDetectorParams))
              .toStmt());
          return o.ReadPropExpr(
              o.ReadClassMemberExpr(propName, changeDetectorType), 'instance',
              outputType: forceDynamic ? o.DYNAMIC_TYPE : type);
        } else {
          if (viewType == ViewType.host &&
              provider.providerType == ProviderAstType.Component) {
            // Host views always have a exactly one component instance, so when
            // the provider type is a component, it must be this instance.
            // There's no need to allocate a new field for this provider, as
            // `HostView` already has a dedicated field for it.
            propName = hostViewComponentFieldName;
            _createMethod.addStmt(o.ReadClassMemberExpr(propName)
                .set(resolvedProviderValueExpr)
                .toStmt());
          } else {
            ViewStorageItem item = storage.allocate(propName,
                outputType: forceDynamic ? o.DYNAMIC_TYPE : type,
                modifiers: const [o.StmtModifier.Private]);
            _createMethod.addStmt(storage
                .buildWriteExpr(item, resolvedProviderValueExpr)
                .toStmt());
          }
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
      var internalFieldName = '_$propName';
      ViewStorageItem internalField = storage.allocate(internalFieldName,
          outputType: forceDynamic
              ? o.DYNAMIC_TYPE
              : (providerHasChangeDetector ? changeDetectorType : type),
          modifiers: const [o.StmtModifier.Private]);
      var getter = CompileMethod();

      if (providerHasChangeDetector) {
        resolvedProviderValueExpr =
            o.importExpr(changeDetectorClass).instantiate(changeDetectorParams);
      }
      // Note: Equals is important for JS so that it also checks the undefined case!
      var statements = <o.Statement>[
        storage
            .buildWriteExpr(internalField, resolvedProviderValueExpr)
            .toStmt()
      ];
      getter.addStmt(
          o.IfStmt(storage.buildReadExpr(internalField).isBlank(), statements));
      getter.addStmt(o.ReturnStatement(storage.buildReadExpr(internalField)));
      getters.add(o.ClassGetter(
          propName,
          getter.finish(),
          forceDynamic
              ? o.DYNAMIC_TYPE
              : (providerHasChangeDetector ? changeDetectorType : type)));
    }
    return o.ReadClassMemberExpr(propName, type);
  }

  void callFunctionalDirective(o.Expression invokeExpression) {
    _createMethod.addStmt(invokeExpression.toStmt());
  }

  void createPipeInstance(String name, CompilePipeMetadata pipeMeta) {
    var usesInjectorGet = false;
    final deps = pipeMeta.type.diDeps.map((diDep) {
      if (diDep.token
          .equalsTo(identifierToken(Identifiers.ChangeDetectorRef))) {
        return o.THIS_EXPR;
      }
      usesInjectorGet = true;
      return injectFromViewParentInjector(this, diDep.token, diDep.isOptional);
    }).toList();
    final pipeInstance = storage.allocate(
      name,
      outputType: o.importType(pipeMeta.type),
      modifiers: [o.StmtModifier.Private],
    );
    final typeExpression = o.importExpr(pipeMeta.type);
    if (usesInjectorGet) {
      _createMethod.addStmt(debugInjectorEnter(typeExpression));
    }
    _createMethod.addStmt(storage
        .buildWriteExpr(
          pipeInstance,
          typeExpression.instantiate(deps),
        )
        .toStmt());
    if (usesInjectorGet) {
      _createMethod.addStmt(debugInjectorLeave(typeExpression));
    }
  }

  void createPureProxy(
    o.Expression fn,
    int argCount,
    o.ReadClassMemberExpr pureProxyProp, {
    o.OutputType pureProxyType,
  }) {
    ViewStorageItem proxy = storage.allocate(
      pureProxyProp.name,
      outputType: pureProxyType,
      modifiers: const [o.StmtModifier.Private],
    );
    var pureProxyId = argCount < Identifiers.pureProxies.length
        ? Identifiers.pureProxies[argCount]
        : null;
    if (pureProxyId == null) {
      throw StateError(
          'Unsupported number of argument for pure functions: $argCount');
    }
    _createMethod.addStmt(storage
        .buildWriteExpr(proxy, o.importExpr(pureProxyId).callFn([fn]))
        .toStmt());
  }

  void writeLiteralAttributeValues(
    String elementName,
    NodeReference nodeReference,
    List<ir.Binding> bindings, {
    @required bool isHtmlElement,
  }) {
    for (var binding in bindings) {
      _createMethod.addStmt(createAttributeStatement(
        binding,
        elementName,
        nodeReference,
        isHtmlElement: isHtmlElement,
      ));
    }
  }

  o.Statement createAttributeStatement(
    ir.Binding binding,
    String elementName,
    NodeReference renderNode, {
    @required bool isHtmlElement,
  }) {
    var expression = _toExpression(binding.source, o.THIS_EXPR);
    o.Statement stmt = bindingToUpdateStatement(
      binding,
      o.THIS_EXPR,
      renderNode,
      isHtmlElement,
      expression,
    );
    return stmt;
  }

  void deferLoadEmbeddedTemplate(
    CompileView deferredView,
    CompileElement targetElement,
  ) {
    final deferredLoadExpr = targetElement.writeDeferredLoader(
      deferredView,
      targetElement.appViewContainer,
    );
    final cancelHandlerName = '_cancelDeferredLoad${targetElement.nodeIndex}';
    storage.allocate(
      cancelHandlerName,
      outputType: o.FunctionType(o.VOID_TYPE, []),
    );
    _createMethod.addStmt(
      o.ReadClassMemberExpr(cancelHandlerName).set(deferredLoadExpr).toStmt(),
    );
    destroyMethod.addStmt(
      o.ReadClassMemberExpr(cancelHandlerName).callFn([]).toStmt(),
    );
  }

  void writeBuildStatements(List<o.Statement> targetStatements) {
    targetStatements.addAll(_createMethod.finish());
  }

  List<o.Statement> writeCheckAlwaysChangeDetectionStatements() {
    final methodName = 'detectChangesInCheckAlwaysViews';
    return [
      // `HostView` already has a specialized implementation of this method.
      if (viewType != ViewType.host) ...[
        for (final viewContainer in viewContainers)
          viewContainer.callMethod(methodName, []).toStmt(),
        for (final viewChild in viewChildren)
          if (viewChild.component.isChangeDetectionLink)
            viewChild.componentView.callMethod(methodName, []).toStmt(),
      ],
    ];
  }

  List<o.Statement> writeChangeDetectionStatements() {
    var statements = <o.Statement>[];
    if (detectChangesInInputsMethod.isEmpty &&
        _updateContentQueriesMethod.isEmpty &&
        afterContentLifecycleCallbacksMethod.isEmpty &&
        detectChangesRenderPropertiesMethod.isEmpty &&
        _updateViewQueriesMethod.isEmpty &&
        afterViewLifecycleCallbacksMethod.isEmpty &&
        // Host views have a default implementation of `detectChangesInternal()`
        // that change detects their only child component view, so the presence
        // of child views is only an indicator for generating change detection
        // statements for component and embedded views.
        (viewType == ViewType.host || viewChildren.isEmpty) &&
        viewContainers.isEmpty) {
      return statements;
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
        List.from(_updateContentQueriesMethod.finish())
          ..addAll(afterContentLifecycleCallbacksMethod.finish());
    if (afterContentStmts.isNotEmpty) {
      statements.add(o.IfStmt(notThrowOnChanges, afterContentStmts));
    }

    // Add render properties change detectors.
    statements.addAll(detectChangesRenderPropertiesMethod.finish());

    // Add view child change detection calls.
    for (var viewChild in viewChildren) {
      statements.add(
          viewChild.componentView.callMethod('detectChanges', []).toStmt());
    }

    List<o.Statement> afterViewStmts =
        List.from(_updateViewQueriesMethod.finish())
          ..addAll(afterViewLifecycleCallbacksMethod.finish());
    if (afterViewStmts.isNotEmpty) {
      statements.add(o.IfStmt(notThrowOnChanges, afterViewStmts));
    }
    var varStmts = <Object>[];
    var readVars = o.findReadVarNames(statements);
    var writeVars = o.findWriteVarNames(statements);
    varStmts.addAll(maybeCachedCtxDeclarationStatement(readVars: readVars));

    if (readVars.contains(DetectChangesVars.changed.name) ||
        writeVars.contains(DetectChangesVars.changed.name)) {
      varStmts.add(DetectChangesVars.changed
          .set(o.literal(false))
          .toDeclStmt(o.BOOL_TYPE));
    }
    if (readVars.contains(DetectChangesVars.firstCheck.name)) {
      varStmts.add(o.DeclareVarStmt(DetectChangesVars.firstCheck.name,
          o.THIS_EXPR.prop('firstCheck'), o.BOOL_TYPE));
    }
    return List.from(varStmts)..addAll(statements);
  }

  o.ClassMethod writeInjectorGetMethod() {
    final statements = providers?.build() ?? [];
    return o.ClassMethod(
      'injectorGetInternal',
      [
        o.FnParam(InjectMethodVars.token.name, o.DYNAMIC_TYPE),
        o.FnParam(InjectMethodVars.nodeIndex.name, o.INT_TYPE),
        o.FnParam(InjectMethodVars.notFoundResult.name, o.DYNAMIC_TYPE)
      ],
      _addReturnValueIfNotEmpty(statements, InjectMethodVars.notFoundResult),
      o.DYNAMIC_TYPE,
      null,
      [o.importExpr(Identifiers.dartCoreOverride)],
    );
  }

  // Returns reference for compile element or null if compile element
  // has no attached node (root node of embedded or host view).
  o.Expression _getParentRenderNode(CompileElement parentElement) {
    bool isRootNode = !identical(parentElement.view, this);
    if (isRootNode) {
      if (viewType == ViewType.component) {
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

  void _initializeAndAppendNode(
    CompileElement parentElement,
    NodeReference nodeReference, [
    o.Expression value,
  ]) {
    if (value != null) {
      _createMethod.addStmt(nodeReference.toWriteStmt(value));
    }
    final parentExpr = _getParentRenderNode(parentElement);
    if (parentExpr != o.NULL_EXPR) {
      _createMethod.addStmt(parentExpr.callMethod(
        'append',
        [nodeReference.toReadExpr()],
      ).toStmt());
    }
  }

  /// Returns any type arguments specified for [rawDirectiveType] on [hostAst].
  ///
  /// Returns an empty list if no matching type arguments are found.
  List<o.OutputType> lookupTypeArgumentsOf(
    CompileTypeMetadata rawDirectiveType,
    TemplateAst hostAst,
  ) {
    if (rawDirectiveType.typeParameters.isEmpty) {
      return [];
    }
    var references = <ReferenceAst>[];
    if (hostAst is ElementAst) {
      references = hostAst.references;
    } else if (hostAst is EmbeddedTemplateAst) {
      references = hostAst.references;
    }
    // Given two `Typed` configurations that match the same directive:
    //  * One that specifies `on` takes precedence over one that doesn't.
    //  * Otherwise the first match takes precedence over any others.
    List<o.OutputType> firstMatchingTypeArguments;
    for (final directiveType in directiveTypes) {
      if (directiveType.name == rawDirectiveType.name &&
          directiveType.moduleUrl == rawDirectiveType.moduleUrl) {
        if (directiveType.on != null) {
          // If `on` is specified, the type arguments only apply if the
          // directive's host element has a matching reference name.
          for (final reference in references) {
            if (directiveType.on == reference.name) {
              return directiveType.typeArguments;
            }
          }
        } else if (firstMatchingTypeArguments == null) {
          // Otherwise the type arguments apply to all instances of the
          // directive in the view.
          if (references.isEmpty) {
            // If the directive's host element has no references, it's not
            // possible for more specific type arguments to be applied, so we
            // return the first match.
            return directiveType.typeArguments;
          } else {
            // Otherwise we remember the first matching type arguments so that
            // they may be applied if reference matching type arguments aren't
            // later specified.
            firstMatchingTypeArguments = directiveType.typeArguments;
          }
        }
      }
    }
    return firstMatchingTypeArguments ?? [];
  }
}

ViewType _getViewType(
    CompileDirectiveMetadata component, int embeddedTemplateIndex) {
  if (embeddedTemplateIndex > 0) {
    return ViewType.embedded;
  } else if (component.type.isHost) {
    return ViewType.host;
  } else {
    return ViewType.component;
  }
}

List<o.Statement> _addReturnValueIfNotEmpty(
    List<o.Statement> statements, o.Expression value) {
  if (statements.isEmpty) {
    return statements;
  } else {
    return List.from(statements)..addAll([o.ReturnStatement(value)]);
  }
}

/// CompileView implementation of ViewStorage which stores instances as
/// class member fields on the AppView class.
///
/// Storage is used to share instances with child views and
/// to share data between build and change detection methods.
///
/// The CompileView reuses simple ClassField(s) to implement storage for
/// runtime.
class CompileViewStorage implements ViewStorage {
  final List<o.ClassField> fields = [];

  @override
  ViewStorageItem allocate(String name,
      {o.OutputType outputType,
      List<o.StmtModifier> modifiers,
      o.Expression initializer}) {
    fields.add(o.ClassField(name,
        outputType: outputType,
        modifiers: modifiers,
        initializer: initializer));
    return ViewStorageItem(name,
        outputType: outputType, modifiers: modifiers, initializer: initializer);
  }

  @override
  o.Expression buildWriteExpr(ViewStorageItem item, o.Expression value) {
    return item.isStatic
        ? o.WriteStaticMemberExpr(item.name, value)
        : o.WriteClassMemberExpr(item.name, value);
  }

  @override
  o.Expression buildReadExpr(ViewStorageItem item) {
    return item.isStatic
        ? o.ReadStaticMemberExpr(item.name, type: item.outputType)
        : o.ReadClassMemberExpr(item.name, item.outputType);
  }
}
