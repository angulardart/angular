import 'dart:html';
import 'dart:convert';

import 'package:angular2/src/core/change_detection/change_detection.dart'
    show ChangeDetectionStrategy, ChangeDetectorState;
import 'package:angular2/src/core/di.dart' show Injector;
import 'package:angular2/src/core/render/api.dart';
import 'package:angular2/src/core/linker/view_container.dart';
import 'package:angular2/src/core/linker/app_view.dart';
import 'package:angular2/src/core/linker/exceptions.dart'
    show ExpressionChangedAfterItHasBeenCheckedException, ViewWrappedException;
import 'package:angular2/src/core/linker/view_type.dart';
import 'package:angular2/src/core/profile/profile.dart'
    show wtfCreateScope, wtfLeave, WtfScopeFn;
import 'package:angular2/src/core/render/api.dart' show RenderComponentType;
import 'package:angular2/src/debug/debug_context.dart'
    show StaticNodeDebugInfo, DebugContext;
import 'package:angular2/src/debug/debug_node.dart'
    show
        DebugElement,
        DebugNode,
        getDebugNode,
        indexDebugNode,
        DebugEventListener,
        removeDebugNodeFromIndex;
import "package:angular2/src/debug/debug_node.dart" show inspectNativeElement;
import 'package:angular2/src/platform/dom/dom_adapter.dart' show DOM;

export 'package:angular2/src/core/linker/app_view.dart';
export 'package:angular2/src/debug/debug_context.dart'
    show StaticNodeDebugInfo, DebugContext;

WtfScopeFn _scope_check = wtfCreateScope('AppView#check(ascii id)');

// RegExp to match anchor comment when logging bindings for debugging.
final RegExp _templateBindingsExp = new RegExp(r'^template bindings=(.*)$');
final RegExp _matchNewLine = new RegExp(r'\n');
const _templateCommentText = 'template bindings={}';
const INSPECT_GLOBAL_NAME = "ng.probe";

class DebugAppView<T> extends AppView<T> {
  static bool profilingEnabled = false;
  static bool _ngProbeInitialized = false;

  final List<StaticNodeDebugInfo> staticNodeDebugInfos;
  DebugContext _currentDebugContext;
  DebugAppView(
      dynamic clazz,
      RenderComponentType componentType,
      ViewType type,
      Map<String, dynamic> locals,
      Injector parentInjector,
      ViewContainer declarationViewContainer,
      ChangeDetectionStrategy cdMode,
      this.staticNodeDebugInfos)
      : super(clazz, componentType, type, locals, parentInjector,
            declarationViewContainer, cdMode) {
    if (!_ngProbeInitialized) {
      _ngProbeInitialized = true;
      DOM.setGlobalVar(INSPECT_GLOBAL_NAME, inspectNativeElement);
    }
  }

  @override
  ViewContainer create(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      selectorOrNode) {
    this._resetDebug();
    try {
      return super.create(givenProjectableNodes, selectorOrNode);
    } catch (e, e_stack) {
      this._rethrowWithContext(e, e_stack);
      rethrow;
    }
  }

  @override
  ViewContainer createComp(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      selectorOrNode) {
    this._resetDebug();
    try {
      return super.createComp(givenProjectableNodes, selectorOrNode);
    } catch (e, e_stack) {
      this._rethrowWithContext(e, e_stack);
      rethrow;
    }
  }

  @override
  ViewContainer createHost(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      selectorOrNode) {
    this._resetDebug();
    try {
      return super.createHost(givenProjectableNodes, selectorOrNode);
    } catch (e, e_stack) {
      this._rethrowWithContext(e, e_stack);
      rethrow;
    }
  }

  dynamic injectorGet(dynamic token, int nodeIndex, dynamic notFoundResult) {
    this._resetDebug();
    try {
      return super.injectorGet(token, nodeIndex, notFoundResult);
    } catch (e, e_stack) {
      this._rethrowWithContext(e, e_stack);
      rethrow;
    }
  }

  void destroyLocal() {
    this._resetDebug();
    try {
      super.destroyLocal();
    } catch (e, e_stack) {
      this._rethrowWithContext(e, e_stack);
      rethrow;
    }
  }

  void detectChanges() {
    this._resetDebug();
    if (profilingEnabled) {
      var s;
      try {
        var s = _scope_check(this.clazz);
        super.detectChanges();
        wtfLeave(s);
      } catch (e, e_stack) {
        wtfLeave(s);
        this._rethrowWithContext(e, e_stack);
        rethrow;
      }
    } else {
      try {
        super.detectChanges();
      } catch (e) {
        if (e is! ExpressionChangedAfterItHasBeenCheckedException) {
          cdState = ChangeDetectorState.Errored;
        }
        rethrow;
      }
    }
  }

  void _resetDebug() {
    this._currentDebugContext = null;
  }

  /*<R>*/ evt/*<E,R>*/(/*<R>*/ cb(/*<E>*/ e)) {
    var superHandler = super.evt(cb);
    return (/*<E>*/ event) {
      this._resetDebug();
      try {
        return superHandler(event);
      } catch (e, e_stack) {
        this._rethrowWithContext(e, e_stack);
        rethrow;
      }
    };
  }

  Function listen(dynamic renderElement, String name, Function callback) {
    var debugEl = getDebugNode(renderElement);
    if (debugEl != null) {
      debugEl.listeners.add(new DebugEventListener(name, callback));
    }
    return super.listen(renderElement, name, callback);
  }

  /// Used only in debug mode to serialize property changes to dom nodes as
  /// attributes.
  void setBindingDebugInfo(
      dynamic renderElement, String propertyName, String propertyValue) {
    if (renderElement is Comment) {
      var existingBindings = _templateBindingsExp
          .firstMatch(renderElement.text.replaceAll(_matchNewLine, ''));
      var parsedBindings = JSON.decode(existingBindings[1]);
      parsedBindings[propertyName] = propertyValue;
      String debugStr =
          const JsonEncoder.withIndent('  ').convert(parsedBindings);
      renderElement.text = _templateCommentText.replaceFirst('{}', debugStr);
    } else {
      setAttr(renderElement, propertyName, propertyValue);
    }
  }

  /// Sets up current debug context to node so that failures can be associated
  /// with template source location and DebugElement.
  DebugContext dbg(num nodeIndex, num rowNum, num colNum) =>
      _currentDebugContext = new DebugContext(this, nodeIndex, rowNum, colNum);

  /// Registers dom node in global debug index.
  void dbgElm(element, num nodeIndex, num rowNum, num colNum) {
    var debugInfo = new DebugContext<T>(this, nodeIndex, rowNum, colNum);
    if (element is Text) return;
    var debugEl;
    if (element is Comment) {
      debugEl =
          new DebugNode(element, getDebugNode(element.parentNode), debugInfo);
    } else {
      debugEl = new DebugElement(
          element,
          element.parentNode == null ? null : getDebugNode(element.parentNode),
          debugInfo);

      debugEl.name = element is Text ? 'text' : element.tagName.toLowerCase();

      _currentDebugContext = debugInfo;
    }
    indexDebugNode(debugEl);
  }

  /// Projects projectableNodes at specified index. We don't use helper
  /// functions to flatten the tree since it allocates list that are not
  /// required in most cases.
  void project(Element parentElement, int index) {
    DebugElement debugParent = getDebugNode(parentElement);
    if (debugParent == null || debugParent is! DebugElement) {
      super.project(parentElement, index);
      return;
    }
    // Optimization for projectables that doesn't include ViewContainer(s).
    // If the projectable is ViewContainer we fall back to building up a list.
    List projectables = projectableNodes[index];
    int projectableCount = projectables.length;
    for (var i = 0; i < projectableCount; i++) {
      var projectable = projectables[i];
      if (projectable is ViewContainer) {
        if (projectable.nestedViews == null) {
          Node child = projectable.nativeElement;
          parentElement.append(child);
          debugParent.addChild(getDebugNode(child));
        } else {
          _appendDebugNestedViewRenderNodes(
              debugParent, parentElement, projectable);
        }
      } else {
        Node child = projectable;
        parentElement.append(child);
        debugParent.addChild(getDebugNode(child));
      }
    }
    domRootRendererIsDirty = true;
  }

  void detachViewNodes(List<dynamic> viewRootNodes) {
    viewRootNodes.forEach((node) {
      var debugNode = getDebugNode(node);
      if (debugNode != null && debugNode.parent != null) {
        debugNode.parent.removeChild(debugNode);
      }
    });
    super.detachViewNodes(viewRootNodes);
  }

  @override
  dynamic selectRootElement(dynamic /* String | dynamic */ selectorOrNode,
      RenderDebugInfo debugInfo) {
    var nativeEl = super.selectRootElement(selectorOrNode, debugInfo);
    var debugEl = new DebugElement(nativeEl, null, debugInfo);
    indexDebugNode(debugEl);
    return nativeEl;
  }

  @override
  dynamic createElement(
      dynamic parentElement, String name, RenderDebugInfo debugInfo) {
    var nativeEl = super.createElement(parentElement, name, debugInfo);
    var debugEl =
        new DebugElement(nativeEl, getDebugNode(parentElement), debugInfo);
    debugEl.name = name;
    indexDebugNode(debugEl);
    return nativeEl;
  }

  @override
  void attachViewAfter(dynamic node, List<Node> viewRootNodes) {
    var debugNode = getDebugNode(node);
    if (debugNode != null) {
      var debugParent = debugNode?.parent;
      if (viewRootNodes.length > 0 && debugParent != null) {
        List<DebugNode> debugViewRootNodes = [];
        int rootNodeCount = viewRootNodes.length;
        for (int n = 0; n < rootNodeCount; n++) {
          var debugNode = getDebugNode(viewRootNodes[n]);
          if (debugNode == null) continue;
          debugViewRootNodes.add(debugNode);
        }
        debugParent.insertChildrenAfter(debugNode, debugViewRootNodes);
      }
    }
    super.attachViewAfter(node, viewRootNodes);
  }

  @override
  void destroyViewNodes(dynamic hostElement, List<dynamic> viewAllNodes) {
    int nodeCount = viewAllNodes.length;
    for (int i = 0; i < nodeCount; i++) {
      var debugNode = getDebugNode(viewAllNodes[i]);
      if (debugNode == null) continue;
      removeDebugNodeFromIndex(debugNode);
    }
    super.destroyViewNodes(hostElement, viewAllNodes);
  }

  void _rethrowWithContext(dynamic e, dynamic stack) {
    if (!(e is ViewWrappedException)) {
      if (!(e is ExpressionChangedAfterItHasBeenCheckedException)) {
        this.cdState = ChangeDetectorState.Errored;
      }
      if (this._currentDebugContext != null) {
        throw new ViewWrappedException(e, stack, this._currentDebugContext);
      }
    }
  }
}

/// Recursively appends app element and nested view nodes to target element.
void _appendDebugNestedViewRenderNodes(
    DebugElement debugParent, Element targetElement, ViewContainer appElement) {
  targetElement.append(appElement.nativeElement as Node);
  var nestedViews = appElement.nestedViews;
  if (nestedViews == null || nestedViews.isEmpty) return;
  int nestedViewCount = nestedViews.length;
  for (int viewIndex = 0; viewIndex < nestedViewCount; viewIndex++) {
    List projectables = nestedViews[viewIndex].rootNodesOrViewContainers;
    int projectableCount = projectables.length;
    for (var i = 0; i < projectableCount; i++) {
      var projectable = projectables[i];
      if (projectable is ViewContainer) {
        _appendDebugNestedViewRenderNodes(
            debugParent, targetElement, projectable);
      } else {
        Node child = projectable;
        targetElement.append(child);
        debugParent.addChild(getDebugNode(child));
      }
    }
  }
}
