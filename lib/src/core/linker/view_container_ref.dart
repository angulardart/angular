import 'package:angular2/src/core/di/injector.dart' show Injector;

import '../profile/profile.dart' show wtfCreateScope, wtfLeave, WtfScopeFn;
import 'component_factory.dart' show ComponentFactory, ComponentRef;
import 'app_element.dart';
import 'element_ref.dart';
import 'template_ref.dart';
import 'view_ref.dart' show EmbeddedViewRef, ViewRef, ViewRefImpl;

/// Represents a container where one or more Views can be attached.
///
/// The container can contain two kinds of Views. Host Views, created by
/// instantiating a [Component] via [#createComponent], and Embedded Views,
/// created by instantiating an [TemplateRef Embedded Template] via
/// [#createEmbeddedView].
///
/// The location of the View Container within the containing View is specified
/// by the Anchor `element`. Each View Container can have only one Anchor
/// Element and each Anchor Element can only have a single View Container.
///
/// Root elements of Views attached to this container become siblings of the
/// Anchor Element in the Rendered View.
///
/// To access a `ViewContainerRef` of an Element, you can either place a
/// [Directive] injected with `ViewContainerRef` on the Element, or you obtain
/// it via a [ViewChild] query.
class ViewContainerRef {
  AppElement _element;

  ViewContainerRef(this._element);

  /// Returns the [ViewRef] for the View located in this container at the
  /// specified index.
  EmbeddedViewRef get(num index) {
    return _element.nestedViews[index].ref;
  }

  /// Returns the number of Views currently attached to this container.
  num get length => _element.nestedViews?.length ?? 0;

  /// Anchor element that specifies the location of this container in the
  /// containing View.
  ElementRef get element => _element.elementRef;

  Injector get injector => _element.injector;

  Injector get parentInjector => _element.parentInjector;

  /// Instantiates an Embedded View based on the [TemplateRef `templateRef`]
  /// and inserts it into this container at the specified `index`.
  ///
  /// If `index` is not specified, the new View will be inserted as the last
  /// View in the container.
  ///
  /// Returns the [ViewRef] for the newly created View.
  EmbeddedViewRef createEmbeddedView(TemplateRef templateRef,
      [num index = -1]) {
    EmbeddedViewRef viewRef = templateRef.createEmbeddedView();
    this.insert(viewRef, index);
    return viewRef;
  }

  WtfScopeFn _createComponentInContainerScope =
      wtfCreateScope('ViewContainerRef#createComponent()');

  /// Instantiates a single [Component] and inserts its Host View into this
  /// container at the specified `index`.
  ///
  /// The component is instantiated using its [ComponentFactory] which can be
  /// obtained via [ComponentResolver#resolveComponent].
  ///
  /// If `index` is not specified, the new View will be inserted as the last
  /// View in the container.
  ///
  /// You can optionally specify the [Injector] that will be used as parent for
  /// the Component.
  ///
  ///Returns the [ComponentRef] of the Host View created for the newly
  /// instantiated Component.
  ComponentRef createComponent(ComponentFactory componentFactory,
      [num index = -1,
      Injector injector = null,
      List<List<dynamic>> projectableNodes = null]) {
    var s = this._createComponentInContainerScope();
    var contextInjector =
        injector != null ? injector : this._element.parentInjector;
    var componentRef =
        componentFactory.create(contextInjector, projectableNodes);
    this.insert(componentRef.hostView, index);
    return wtfLeave(s, componentRef);
  }

  var _insertScope = wtfCreateScope('ViewContainerRef#insert()');

  /// Inserts a View identified by a [ViewRef] into the container.
  ///
  /// If `index` is not specified, the new View will be inserted as the
  /// last View in the container.
  ///
  /// Returns the inserted [ViewRef].
  /// TODO(i): refactor insert+remove into move
  ViewRef insert(ViewRef viewRef, [num index = -1]) {
    var s = this._insertScope();
    if (index == -1) index = this.length;
    var viewRef_ = (viewRef as ViewRefImpl);
    this._element.attachView(viewRef_.internalView, index);
    return wtfLeave(s, viewRef_);
  }

  ViewRef move(ViewRef viewRef, int currentIndex) {
    ViewRef s = _insertScope();
    if (currentIndex == -1) return null;

    dynamic viewRef_ = viewRef as ViewRefImpl;
    _element.moveView(viewRef_.internalView, currentIndex);
    return wtfLeave(s, viewRef_);
  }

  /// Returns the index of the View, specified via [ViewRef], within the current
  /// container or `-1` if this container doesn't contain the View.
  num indexOf(ViewRef viewRef) =>
      _element.nestedViews.indexOf((viewRef as ViewRefImpl).internalView);

  var _removeScope = wtfCreateScope('ViewContainerRef#remove()');

  /// Destroys a View attached to this container at the specified `index`.
  ///
  /// If `index` is not specified, the last View in the container will be
  /// removed.
  /// TODO(i): rename to destroy
  void remove([num index = -1]) {
    var s = this._removeScope();
    if (index == -1) index = this.length - 1;
    var view = this._element.detachView(index);
    view.destroy();
    // view is intentionally not returned to the client.
    wtfLeave(s);
  }

  var _detachScope = wtfCreateScope('ViewContainerRef#detach()');

  /// Use along with [#insert] to move a View within the current container.
  ///
  /// If the `index` param is omitted, the last [ViewRef] is detached.
  /// TODO(i): refactor insert+remove into move
  ViewRef detach([num index = -1]) {
    var s = this._detachScope();
    if (index == -1) index = this.length - 1;
    var view = this._element.detachView(index);
    return wtfLeave(s, view.ref);
  }

  /// Destroys all Views in this container.
  void clear() {
    for (var i = this.length - 1; i >= 0; i--) {
      this.remove(i);
    }
  }
}
