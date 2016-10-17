import 'dart:html';

import 'package:angular2/src/core/change_detection/change_detection.dart'
    as import9;
import 'package:angular2/src/core/di/injector.dart' as import6;
import 'package:angular2/src/core/linker/app_element.dart' as import7;
import 'package:angular2/src/core/linker/app_view_utils.dart' as import5;
import 'package:angular2/src/core/linker/component_factory.dart' as import11;
import 'package:angular2/src/core/linker/view_type.dart' as import8;
import 'package:angular2/src/core/metadata/view.dart' as import10;
import 'package:angular2/src/core/render/api.dart' as import2;
import 'package:angular2/src/debug/debug_app_view.dart' as import3;
import 'package:angular2/src/debug/debug_context.dart' as import1;

import 'offline_compiler_compa.css.shim.dart' as import0;
import 'offline_compiler_util.dart' as import4;

const List<dynamic> styles_CompA = const [
  '.redStyle[_ngcontent-%COMP%] { color: red; }',
  import0.styles
];
const List<import1.StaticNodeDebugInfo> nodeDebugInfos_CompA0 = const [
  const import1.StaticNodeDebugInfo(const [], null, const <String, dynamic>{})
];
import2.RenderComponentType renderType_CompA;

class _ViewCompA0 extends import3.DebugAppView<import4.CompA> {
  var _text_0;
  var _expr_0;
  _ViewCompA0(import6.Injector parentInjector, import7.AppElement declarationEl)
      : super(
            _ViewCompA0,
            renderType_CompA,
            import8.ViewType.COMPONENT,
            {},
            parentInjector,
            declarationEl,
            import9.ChangeDetectionStrategy.CheckAlways,
            nodeDebugInfos_CompA0);
  import7.AppElement createInternal(dynamic rootSelector) {
    final parentRenderNode =
        this.initViewRoot(this.declarationAppElement.nativeElement);
    _text_0 = new Text('');
    parentRenderNode.append(_text_0);
    dbgElm(_text_0, 0, 0, 0);
    _expr_0 = import9.uninitialized;
    this.init([], [this._text_0], []);
    return null;
  }

  void detectChangesInternal() {
    this.detectContentChildrenChanges();
    dbg(0, 0, 0);
    final currVal_0 =
        import5.interpolate(1, 'Hello World ', this.ctx.user, '!');
    if (import5.checkBinding(_expr_0, currVal_0)) {
      _text_0.text = currVal_0;
      _expr_0 = currVal_0;
    }
    this.detectViewChildrenChanges();
  }
}

import3.AppView<import4.CompA> viewFactory_CompA0(
    import6.Injector parentInjector, import7.AppElement declarationEl) {
  if (identical(renderType_CompA, null)) {
    (renderType_CompA = import5.appViewUtils.createRenderComponentType(
        'asset:angular2/test/compiler/offline_compiler_compa.html',
        0,
        import10.ViewEncapsulation.Emulated,
        styles_CompA));
  }
  return new _ViewCompA0(parentInjector, declarationEl);
}

const List<dynamic> styles_CompA_Host = const [];
const List<import1.StaticNodeDebugInfo> nodeDebugInfos_CompA_Host0 = const [
  const import1.StaticNodeDebugInfo(
      const [import4.CompA], import4.CompA, const <String, dynamic>{}),
  null // Testing null default case.
];
import2.RenderComponentType renderType_CompA_Host;

class _ViewCompAHost0 extends import3.DebugAppView<dynamic> {
  var _el_0;
  import7.AppElement _appEl_0;
  import4.CompA _CompA_0_4;
  _ViewCompAHost0(
      import6.Injector parentInjector, import7.AppElement declarationEl)
      : super(
            _ViewCompAHost0,
            renderType_CompA_Host,
            import8.ViewType.HOST,
            {},
            parentInjector,
            declarationEl,
            import9.ChangeDetectionStrategy.CheckAlways,
            nodeDebugInfos_CompA_Host0);
  import7.AppElement createInternal(dynamic rootSelector) {
    this._el_0 =
        this.selectOrCreateHostElement('comp-a', rootSelector, dbg(0, 0, 0));
    this._appEl_0 = new import7.AppElement(0, null, this, this._el_0);
    var compView_0 = viewFactory_CompA0(this.injector(0), this._appEl_0);
    this._CompA_0_4 = new import4.CompA();
    this._appEl_0.initComponent(this._CompA_0_4, [], compView_0);
    compView_0.create(this.projectableNodes, null);
    this.init([]..addAll([this._el_0]), [this._el_0], []);
    return this._appEl_0;
  }

  dynamic injectorGetInternal(
      dynamic token, num requestNodeIndex, dynamic notFoundResult) {
    if ((identical(token, import4.CompA) && identical(0, requestNodeIndex))) {
      return this._CompA_0_4;
    }
    return notFoundResult;
  }
}

import3.AppView<dynamic> viewFactory_CompA_Host0(
    import6.Injector parentInjector, import7.AppElement declarationEl) {
  if (identical(renderType_CompA_Host, null)) {
    (renderType_CompA_Host = import5.appViewUtils.createRenderComponentType(
        '', 0, import10.ViewEncapsulation.Emulated, styles_CompA_Host));
  }
  return new _ViewCompAHost0(parentInjector, declarationEl);
}

const import11.ComponentFactory CompANgFactory =
    const import11.ComponentFactory(
        'comp-a', viewFactory_CompA_Host0, import4.CompA, _METADATA);
const _METADATA = const [];
