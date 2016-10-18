import 'dart:html';

import 'package:angular2/src/core/change_detection/change_detection.dart'
    show ChangeDetectionStrategy, ChangeDetectorState;
import 'package:angular2/src/core/di.dart' show Injector;
import 'package:angular2/src/core/linker/app_element.dart';
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
    show DebugElement, DebugNode, getDebugNode, indexDebugNode;
import 'package:angular2/src/platform/dom/dom_renderer.dart'
    show DomRootRenderer;

export 'package:angular2/src/core/linker/app_view.dart';
export 'package:angular2/src/debug/debug_context.dart'
    show StaticNodeDebugInfo, DebugContext;

WtfScopeFn _scope_check = wtfCreateScope('AppView#check(ascii id)');

class DebugAppView<T> extends AppView<T> {
  static bool profilingEnabled = false;

  final List<StaticNodeDebugInfo> staticNodeDebugInfos;
  DebugContext _currentDebugContext;
  DebugAppView(
      dynamic clazz,
      RenderComponentType componentType,
      ViewType type,
      Map<String, dynamic> locals,
      Injector parentInjector,
      AppElement declarationAppElement,
      ChangeDetectionStrategy cdMode,
      this.staticNodeDebugInfos)
      : super(clazz, componentType, type, locals, parentInjector,
            declarationAppElement, cdMode);

  @override
  AppElement create(
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
  AppElement createComp(
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
  AppElement createHost(
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

  dynamic injectorGet(dynamic token, num nodeIndex, dynamic notFoundResult) {
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

  Function evt(Function cb) {
    var superHandler = super.evt(cb);
    return (event) {
      this._resetDebug();
      try {
        return superHandler(event);
      } catch (e, e_stack) {
        this._rethrowWithContext(e, e_stack);
        rethrow;
      }
    };
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
    // Optimization for projectables that doesn't include AppElement(s).
    // If the projectable is AppElement we fall back to building up a list.
    List projectables = projectableNodes[index];
    int projectableCount = projectables.length;
    for (var i = 0; i < projectableCount; i++) {
      var projectable = projectables[i];
      if (projectable is AppElement) {
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
    DomRootRenderer.isDirty = true;
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
    DebugElement debugParent, Element targetElement, AppElement appElement) {
  targetElement.append(appElement.nativeElement as Node);
  var nestedViews = appElement.nestedViews;
  if (nestedViews == null || nestedViews.isEmpty) return;
  int nestedViewCount = nestedViews.length;
  for (int viewIndex = 0; viewIndex < nestedViewCount; viewIndex++) {
    List projectables = nestedViews[viewIndex].rootNodesOrAppElements;
    int projectableCount = projectables.length;
    for (var i = 0; i < projectableCount; i++) {
      var projectable = projectables[i];
      if (projectable is AppElement) {
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
