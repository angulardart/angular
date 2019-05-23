import 'dart:async';
import 'dart:html';

import 'package:meta/dart2js.dart' as dart2js;
import 'package:angular/src/core/linker/app_view_utils.dart';
import 'package:angular/src/core/linker/style_encapsulation.dart';
import 'package:angular/src/core/linker/view_container.dart';
import 'package:angular/src/core/linker/view_fragment.dart';
import 'package:angular/src/runtime.dart';
import 'package:angular/src/runtime/dom_helpers.dart';

import 'view.dart';

/// A view that renders a portion of a component template.
///
/// The responsibilities of this view include:
///
///   * Rendering the DOM defined in the template. This includes applying
///   encapsulation classes if the component uses style encapsulation.
///
///   * Initializing each directive used in the template.
///
///   * Initializing each component used in the template, and its associated
///   component view.
///
///   * Making any services provided by the directives and components in this
///   view available for injection to their respective host and descendants.
///
///   * Updating any expression bindings that changed in the template during
///   change detection, and invoking change detection on nested views.
///
///   * Invoking any life cycle interfaces implemented by components in this
///   view at the appropriate times.
///
///   * Attaching any projected content that matches an `<ng-content>` slot
///   declared the template at its corresponding location (the `<ng-content>`
///   tag itself is never rendered).
///
/// Note that generated views should never extend this class directly, but
/// rather one of its specializations.
abstract class RenderView extends View {
  /// The context in which expressions bound in this view are evaluated.
  ///
  /// This is the component instance whose template corresponds to this view.
  /// Implementations should override the type, which is intentionally omitted
  /// here to avoid the cost of reifying this type wherever used (which
  /// dramatically reduces code size).
  Object get ctx;

  /// This view's compiled CSS styles and style encapsulation information.
  ComponentStyles get componentStyles;

  /// Nodes that are given to this view by a parent view via content projection.
  ///
  /// A view will only attempt to _use_ this value if and only if it has at
  /// least one `<ng-content>` slot. These nodes are not created by the view
  /// itself but rather by the view's parent.
  List<Object> get projectedNodes;

  // Initialization ------------------------------------------------------------

  /// Moves (appends) appropriate DOM [Node]s of [ViewData.projectedNodes].
  ///
  /// In the case of multiple `<ng-content>` slots [index] is used as the
  /// discriminator to determine which parts of the template are mapped to
  /// what parts of the DOM.
  @dart2js.noInline
  void project(Element target, int index) {
    // TODO(b/132111830): Determine in what case this is `null`.
    if (target == null) {
      return;
    }

    // TODO(b/132111830): Determine why this would be `null` or out of bounds.
    final projectedNodesByContentIndex = projectedNodes;
    if (projectedNodesByContentIndex == null ||
        index >= projectedNodesByContentIndex.length) {
      return;
    }

    // TODO(b/132111830): Also determine why this might be `null`.
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
            nestedViews[n].viewFragment.appendDomNodesInto(target);
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

  // Dependency injection ------------------------------------------------------

  @override
  Object injectFromAncestry(Object token, Object notFoundValue) =>
      parentView.inject(token, parentIndex, notFoundValue);

  // Change detection ----------------------------------------------------------

  /// Wraps [handler] so that when invoked, this view gets change detected.
  ///
  /// The wrapped handler does two things:
  ///
  ///   * Ensures the original [handler] is executed inside the Angular zone so
  ///   that a change detection cycle is triggered. This also ensures that any
  ///   asynchronous work scheduled by [handler] is also run inside the Angular
  ///   zone, triggering subsequent change detection cycles.
  ///
  ///   * Calls [markForCheck] on this view to ensure it gets change detected
  ///   during the next change detection cycle, in case it uses a non-default
  ///   change detection strategy.
  void Function(E) eventHandler0<E>(void Function() handler) {
    return (E event) {
      markForCheck();
      appViewUtils.eventManager.zone.runGuarded(handler);
    };
  }

  /// The same as [eventHandler0], but [handler] is passed an event parameter.
  ///
  /// This is used anytime the user binds an event listener with an [Event]
  /// parameter, or references the `$event` variable inside an event handler in
  /// a template.
  ///
  /// When registering an event listener for a native DOM event, the return
  /// value of this method is passed to [EventTarget.addEventListener] which
  /// expects an [EventListener]. This means you can't directly register an
  /// event listener for a specific subclass of [Event], such as a [MouseEvent]
  /// for the 'click' event. A workaround is possible by ensuring the parameter
  /// of the event listener is a subclass of [Event]. The [Event] passed in from
  /// [EventTarget.addEventListener] can then be safely coerced back to its
  /// known type.
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

  // Styling -------------------------------------------------------------------

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

  /// Called by change detector to apply correct host and content shimming
  /// after node's className is changed.
  ///
  /// Used by [detectChanges] when changing [element.className] directly.
  ///
  /// For example, through the `[class]="..."` or `[attr.class]="..."` syntax.
  @dart2js.noInline
  void updateChildClass(HtmlElement element, String newClass) {
    final styles = componentStyles;
    final shim = styles.usesStyleEncapsulation;
    element.className = shim ? '$newClass ${styles.contentPrefix}' : newClass;
  }

  /// Similar to [updateChildClass], for an [element] not guaranteed to be HTML.
  @dart2js.noInline
  void updateChildClassNonHtml(Element element, String newClass) {
    final styles = componentStyles;
    final shim = styles.usesStyleEncapsulation;
    updateAttribute(element, 'class',
        shim ? '$newClass ${styles.contentPrefix}' : newClass);
  }
}

/// The interface for [RenderView] data bundled together as an optimization.
///
/// Similar to [ViewData], this interface exists solely as a common point for
/// documentation.
abstract class RenderViewData implements ViewData {
  /// Storage for [View.parentView].
  View get parentView;

  /// Storage for [View.parentIndex].
  int get parentIndex;

  /// Storage for [RenderView.projectedNodes].
  List<Object> get projectedNodes;

  /// Storage for subscriptions to any outputs in this view.
  ///
  /// These are cancelled when this is [destroyed].
  List<StreamSubscription<void>> get subscriptions;
}
