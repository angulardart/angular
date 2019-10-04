import 'dart:html';

import 'package:meta/meta.dart';
import 'package:angular/src/di/injector/injector.dart' show Injector;
import 'package:angular/src/runtime.dart';

import 'component_factory.dart' show ComponentFactory, ComponentRef;
import 'component_loader.dart';
import 'element_ref.dart';
import 'template_ref.dart';
import 'view_container_ref.dart';
import 'view_ref.dart' show EmbeddedViewRef, ViewRef;
import 'views/dynamic_view.dart';
import 'views/view.dart';

/// A container providing an insertion point for attaching children.
///
/// This is created for components containing a nested component or a
/// `<template>` element so they can be attached after initialization.
class ViewContainer extends ComponentLoader implements ViewContainerRef {
  final int index;
  final int parentIndex;
  final View parentView;
  final Node nativeElement;

  List<DynamicView> nestedViews;

  ViewContainer(
    this.index,
    this.parentIndex,
    this.parentView,
    this.nativeElement,
  );

  @Deprecated('Use .nativeElement instead')
  ElementRef get elementRef => ElementRef(nativeElement);

  /// Returns the [ViewRef] for the View located in this container at the
  /// specified index.
  @override
  ViewRef get(int index) {
    return nestedViews[index];
  }

  /// The number of Views currently attached to this container.
  @override
  int get length {
    final nested = nestedViews;
    return nested == null ? 0 : nested.length;
  }

  /// Anchor element that specifies the location of this container in the
  /// containing View.
  @override
  ElementRef get element => elementRef;

  @override
  Injector get parentInjector => parentView.injector(parentIndex);

  @override
  Injector get injector => parentView.injector(index);

  @experimental
  void detectChangesInCheckAlwaysViews() {
    final nested = nestedViews;
    if (nested == null) {
      return;
    }
    for (var i = 0, len = nested.length; i < len; i++) {
      nested[i].detectChangesInCheckAlwaysViews();
    }
  }

  void detectChangesInNestedViews() {
    final nested = nestedViews;
    if (nested == null) {
      return;
    }
    for (var i = 0, len = nested.length; i < len; i++) {
      nested[i].detectChanges();
    }
  }

  void destroyNestedViews() {
    final nested = nestedViews;
    if (nested == null) {
      return;
    }
    for (var i = 0, len = nested.length; i < len; i++) {
      nested[i].destroyInternalState();
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
    final viewRef = templateRef.createEmbeddedView();
    insert(viewRef, index);
    return viewRef;
  }

  /// Instantiates an Embedded View based on the [TemplateRef `templateRef`]
  /// and appends it into this container.
  @override
  EmbeddedViewRef createEmbeddedView(TemplateRef templateRef) {
    final viewRef = templateRef.createEmbeddedView();
    attachView(unsafeCast(viewRef), length);
    return viewRef;
  }

  ComponentRef<T> createComponent<T>(
    ComponentFactory<T> componentFactory, [
    int index = -1,
    Injector injector,
    List<List<dynamic>> projectableNodes,
  ]) {
    final contextInjector = injector ?? parentInjector;
    final componentRef = componentFactory.create(
      contextInjector,
      projectableNodes,
    );
    insert(componentRef.hostView, index);
    return componentRef;
  }

  @override
  ViewRef insert(ViewRef viewRef, [int index = -1]) {
    if (index == -1) {
      index = length;
    }
    attachView(unsafeCast(viewRef), index);
    return viewRef;
  }

  @override
  ViewRef move(ViewRef viewRef, int currentIndex) {
    if (currentIndex == -1) {
      return null;
    }
    moveView(unsafeCast(viewRef), currentIndex);
    return viewRef;
  }

  /// Returns the index of the View, specified via [ViewRef], within the current
  /// container or `-1` if this container doesn't contain the View.
  @override
  int indexOf(ViewRef viewRef) {
    return nestedViews.indexOf(unsafeCast(viewRef));
  }

  /// Destroys a View attached to this container at the specified `index`.
  ///
  /// If `index` is not specified, the last View in the container will be
  /// removed.
  /// TODO(i): rename to destroy
  @override
  void remove([int index = -1]) {
    if (index == -1) {
      index = length - 1;
    }
    detachView(index).destroyInternalState();
  }

  /// Use along with [#insert] to move a View within the current container.
  ///
  /// If the `index` param is omitted, the last [ViewRef] is detached.
  /// TODO(i): refactor insert+remove into move
  @override
  ViewRef detach([int index = -1]) {
    if (index == -1) {
      index = length - 1;
    }
    return detachView(index);
  }

  /// Destroys all Views in this container.
  @override
  void clear() {
    for (var i = length - 1; i >= 0; i--) {
      remove(i);
    }
  }

  List<T> mapNestedViews<T, U extends DynamicView>(
    List<T> Function(U) callback,
  ) {
    final nestedViews = this.nestedViews;
    if (nestedViews == null || nestedViews.isEmpty) {
      return const <Null>[];
    }
    final result = <T>[];
    for (var i = 0, l = nestedViews.length; i < l; i++) {
      result.addAll(callback(unsafeCast<U>(nestedViews[i])));
    }
    return result;
  }

  Node _findRenderNode(List<DynamicView> views, int index) {
    return index > 0
        ? views[index - 1].viewFragment.findLastDomNode()
        : nativeElement;
  }

  void moveView(DynamicView view, int currentIndex) {
    final views = nestedViews;
    final previousIndex = views.indexOf(view);

    views.removeAt(previousIndex);
    views.insert(currentIndex, view);

    final refRenderNode = _findRenderNode(views, currentIndex);

    if (refRenderNode != null) {
      view.addRootNodesAfter(refRenderNode);
    }

    view.wasMoved();
  }

  void attachView(DynamicView view, int viewIndex) {
    final views = nestedViews ?? <DynamicView>[];
    views.insert(viewIndex, view);

    final refRenderNode = _findRenderNode(views, viewIndex);
    nestedViews = views;

    if (refRenderNode != null) {
      view.addRootNodesAfter(refRenderNode);
    }

    view.wasInserted(this);
  }

  DynamicView detachView(int viewIndex) {
    return nestedViews.removeAt(viewIndex)
      ..removeRootNodes()
      ..wasRemoved();
  }

  @override
  ComponentRef<T> loadNextTo<T>(
    ComponentFactory<T> component, {
    Injector injector,
  }) =>
      loadNextToLocation(component, this, injector: injector);
}
