library angular2.src.core.linker.component_factory;

import "package:angular2/src/core/di.dart" show Injector;
import "package:angular2/src/facade/lang.dart" show Type, isPresent, isBlank;
import "package:angular2/src/facade/exceptions.dart" show unimplemented;
import "element_ref.dart" show ElementRef;
import "view_ref.dart" show ViewRef, ViewRef_;
import "element.dart" show AppElement;
import "view_utils.dart" show ViewUtils;
import "../change_detection/change_detection.dart" show ChangeDetectorRef;

/**
 * Represents an instance of a Component created via a [ComponentFactory].
 *
 * `ComponentRef` provides access to the Component Instance as well other objects related to this
 * Component Instance and allows you to destroy the Component Instance via the [#destroy]
 * method.
 */
abstract class ComponentRef {
  /**
   * Location of the Host Element of this Component Instance.
   */
  ElementRef get location {
    return unimplemented();
  }

  /**
   * The injector on which the component instance exists.
   */
  Injector get injector {
    return unimplemented();
  }

  /**
   * The instance of the Component.
   */
  dynamic get instance {
    return unimplemented();
  }

  /**
   * The [ViewRef] of the Host View of this Component instance.
   */
  ViewRef get hostView {
    return unimplemented();
  }

  /**
   * The [ChangeDetectorRef] of the Component instance.
   */
  ChangeDetectorRef get changeDetectorRef {
    return unimplemented();
  }

  /**
   * The component type.
   */
  Type get componentType {
    return unimplemented();
  }

  /**
   * Destroys the component instance and all of the data structures associated with it.
   */
  void destroy();
  /**
   * Allows to register a callback that will be called when the component is destroyed.
   */
  void onDestroy(Function callback);
}

class ComponentRef_ extends ComponentRef {
  AppElement _hostElement;
  Type _componentType;
  ComponentRef_(this._hostElement, this._componentType) : super() {
    /* super call moved to initializer */;
  }
  ElementRef get location {
    return this._hostElement.elementRef;
  }

  Injector get injector {
    return this._hostElement.injector;
  }

  dynamic get instance {
    return this._hostElement.component;
  }

  ViewRef get hostView {
    return this._hostElement.parentView.ref;
  }

  ChangeDetectorRef get changeDetectorRef {
    return this._hostElement.parentView.ref;
  }

  Type get componentType {
    return this._componentType;
  }

  void destroy() {
    this._hostElement.parentView.destroy();
  }

  void onDestroy(Function callback) {
    this.hostView.onDestroy(callback);
  }
}

class ComponentFactory {
  final String selector;
  final Function _viewFactory;
  final Type _componentType;
  const ComponentFactory(this.selector, this._viewFactory, this._componentType);
  Type get componentType {
    return this._componentType;
  }

  /**
   * Creates a new component.
   */
  ComponentRef create(Injector injector,
      [List<List<dynamic>> projectableNodes = null,
      dynamic /* String | dynamic */ rootSelectorOrNode = null]) {
    ViewUtils vu = injector.get(ViewUtils);
    if (isBlank(projectableNodes)) {
      projectableNodes = [];
    }
    // Note: Host views don't need a declarationAppElement!
    var hostView = this._viewFactory(vu, injector, null);
    var hostElement = hostView.create(projectableNodes, rootSelectorOrNode);
    return new ComponentRef_(hostElement, this._componentType);
  }
}
