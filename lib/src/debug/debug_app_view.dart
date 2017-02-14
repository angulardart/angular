import 'dart:html';
import 'dart:convert';
import 'dart:js_util' as js_util;
import 'package:js/js.dart' as js;

import 'package:angular2/src/core/change_detection/change_detection.dart'
    show ChangeDetectionStrategy, ChangeDetectorState;
import 'package:angular2/src/core/di.dart' show Injector;
import 'package:angular2/src/core/di/injector.dart' show THROW_IF_NOT_FOUND;
import 'package:angular2/src/core/render/api.dart';
import 'package:angular2/src/core/linker/view_container.dart';
import 'package:angular2/src/core/linker/app_view.dart';
import 'package:angular2/src/core/linker/component_factory.dart';
import 'package:angular2/src/core/linker/exceptions.dart'
    show ExpressionChangedAfterItHasBeenCheckedException, ViewWrappedException;
import 'package:angular2/src/core/linker/view_type.dart';
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

export 'package:angular2/src/core/linker/app_view.dart';
export 'package:angular2/src/debug/debug_context.dart'
    show StaticNodeDebugInfo, DebugContext;

// RegExp to match anchor comment when logging bindings for debugging.
final RegExp _templateBindingsExp = new RegExp(r'^template bindings=(.*)$');
final RegExp _matchNewLine = new RegExp(r'\n');
const _templateCommentText = 'template bindings={}';
const INSPECT_GLOBAL_NAME = "ng.probe";

class DebugAppView<T> extends AppView<T> {
  static bool _ngProbeInitialized = false;

  final List<StaticNodeDebugInfo> staticNodeDebugInfos;
  DebugContext _currentDebugContext;
  DebugAppView(
      dynamic clazz,
      ViewType type,
      Map<String, dynamic> locals,
      AppView parentView,
      int parentIndex,
      Node parentElement,
      ChangeDetectionStrategy cdMode,
      this.staticNodeDebugInfos)
      : super(clazz, type, locals, parentView, parentIndex, parentElement,
            cdMode) {
    this.cdMode = cdMode;
    if (!_ngProbeInitialized) {
      _ngProbeInitialized = true;
      _setGlobalVar(INSPECT_GLOBAL_NAME, inspectNativeElement);
    }
  }

  @override
  ComponentRef create(
      T context,
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      dynamic /* String | Node */ rootSelectorOrNode) {
    this._resetDebug();
    try {
      return super.create(context, givenProjectableNodes, rootSelectorOrNode);
    } catch (e, s) {
      this._rethrowWithContext(e, s);
      rethrow;
    }
  }

  /// Builds host level view.
  @override
  ComponentRef createHostView(
      dynamic /* String | Node */ rootSelectorOrNode,
      Injector hostInjector,
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes) {
    this._resetDebug();
    try {
      return super.createHostView(
          rootSelectorOrNode, hostInjector, givenProjectableNodes);
    } catch (e, s) {
      this._rethrowWithContext(e, s);
      rethrow;
    }
  }

  @override
  dynamic injectorGet(dynamic token, int nodeIndex,
      [dynamic notFoundResult = THROW_IF_NOT_FOUND]) {
    this._resetDebug();
    try {
      return super.injectorGet(token, nodeIndex, notFoundResult);
    } catch (e, s) {
      this._rethrowWithContext(e, s, stopChangeDetection: false);
      rethrow;
    }
  }

  @override
  void destroy() {
    this._resetDebug();
    try {
      super.destroy();
    } catch (e, s) {
      this._rethrowWithContext(e, s);
      rethrow;
    }
  }

  @override
  void detectChanges() {
    this._resetDebug();
    try {
      super.detectChanges();
    } catch (e) {
      if (e is! ExpressionChangedAfterItHasBeenCheckedException) {
        cdState = ChangeDetectorState.Errored;
      }
      rethrow;
    }
  }

  void _resetDebug() {
    this._currentDebugContext = null;
  }

  @override
  /*<R>*/ evt<E, R>(/*<R>*/ cb(/*<E>*/ e)) {
    var superHandler = super.evt(cb);
    return (/*<E>*/ event) {
      this._resetDebug();
      try {
        return superHandler(event);
      } catch (e, s) {
        this._rethrowWithContext(e, s);
        rethrow;
      }
    };
  }

  @override
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
  @override
  void project(Element parentElement, int index) {
    DebugElement debugParent = getDebugNode(parentElement);
    if (debugParent == null || debugParent is! DebugElement) {
      super.project(parentElement, index);
      return;
    }
    // Optimization for projectables that doesn't include ViewContainer(s).
    // If the projectable is ViewContainer we fall back to building up a list.
    if (projectableNodes == null || index >= projectableNodes.length) return;
    List projectables = projectableNodes[index];
    if (projectables == null) return;
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

  @override
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

  void _rethrowWithContext(dynamic e, dynamic stack,
      {bool stopChangeDetection: true}) {
    if (!(e is ViewWrappedException)) {
      if (stopChangeDetection &&
          !(e is ExpressionChangedAfterItHasBeenCheckedException)) {
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

void _setGlobalVar(String path, value) {
  var parts = path.split('.');
  Object obj = window;
  for (var i = 0; i < parts.length - 1; i++) {
    var name = parts[i];
    if (!js_util.callMethod(obj, 'hasOwnProperty', [name])) {
      js_util.setProperty(obj, name, js_util.newObject());
    }
    obj = js_util.getProperty(obj, name);
  }
  js_util.setProperty(obj, parts[parts.length - 1],
      (value is Function) ? js.allowInterop(value) : value);
}
