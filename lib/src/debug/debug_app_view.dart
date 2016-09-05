import 'dart:html';

import 'package:angular2/src/core/change_detection/change_detection.dart'
    show ChangeDetectionStrategy, ChangeDetectorState;
import 'package:angular2/src/core/di.dart' show Injector;
import 'package:angular2/src/core/render/api.dart' show RenderComponentType;
import 'package:angular2/src/debug/debug_node.dart'
    show DebugElement, getDebugNode, indexDebugNode;
import 'package:angular2/src/core/profile/profile.dart'
    show wtfCreateScope, wtfLeave, WtfScopeFn;
import 'package:angular2/src/debug/debug_context.dart'
    show StaticNodeDebugInfo, DebugContext;
export 'package:angular2/src/debug/debug_context.dart'
    show StaticNodeDebugInfo, DebugContext;
import 'package:angular2/src/core/linker/app_element.dart';
import 'package:angular2/src/core/linker/exceptions.dart'
    show ExpressionChangedAfterItHasBeenCheckedException, ViewWrappedException;
import 'package:angular2/src/core/linker/app_view.dart';
export 'package:angular2/src/core/linker/app_view.dart';
import 'package:angular2/src/core/linker/view_type.dart';
import 'package:angular2/src/core/linker/view_utils.dart';

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
      ViewUtils viewUtils,
      Injector parentInjector,
      AppElement declarationAppElement,
      ChangeDetectionStrategy cdMode,
      this.staticNodeDebugInfos)
      : super(clazz, componentType, type, locals, viewUtils, parentInjector,
            declarationAppElement, cdMode);

  AppElement create(
      List<dynamic /* dynamic | List < dynamic > */ > givenProjectableNodes,
      selector) {
    String rootSelector = selector;
    this._resetDebug();
    try {
      return super.create(givenProjectableNodes, rootSelector);
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

  destroyLocal() {
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

  _resetDebug() {
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

  DebugContext debug(num nodeIndex, num rowNum, num colNum) =>
      _currentDebugContext = new DebugContext(this, nodeIndex, rowNum, colNum);

  /// Registers dom node in global debug index.
  void dbgElm(element, num nodeIndex, num rowNum, num colNum) {
    var debugInfo = new DebugContext<T>(this, nodeIndex, rowNum, colNum);
    if (element is Text) return;
    var debugEl = new DebugElement(
        element,
        element.parentNode == null ? null : getDebugNode(element.parentNode),
        debugInfo);
    debugEl.name = element is Text ? 'text' : element.tagName.toLowerCase();
    _currentDebugContext = debugInfo;
    indexDebugNode(debugEl);
  }

  _rethrowWithContext(dynamic e, dynamic stack) {
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
