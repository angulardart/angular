import "element.dart" show AppElement;
import "element_ref.dart" show ElementRef;
import "view.dart" show AppView;
import "view_ref.dart" show EmbeddedViewRef;

/**
 * Represents an Embedded Template that can be used to instantiate Embedded Views.
 *
 * You can access a `TemplateRef`, in two ways. Via a directive placed on a `<template>` element (or
 * directive prefixed with `*`) and have the `TemplateRef` for this Embedded View injected into the
 * constructor of the directive using the `TemplateRef` Token. Alternatively you can query for the
 * `TemplateRef` from a Component or a Directive via [Query].
 *
 * To instantiate Embedded Views based on a Template, use
 * [ViewContainerRef#createEmbeddedView], which will create the View and attach it to the
 * View Container.
 */
abstract class TemplateRef {
  /**
   * The location in the View where the Embedded View logically belongs to.
   *
   * The data-binding and injection contexts of Embedded Views created from this `TemplateRef`
   * inherit from the contexts of this location.
   *
   * Typically new Embedded Views are attached to the View Container of this location, but in
   * advanced use-cases, the View can be attached to a different container while keeping the
   * data-binding and injection context from the original location.
   *
   */

  // TODO(i): rename to anchor or location
  ElementRef get elementRef {
    return null;
  }

  EmbeddedViewRef createEmbeddedView();
}

class TemplateRef_ extends TemplateRef {
  AppElement _appElement;
  Function _viewFactory;
  TemplateRef_(this._appElement, this._viewFactory) : super() {
    /* super call moved to initializer */;
  }
  EmbeddedViewRef createEmbeddedView() {
    AppView<dynamic> view = this._viewFactory(
        this._appElement.parentView.viewUtils,
        this._appElement.parentInjector,
        this._appElement);
    view.create(null, null);
    return view.ref;
  }

  ElementRef get elementRef {
    return this._appElement.elementRef;
  }
}
