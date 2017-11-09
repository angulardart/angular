import 'package:angular/src/di/injector/injector.dart' show Injector;

import 'component_factory.dart' show ComponentFactory, ComponentRef;
import 'component_loader.dart';
import 'element_ref.dart';
import 'template_ref.dart';
import 'view_ref.dart' show EmbeddedViewRef, ViewRef;

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
abstract class ViewContainerRef implements ComponentLoader {
  /// Returns the [ViewRef] for the View located in this container at the
  /// specified index.
  EmbeddedViewRef get(int index);

  /// Returns the number of Views currently attached to this container.
  int get length;

  /// Anchor element that specifies the location of this container in the
  /// containing View.
  ElementRef get element;

  Injector get injector;

  Injector get parentInjector;

  /// Instantiates an Embedded View based on the [TemplateRef `templateRef`]
  /// and inserts it into this container at the specified `index`.
  ///
  /// If `index` is not specified, the new View will be inserted as the last
  /// View in the container.
  ///
  /// Returns the [ViewRef] for the newly created View.
  EmbeddedViewRef insertEmbeddedView(TemplateRef templateRef, int index);

  /// Instantiates an Embedded View based on the [TemplateRef `templateRef`]
  /// and appends it into this container.
  EmbeddedViewRef createEmbeddedView(TemplateRef templateRef);

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
  ComponentRef<T> createComponent<T>(
    ComponentFactory<T> componentFactory, [
    int index = -1,
    Injector injector,
    List<List<dynamic>> projectableNodes,
  ]);

  /// Inserts a View identified by a [ViewRef] into the container.
  ///
  /// If `index` is not specified, the new View will be inserted as the
  /// last View in the container.
  ///
  /// Returns the inserted [ViewRef].
  /// TODO(i): refactor insert+remove into move
  ViewRef insert(ViewRef viewRef, [int index = -1]);

  ViewRef move(ViewRef viewRef, int currentIndex);

  /// Returns the index of the View, specified via [ViewRef], within the current
  /// container or `-1` if this container doesn't contain the View.
  int indexOf(ViewRef viewRef);

  /// Destroys a View attached to this container at the specified `index`.
  ///
  /// If `index` is not specified, the last View in the container will be
  /// removed.
  /// TODO(i): rename to destroy
  void remove([int index = -1]);

  /// Use along with [#insert] to move a View within the current container.
  ///
  /// If the `index` param is omitted, the last [ViewRef] is detached.
  /// TODO(i): refactor insert+remove into move
  ViewRef detach([int index = -1]);

  /// Destroys all Views in this container.
  void clear();
}
