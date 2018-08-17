/// Proposal for generated application views for components and templates.
///
/// Not currently used in production.
///
/// See: https://github.com/dart-lang/angular/issues/1421
library angular.src.runtime.view;

import 'dart:html' show HtmlElement;

import 'package:meta/meta.dart' show mustCallSuper, protected;

import '../core/linker/view_container.dart';
import '../di/injector/injector.dart';
import 'optimizations.dart';

/// Base generated view for components and templates.
abstract class View<T> {
  /// Runs change detection, updating the view and children based on context.
  @mustCallSuper
  void detectChanges() {}

  /// Destroys this view and disposes of any resources or child views.
  @mustCallSuper
  void destroy() {}
}

/// Base generated view for views that have a parent [ComponentView].
abstract class ChildView<T> extends View<T> {
  /// Concrete component `class` instance [T].
  final T context;

  ChildView(this.context);
}

/// Root application view for a given component class [T].
///
/// For example given:
/// ```dart
/// @Component(...)
/// class A {}
/// ```
///
/// ... would generate:
///
/// ```dart
/// class _ComponentView$A extends ComponentView<A> {}
/// ```
abstract class ComponentView<T> extends ChildView<T> {
  /// Child views (embedded or components).
  @protected
  final List<View<void>> childViews;

  /// Root element used as the root element for the component view.
  @protected
  final HtmlElement rootElement;

  ComponentView(
    T context,
    this.childViews,
    this.rootElement,
  ) : super(context);

  @mustCallSuper
  @override
  void destroy() {
    destroyChildViews();
    super.destroy();
  }

  @mustCallSuper
  @protected
  void destroyChildViews() {
    for (final childView in childViews) {
      childView.destroy();
    }
  }
}

/// Nested embedded view for `<template>` views inside of a component [T].
///
/// Any time a `<template>` tag is inserted into the template of a _component_
/// (explicitly, or implicitly via `*`-directives, `<ng-container>`, or
/// annotations like `@deferred`), an [EmbeddedView] is created.
///
/// For example given:
/// ```dart
/// @Component(
///   template: r'''
///     <template [ngIf]="condition">...</template>
///   ''',
/// )
/// class A {}
/// ```
///
/// ... would generate:
///
/// ```dart
/// class _EmbeddedView_0_NgIf$A extends EmbeddedView<A> {}
/// ```
abstract class EmbeddedView<T> extends ChildView<T> {
  @protected
  final ComponentView<T> componentView;

  final Map<String, dynamic> _locals = Map.identity();

  EmbeddedView(
    T context,
    this.componentView,
  ) : super(
          context,
        );

  /// Gets access to the locally declared variable [name].
  @protected
  S getLocal<S>(String name) => unsafeCast(name);

  /// Sets the locally declared variable [name] to [value].
  @protected
  void setLocal<S>(String name, S value) => _locals[name] = value;
}

/// Nested [EmbeddedView] that also contains a [ViewContainer].
abstract class ContainerView<T> extends EmbeddedView<T> {
  @protected
  final ViewContainer viewContainer;

  ContainerView(
    T context,
    ComponentView<T> componentView,
    this.viewContainer,
  ) : super(
          context,
          componentView,
        );

  @mustCallSuper
  @override
  void destroy() {
    viewContainer.destroyNestedViews();
    super.destroy();
  }
}

/// Root application view for dynamically creating a component class [T].
///
/// A [HostView] exists to be a _wrapper_ around a given [ComponentView], which
/// contains enough information to dynamically create the component (and request
/// its dependencies) when created.
///
/// For example given:
/// ```dart
/// @Component(...)
/// class A {}
/// ```
///
/// ... would generate:
///
/// ```dart
/// class _HostView$A extends HostView<A> {}
/// ```
abstract class HostView<T> extends View<T> {
  /// Which [ComponentView] is managed directly by this [HostView]/
  @protected
  final ComponentView<T> componentView;

  /// Context where the hosted view was created within.
  @protected
  final Injector hostInjector;

  HostView(
    this.componentView,
    this.hostInjector,
  );
}
