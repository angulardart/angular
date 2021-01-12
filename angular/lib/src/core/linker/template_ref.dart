import 'package:angular/src/utilities.dart';

import 'view_container.dart';
import 'view_ref.dart' show EmbeddedViewRef;
import 'views/embedded_view.dart';
import 'views/render_view.dart';

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
  final EmbeddedView<void> Function(RenderView, int) _viewFactory;

  TemplateRef(this._viewContainer, this._viewFactory);

  /// Instantiates an instance of the provided template.
  EmbeddedViewRef createEmbeddedView() {
    // The unsafe cast is necessary because a view container's parent may be any
    // kind of view, but this method is only ever called when the parent view is
    // a `RenderView`.
    final parentView = unsafeCast<RenderView>(_viewContainer.parentView);
    final view = _viewFactory(parentView, _viewContainer.index);
    view.create();
    return view;
  }
}
