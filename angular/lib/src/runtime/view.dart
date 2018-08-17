/// Proposal for generated application views for components and templates.
///
/// Not currently used in production.
///
/// See: https://github.com/dart-lang/angular/issues/1421
library angular.src.runtime.view;

import 'dart:html' show HtmlElement;

import 'package:meta/meta.dart' show mustCallSuper, protected;

import 'optimizations.dart';

/// Base generated view for components and templates.
abstract class View<T> {
  /// Runs change detection, updating the view and children based on context.
  @mustCallSuper
  void detectChanges() {}
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
  /// Root element used as the root element for the component view.
  @protected
  final HtmlElement rootElement;

  ComponentView(
    T context,
    this.rootElement,
  ) : super(context);
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
  ) : super(context);

  /// Gets access to the locally declared variable [name].
  @protected
  S getLocal<S>(String name) => unsafeCast(name);

  /// Sets the locally declared variable [name] to [value].
  @protected
  void setLocal<S>(String name, S value) => _locals[name] = value;
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

  HostView(
    this.componentView,
  );
}
