import "package:angular2/src/core/di.dart" show Injector;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

import "app_view.dart";
import "element_ref.dart";
import "query_list.dart" show QueryList;
import "view_container_ref.dart";
import "view_type.dart";

/// An AppElement is created for elements that have a ViewContainerRef,
/// a nested component or a <template> element to keep data around
/// that is needed for later instantiations.
class AppElement {
  final int index;
  final int parentIndex;
  final AppView parentView;
  final dynamic nativeElement;
  List<AppView> nestedViews;
  AppView componentView;
  dynamic component;
  List<QueryList> componentConstructorViewQueries;

  AppElement(this.index, this.parentIndex, this.parentView, this.nativeElement);

  ElementRef get elementRef => new ElementRef(nativeElement);

  ViewContainerRef get vcRef => new ViewContainerRef(this);

  void initComponent(dynamic component,
      List<QueryList> componentConstructorViewQueries, AppView view) {
    this.component = component;
    this.componentConstructorViewQueries = componentConstructorViewQueries;
    componentView = view;
  }

  Injector get parentInjector => parentView.injector(parentIndex);

  Injector get injector => parentView.injector(index);

  List<dynamic> mapNestedViews(dynamic nestedViewClass, Function callback) {
    var result = [];
    if (nestedViews != null) {
      nestedViews.forEach((nestedView) {
        if (identical(nestedView.clazz, nestedViewClass)) {
          result.add(callback(nestedView));
        }
      });
    }
    return result;
  }

  void moveView(AppView view, int currentIndex) {
    int previousIndex = nestedViews.indexOf(view);

    if (view.type == ViewType.COMPONENT) {
      throw new Exception("Component views can't be moved!");
    }

    List<AppView> views = nestedViews;

    if (views == null) {
      views = <AppView>[];
      nestedViews = views;
    }

    views.removeAt(previousIndex);
    views.insert(currentIndex, view);
    dynamic refRenderNode;

    if (currentIndex > 0) {
      AppView prevView = views[currentIndex - 1];
      refRenderNode = prevView.lastRootNode;
    } else {
      refRenderNode = nativeElement;
    }

    if (refRenderNode != null) {
      view.renderer.attachViewAfter(refRenderNode, view.flatRootNodes);
    }

    view.markContentChildAsMoved(this);
  }

  void attachView(AppView view, int viewIndex) {
    if (identical(view.type, ViewType.COMPONENT)) {
      throw new BaseException("Component views can't be moved!");
    }
    nestedViews ??= <AppView>[];
    nestedViews.insert(viewIndex, view);
    var refRenderNode;
    if (viewIndex > 0) {
      var prevView = nestedViews[viewIndex - 1];
      refRenderNode = prevView.lastRootNode;
    } else {
      refRenderNode = nativeElement;
    }
    if (refRenderNode != null) {
      view.renderer.attachViewAfter(refRenderNode, view.flatRootNodes);
    }
    view.addToContentChildren(this);
  }

  AppView detachView(int viewIndex) {
    var view = nestedViews.removeAt(viewIndex);
    if (view.type == ViewType.COMPONENT) {
      throw new BaseException("Component views can't be moved!");
    }
    view.renderer.detachView(view.flatRootNodes);
    view.removeFromContentChildren(this);
    return view;
  }
}
