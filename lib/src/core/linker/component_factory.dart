import "package:angular2/src/core/di.dart" show Injector;
import "package:angular2/src/core/reflection/reflection.dart" show reflector;

import "../change_detection/change_detection.dart" show ChangeDetectorRef;
import "element.dart" show AppElement;
import "element_ref.dart" show ElementRef;
import "view_ref.dart" show ViewRef;
import "view_utils.dart" show ViewUtils;

/// Represents an instance of a Component created via a [ComponentFactory].
///
/// [ComponentRef] provides access to the Component Instance as well other
/// objects related to this Component Instance and allows you to destroy the
/// Component Instance via the [#destroy] method.
abstract class ComponentRef {
  /// Location of the Host Element of this Component Instance.
  ElementRef get location;

  /// The injector on which the component instance exists.
  Injector get injector;

  /// The instance of the Component.
  dynamic get instance;

  /// The [ViewRef] of the Host View of this Component instance.
  ViewRef get hostView;

  /// The [ChangeDetectorRef] of the Component instance.
  ChangeDetectorRef get changeDetectorRef;

  /// The component type.
  Type get componentType;

  /// Destroys the component instance and all of the data structures associated
  /// with it.
  void destroy();

  /// Allows to register a callback that will be called when the component is
  /// destroyed.
  void onDestroy(Function callback);
}

class ComponentRef_ extends ComponentRef {
  final AppElement hostElement;
  final Type componentType;
  final List<dynamic> metadata;

  ComponentRef_(this.hostElement, this.componentType, this.metadata);

  ElementRef get location => hostElement.elementRef;

  Injector get injector => hostElement.injector;

  dynamic get instance => hostElement.component;

  ViewRef get hostView => hostElement.parentView.ref;

  ChangeDetectorRef get changeDetectorRef => hostElement.parentView.ref;

  void destroy() {
    hostElement.parentView.destroy();
  }

  void onDestroy(Function callback) {
    hostView.onDestroy(callback);
  }
}

class ComponentFactory {
  final String selector;
  final Function _viewFactory;
  final Type _componentType;
  final List<dynamic /* Type | List < dynamic > */ > _metadataPairs;
  static ComponentFactory cloneWithMetadata(
      ComponentFactory original, List<dynamic> metadata) {
    return new ComponentFactory(original.selector, original._viewFactory,
        original._componentType, [original.componentType, metadata]);
  }
  // Note: can't use a Map for the metadata due to

  // https://github.com/dart-lang/sdk/issues/21553
  const ComponentFactory(this.selector, this._viewFactory, this._componentType,
      [this._metadataPairs = null]);

  Type get componentType => _componentType;

  List get metadata {
    if (_metadataPairs == null) {
      return reflector.annotations(_componentType);
    }
    for (var i = 0; i < this._metadataPairs.length; i += 2) {
      if (identical(this._metadataPairs[i], this._componentType)) {
        return (this._metadataPairs[i + 1] as List);
      }
    }
    return [];
  }

  /// Creates a new component.
  ComponentRef create(Injector injector,
      [List<List<dynamic>> projectableNodes = null,
      dynamic /* String | dynamic */ rootSelectorOrNode = null]) {
    ViewUtils vu = injector.get(ViewUtils);
    projectableNodes ??= [];

    // Note: Host views don't need a declarationAppElement!
    var hostView = this._viewFactory(vu, injector, null);
    var hostElement = hostView.create(projectableNodes, rootSelectorOrNode);
    return new ComponentRef_(hostElement, this.componentType, this.metadata);
  }
}
