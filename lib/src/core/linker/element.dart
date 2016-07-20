import "package:angular2/src/core/di.dart" show Injector;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

import "element_ref.dart";
import "query_list.dart" show QueryList;
import "app_view.dart";
import "view_container_ref.dart";
import "view_type.dart";

/// An AppElement is created for elements that have a ViewContainerRef,
/// a nested component or a <template> element to keep data around
/// that is needed for later instantiations.
class AppElement {
  num index;
  num parentIndex;
  AppView<dynamic> parentView;
  dynamic nativeElement;
  List<AppView<dynamic>> nestedViews = null;
  AppView<dynamic> componentView = null;
  dynamic component;
  List<QueryList<dynamic>> componentConstructorViewQueries;

  AppElement(this.index, this.parentIndex, this.parentView, this.nativeElement);

  ElementRef get elementRef => new ElementRef(nativeElement);

  ViewContainerRef get vcRef => new ViewContainerRef(this);

  void initComponent(
      dynamic component,
      List<QueryList<dynamic>> componentConstructorViewQueries,
      AppView<dynamic> view) {
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

  void attachView(AppView<dynamic> view, num viewIndex) {
    if (identical(view.type, ViewType.COMPONENT)) {
      throw new BaseException("Component views can't be moved!");
    }
    nestedViews ??= [];
    nestedViews.insert(viewIndex, view);
    var refRenderNode;
    if (viewIndex > 0) {
      var prevView = nestedViews[viewIndex - 1];
      refRenderNode = prevView.lastRootNode;
    } else {
      refRenderNode = this.nativeElement;
    }
    if (refRenderNode != null) {
      view.renderer.attachViewAfter(refRenderNode, view.flatRootNodes);
    }
    view.addToContentChildren(this);
  }

  AppView<dynamic> detachView(num viewIndex) {
    var view = this.nestedViews.removeAt(viewIndex);
    if (identical(view.type, ViewType.COMPONENT)) {
      throw new BaseException("Component views can't be moved!");
    }
    view.renderer.detachView(view.flatRootNodes);
    view.removeFromContentChildren(this);
    return view;
  }
}
