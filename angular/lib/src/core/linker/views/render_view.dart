import 'dart:html';

import 'package:angular/src/core/linker/style_encapsulation.dart';

import 'view.dart';

/// An interface for views that render DOM content.
abstract class RenderView implements View {
  /// This view's CSS styles.
  ComponentStyles get componentStyles;

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
}
