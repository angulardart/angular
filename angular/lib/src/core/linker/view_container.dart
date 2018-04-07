import 'dart:html';

import 'package:angular/src/di/injector/injector.dart' show Injector;
import 'package:angular/src/runtime.dart';

import 'app_view.dart';
import 'component_factory.dart' show ComponentFactory, ComponentRef;
import 'component_loader.dart';
import 'element_ref.dart';
import 'template_ref.dart';
import 'view_container_ref.dart';
import 'view_ref.dart' show EmbeddedViewRef, ViewRef, ViewRefImpl;
import 'view_type.dart';

/// A container providing an insertion point for attaching children.
///
/// This is created for components containing a nested component or a
/// `<template>` element so they can be attached after initialization.
class ViewContainer extends ComponentLoader implements ViewContainerRef {
  final int index;
  final int parentIndex;
  final AppView parentView;
  final Node nativeElement;
  List<AppView> nestedViews;
  ElementRef _elementRef;
  Injector _parentInjector;

  ViewContainer(
      this.index, this.parentIndex, this.parentView, this.nativeElement);

  ElementRef get elementRef => _elementRef ??= new ElementRef(nativeElement);

  /// Returns the [ViewRef] for the View located in this container at the
  /// specified index.
  @override
  EmbeddedViewRef get(int index) {
    return nestedViews[index].viewData.ref;
  }

  /// The number of Views currently attached to this container.
  @override
  int get length {
    var nested = nestedViews;
    return nested == null ? 0 : nested.length;
  }

  /// Anchor element that specifies the location of this container in the
  /// containing View.
  @override
  ElementRef get element => elementRef;

  @override
  Injector get parentInjector =>
      _parentInjector ??= parentView.injector(parentIndex);

  @override
  Injector get injector => parentView.injector(index);

  void detectChangesInNestedViews() {
    var _nestedViews = nestedViews;
    if (_nestedViews == null) return;
    for (var i = 0, len = _nestedViews.length; i < len; i++) {
      _nestedViews[i].detectChanges();
    }
  }

  void destroyNestedViews() {
    var _nestedViews = nestedViews;
    if (_nestedViews == null) return;
    for (var i = 0, len = _nestedViews.length; i < len; i++) {
      _nestedViews[i].destroy();
    }
  }

  /// Instantiates an Embedded View based on the [TemplateRef `templateRef`]
  /// and inserts it into this container at the specified `index`.
  ///
  /// If `index` is not specified, the new View will be inserted as the last
  /// View in the container.
  ///
  /// Returns the [ViewRef] for the newly created View.
  @override
  EmbeddedViewRef insertEmbeddedView(TemplateRef templateRef, int index) {
    EmbeddedViewRef viewRef = templateRef.createEmbeddedView();
    insert(viewRef, index);
    return viewRef;
  }

  /// Instantiates an Embedded View based on the [TemplateRef `templateRef`]
  /// and appends it into this container.
  @override
  EmbeddedViewRef createEmbeddedView(TemplateRef templateRef) {
    EmbeddedViewRef viewRef = templateRef.createEmbeddedView();
    attachView((viewRef as ViewRefImpl).appView, length);
    return viewRef;
  }

  ComponentRef<T> createComponent<T>(
    ComponentFactory<T> componentFactory, [
    int index = -1,
    Injector injector,
    List<List<dynamic>> projectableNodes,
  ]) {
    var contextInjector = injector ?? parentInjector;
    var componentRef =
        componentFactory.create(contextInjector, projectableNodes);
    insert(componentRef.hostView, index);
    return componentRef;
  }

  @override
  ViewRef insert(ViewRef viewRef, [int index = -1]) {
    if (index == -1) index = this.length;
    var viewRef_ = (viewRef as ViewRefImpl);
    attachView(viewRef_.appView, index);
    return viewRef;
  }

  @override
  ViewRef move(ViewRef viewRef, int currentIndex) {
    if (currentIndex == -1) return null;
    var viewRef_ = viewRef as ViewRefImpl;
    moveView(viewRef_.appView, currentIndex);
    return viewRef_;
  }

  /// Returns the index of the View, specified via [ViewRef], within the current
  /// container or `-1` if this container doesn't contain the View.
  @override
  int indexOf(ViewRef viewRef) =>
      nestedViews.indexOf((viewRef as ViewRefImpl).appView);

  /// Destroys a View attached to this container at the specified `index`.
  ///
  /// If `index` is not specified, the last View in the container will be
  /// removed.
  /// TODO(i): rename to destroy
  @override
  void remove([int index = -1]) {
    if (index == -1) index = this.length - 1;
    var view = detachView(index);
    view.destroy();
  }

  /// Use along with [#insert] to move a View within the current container.
  ///
  /// If the `index` param is omitted, the last [ViewRef] is detached.
  /// TODO(i): refactor insert+remove into move
  @override
  ViewRef detach([int index = -1]) {
    if (index == -1) index = this.length - 1;
    return detachView(index).viewData.ref;
  }

  /// Destroys all Views in this container.
  @override
  void clear() {
    for (var i = this.length - 1; i >= 0; i--) {
      remove(i);
    }
  }

  List<T> mapNestedViews<T, U extends AppView>(List<T> Function(U) callback) {
    final nestedViews = this.nestedViews;
    if (nestedViews == null || nestedViews.isEmpty) {
      return const [];
    }
    final result = <T>[];
    for (var i = 0, l = nestedViews.length; i < l; i++) {
      result.addAll(callback(unsafeCast<U>(nestedViews[i])));
    }
    return result;
  }

  void moveView(AppView view, int currentIndex) {
    List<AppView> views = nestedViews;

    int previousIndex = views.indexOf(view);

    if (view.viewData.type == ViewType.component) {
      throw new Exception("Component views can't be moved!");
    }

    if (views == null) {
      views = <AppView>[];
      nestedViews = views;
    }

    views.removeAt(previousIndex);
    views.insert(currentIndex, view);
    Node refRenderNode;

    if (currentIndex > 0) {
      AppView prevView = views[currentIndex - 1];
      refRenderNode = prevView.lastRootNode;
    } else {
      refRenderNode = nativeElement;
    }

    if (refRenderNode != null) {
      view.attachViewAfter(refRenderNode, view.flatRootNodes);
    }

    view.markContentChildAsMoved(this);
  }

  void attachView(AppView view, int viewIndex) {
    if (identical(view.viewData.type, ViewType.component)) {
      throw new StateError("Component views can't be moved!");
    }
    var _nestedViews = nestedViews ?? <AppView>[];
    _nestedViews.insert(viewIndex, view);
    Node refRenderNode;
    if (viewIndex > 0) {
      var prevView = _nestedViews[viewIndex - 1];
      refRenderNode = prevView.lastRootNode;
    } else {
      refRenderNode = nativeElement;
    }
    nestedViews = _nestedViews;
    if (refRenderNode != null) {
      view.attachViewAfter(refRenderNode, view.flatRootNodes);
    }
    view.addToContentChildren(this);
  }

  AppView detachView(int viewIndex) {
    var view = nestedViews.removeAt(viewIndex);
    if (view.viewData.type == ViewType.component) {
      throw new StateError("Component views can't be moved!");
    }
    view.detachViewNodes(view.flatRootNodes);
    if (view.inlinedNodes != null) {
      view.detachViewNodes(view.inlinedNodes);
    }
    view.removeFromContentChildren(this);
    return view;
  }

  @override
  ComponentRef<T> loadNextTo<T>(
    ComponentFactory<T> component, {
    Injector injector,
  }) =>
      loadNextToLocation(component, this, injector: injector);
}
