import 'package:angular/src/di/injector.dart' show Injector;

import 'component_factory.dart' show ComponentFactory, ComponentRef;
import 'component_loader.dart';
import 'element_ref.dart';
import 'template_ref.dart';
import 'view_ref.dart' show EmbeddedViewRef, ViewRef;

/// Represents a container where one or more views can be attached.
///
/// The container can contain two kinds of views. Host views, created by
/// instantiating a [ComponentFactory] via [createComponent], and embedded
/// views, created by instantiating an [TemplateRef] via [createEmbeddedView].
///
/// The location of the view container within the containing view is specified
/// by the anchor [element]. Each view container can have only one anchor
/// element and each anchor element can only have a single view container.
///
/// Root elements of views attached to this container become siblings of the
/// anchor element in the rendered view.
///
/// To access a [ViewContainerRef] of an `Element`, you can either place a
/// `@Directive` injected with [ViewContainerRef] on the `Element`, or obtain
/// it via a `@ViewChild` query.
abstract class ViewContainerRef implements ComponentLoader {
  /// Returns the view located in this container at the specified [index].
  ViewRef get(int index);

  /// Returns the number of views currently attached to this container.
  int get length;

  /// Anchor element (the location of this container in the containing view).
  ElementRef get element;

  /// Injector context for the view container within the larger app.
  Injector get injector;

  /// The parent injector context.
  Injector get parentInjector;

  /// Instantiates [templateRef] and inserts it into this container at [index].
  ///
  /// If [index] is not specified, the new view will be inserted as the last
  /// View in the container.
  ///
  /// Returns the newly created view.
  EmbeddedViewRef insertEmbeddedView(TemplateRef templateRef, [int index = -1]);

  /// Instantiates [templateRef] and appends it into this container.
  ///
  /// Returns the newly created view.
  EmbeddedViewRef createEmbeddedView(TemplateRef templateRef);

  /// Instantiates a single component and inserts its host view into this
  /// container at the specified [index].
  ///
  /// The component is instantiated using its [ComponentFactory].
  ///
  /// If [index] is not specified, the new view will be inserted as the last
  /// View in the container.
  ///
  /// You can optionally specify the [Injector] that will be used as parent for
  /// the component.
  ///
  /// Returns the [ComponentRef] of the host view created for the newly
  /// instantiated component.
  ComponentRef<T> createComponent<T extends Object>(
    ComponentFactory<T> componentFactory, [
    int index = -1,
    Injector? injector,
    List<List<Object>>? projectableNodes,
  ]);

  /// Inserts a View identified by a [ViewRef] into the container.
  ///
  /// If [index] is not specified, the new View will be inserted as the
  /// last view in the container.
  ///
  /// Returns the inserted [ViewRef].
  ViewRef insert(ViewRef viewRef, [int index = -1]);

  /// Moves the provided [viewRef] into the specified [index].
  ///
  /// If [index] is not specified, the existing view will be moved to be the
  /// last view in the container.
  void move(ViewRef viewRef, [int index = -1]);

  /// Returns the index of the attached [viewRef].
  ///
  /// Returns `-1` if this container doesn't contain the provided view.
  int indexOf(ViewRef viewRef);

  /// Removes the view attached to this container at the specified [index].
  ///
  /// If [index] is not specified, the last View in the container will be
  /// removed.
  ///
  /// NOTE: In the process of removing the view, the view is also destroyed.
  void remove([int index = -1]);

  /// Use along with [insert] to move a view within the current container.
  ///
  /// If the `index` parameter is omitted, the last [ViewRef] is detached.
  ViewRef detach([int index = -1]);

  /// Destroys all views in this container.
  void clear();
}
