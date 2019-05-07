import 'dart:html';

import 'package:angular/src/core/linker/views/render_view.dart';

/// Base class for helpers generated for some classes annotated with @Directive.
///
/// When a `@Directive`-annotated class has one or more `@HostBinding()`s those
/// bindings and/or are hoisted into the [detectHostChanges] method of this
/// class, and are re-used across the different call sites.
abstract class DirectiveChangeDetector {
  /// Implements `detectChanges()`-like logic but for the directive instance.
  ///
  /// Currently, this implements and updates `@HostBinding()`s only.
  void detectHostChanges(RenderView view, Element hostElement);
}
