import 'app_view.dart';
import 'element_ref.dart';
import 'view_container.dart';
import 'view_ref.dart' show EmbeddedViewRef;

/// Represents an Embedded Template that can be used to instantiate Embedded
/// Views.
///
/// You can access a `TemplateRef`, in two ways. Via a directive placed on a
/// `<template>` element (or directive prefixed with `*`) and have the
/// `TemplateRef` for this Embedded View injected into the constructor of the
/// directive using the `TemplateRef` Token. Alternatively you can query for the
/// `TemplateRef` from a Component or a Directive via [Query].
///
/// To instantiate Embedded Views based on a Template, use
/// [ViewContainerRef#createEmbeddedView], which will create the View and attach
/// it to the View Container.
class TemplateRef {
  final ViewContainer _viewContainer;
  final Function _viewFactory;

  TemplateRef(this._viewContainer, this._viewFactory);

  EmbeddedViewRef createEmbeddedView() {
    AppView parentView = _viewContainer.parentView;
    AppView view = _viewFactory(parentView, _viewContainer.index);
    view.create(parentView.ctx, parentView.viewData.projectableNodes);
    return view.viewData.ref;
  }

  /// The location in the View where the Embedded View logically belongs to.
  ///
  /// The data-binding and injection contexts of Embedded Views created from
  /// this `TemplateRef` inherit from the contexts of this location.
  ///
  /// Typically new Embedded Views are attached to the View Container of this
  /// location, but in advanced use-cases, the View can be attached to a
  /// different container while keeping the data-binding and injection context
  /// from the original location.
  ElementRef get elementRef => _viewContainer.elementRef;
}
