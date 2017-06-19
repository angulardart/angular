/// What type of generated `AppView` an instance is.
enum ViewType {
  /// A view that contains the host element with bound component directive.
  ///
  /// Contains a `@Component`'s root element.
  HOST,

  /// The view of `@Component` that contains 0 to n _embedded_ views.
  COMPONENT,

  /// A view that is embedded into another view via a `<template>` element.
  ///
  /// These are only inside a [COMPONENT] view.
  EMBEDDED
}
