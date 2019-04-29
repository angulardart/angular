import 'dart:html';

import 'package:meta/dart2js.dart' as dart2js;
import 'package:angular/src/core/linker/app_view_utils.dart';
import 'package:angular/src/core/linker/style_encapsulation.dart';
import 'package:angular/src/core/linker/view_container.dart';
import 'package:angular/src/core/linker/view_fragment.dart';
import 'package:angular/src/runtime.dart';
import 'package:angular/src/runtime/dom_helpers.dart';

import 'view.dart';

/// A view that renders DOM content.
abstract class RenderView extends View {
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

  /// Nodes that are given to this view by a parent view via content projection.
  ///
  /// A view will only attempt to _use_ this value if and only if it has at
  /// least one `<ng-content>` slot. These nodes are not created by the view
  /// itself but rather by the view's parent.
  List<Object> get projectedNodes;

  /// Equivalent to [addShimE], but optimized for [HtmlElement].
  @dart2js.noInline
  void addShimC(HtmlElement element) {
    final styles = componentStyles;
    if (styles.usesStyleEncapsulation) {
      updateClassBinding(element, styles.contentPrefix, true);
    }
  }

  /// Adds a content shim class to [element].
  ///
  /// This is only used if [componentStyles] are encapsulated, as the content
  /// shim class is needed for any styles to match [element].
  ///
  /// This should only be used for SVG or custom elements. For a plain
  /// [HtmlElement], use [addShimC] instead.
  @dart2js.noInline
  void addShimE(Element element) {
    final styles = componentStyles;
    if (styles.usesStyleEncapsulation) {
      updateClassBindingNonHtml(element, styles.contentPrefix, true);
    }
  }

  void Function(E) eventHandler0<E>(void Function() handler) {
    return (E event) {
      markForCheck();
      appViewUtils.eventManager.zone.runGuarded(handler);
    };
  }

  // When registering an event listener for a native DOM event, the return value
  // of this method is passed to EventTarget.addEventListener() which expects a
  // function that accepts an Event parameter. This means you can't directly
  // register an event listener for a specific subclass of Event, such as a
  // MouseEvent for the 'click' event. A workaround is possible by ensuring the
  // parameter of the event listener is a subclass of Event. The Event passed in
  // from EventTarget.addEventListener() can then be safely coerced back to its
  // known type.
  void Function(E) eventHandler1<E, F extends E>(void Function(F) handler) {
    assert(
        E == Null || F != Null,
        "Event handler '$handler' isn't assignable to expected type "
        "'($E) => void'");
    return (E event) {
      markForCheck();
      appViewUtils.eventManager.zone
          .runGuarded(() => handler(unsafeCast<F>(event)));
    };
  }

  /// Moves (appends) appropriate DOM [Node]s of [ViewData.projectedNodes].
  ///
  /// In the case of multiple `<ng-content>` slots [index] is used as the
  /// discriminator to determine which parts of the template are mapped to
  /// what parts of the DOM.
  @dart2js.noInline
  void project(Element target, int index) {
    // TODO: Determine in what case this is `null`.
    if (target == null) {
      return;
    }

    // TODO: Determine why this would be `null` or out of bounds.
    final projectedNodesByContentIndex = projectedNodes;
    if (projectedNodesByContentIndex == null ||
        index >= projectedNodesByContentIndex.length) {
      return;
    }

    // TODO: Also determine why this might be `null`.
    final nodesToProjectIntoTarget = unsafeCast<List<Object>>(
      projectedNodesByContentIndex[index],
    );
    if (nodesToProjectIntoTarget == null) {
      return;
    }

    // This is slightly duplicated with ViewFragment due to the fact that nodes
    // stored in the projection list are sometimes stored as a List and
    // sometimes not as an optimization.
    final length = nodesToProjectIntoTarget.length;
    for (var i = 0; i < length; i++) {
      final node = nodesToProjectIntoTarget[i];
      if (node is ViewContainer) {
        target.append(node.nativeElement);
        final nestedViews = node.nestedViews;
        if (nestedViews != null) {
          final length = nestedViews.length;
          for (var n = 0; n < length; n++) {
            nestedViews[n].addRootNodesToChildrenOf(target);
          }
        }
      } else if (node is List<Object>) {
        ViewFragment.appendDomNodes(target, node);
      } else {
        target.append(unsafeCast(node));
      }
    }

    domRootRendererIsDirty = true;
  }

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
