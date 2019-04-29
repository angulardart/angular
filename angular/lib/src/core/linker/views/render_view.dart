import 'dart:html';

import 'package:angular/src/core/linker/style_encapsulation.dart';

import 'view.dart';

/// An interface for views that render DOM content.
abstract class RenderView implements View {
  /// The context in which expressions bound in this view are evaluated.
  ///
  /// This is the component instance whose template corresponds to this view.
  /// Implementations should override the type, which is intentionally omitted
  /// here to avoid the cost of reifying this type wherever used (which
  /// dramatically reduces code size).
  Object get ctx;

  /// This view's CSS styles.
  ComponentStyles get componentStyles;

  /// Returns whether this is the first change detection pass.
  // TODO(b/129479956): remove after directive change detectors are removed.
  bool get firstCheck;

  /// The index of this view within its [parentView].
  int get parentIndex;

  /// This view's parent view.
  // TODO(b/130375490): a component view's parent shouldn't be a `RenderView`.
  RenderView get parentView;

  /// Equivalent to [addShimE], but optimized for [HtmlElement].
  void addShimC(HtmlElement element);

  /// Adds a content shim class to [element].
  ///
  /// This is only used if [componentStyles] are encapsulated, as the content
  /// shim class is needed for any styles to match [element].
  ///
  /// This should only be used for SVG or custom elements. For a plain
  /// [HtmlElement], use [addShimC] instead.
  void addShimE(Element element);

  /// Called by change detector to apply correct host and content shimming
  /// after node's className is changed.
  ///
  /// Used by [detectChanges] when changing [element.className] directly.
  ///
  /// For example, through the `[class]="..."` or `[attr.class]="..."` syntax.
  void updateChildClass(HtmlElement element, String newClass);

  /// Similar to [updateChildClass], for an [element] not guaranteed to be HTML.
  void updateChildClassNonHtml(Element element, String newClass);
}
