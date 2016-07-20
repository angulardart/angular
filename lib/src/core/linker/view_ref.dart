library angular2.src.core.linker.view_ref;

import "package:angular2/src/core/change_detection/constants.dart"
    show ChangeDetectionStrategy;

import "../change_detection/change_detector_ref.dart" show ChangeDetectorRef;
import "view.dart" show AppView;

abstract class ViewRef {
  bool get destroyed;

  onDestroy(Function callback);
}

/**
 * Represents an Angular View.
 *
 * <!-- TODO: move the next two paragraphs to the dev guide -->
 * A View is a fundamental building block of the application UI. It is the smallest grouping of
 * Elements which are created and destroyed together.
 *
 * Properties of elements in a View can change, but the structure (number and order) of elements in
 * a View cannot. Changing the structure of Elements can only be done by inserting, moving or
 * removing nested Views via a [ViewContainerRef]. Each View can contain many View Containers.
 * <!-- /TODO -->
 *
 * ### Example
 *
 * Given this template...
 *
 * ```
 * Count: {{items.length}}
 * <ul>
 *   <li *ngFor="let  item of items">{{item}}</li>
 * </ul>
 * ```
 *
 * ... we have two [ProtoViewRef]s:
 *
 * Outer [ProtoViewRef]:
 * ```
 * Count: {{items.length}}
 * <ul>
 *   <template ngFor let-item [ngForOf]="items"></template>
 * </ul>
 * ```
 *
 * Inner [ProtoViewRef]:
 * ```
 *   <li>{{item}}</li>
 * ```
 *
 * Notice that the original template is broken down into two separate [ProtoViewRef]s.
 *
 * The outer/inner [ProtoViewRef]s are then assembled into views like so:
 *
 * ```
 * <!-- ViewRef: outer-0 -->
 * Count: 2
 * <ul>
 *   <template view-container-ref></template>
 *   <!-- ViewRef: inner-1 --><li>first</li><!-- /ViewRef: inner-1 -->
 *   <!-- ViewRef: inner-2 --><li>second</li><!-- /ViewRef: inner-2 -->
 * </ul>
 * <!-- /ViewRef: outer-0 -->
 * ```
 */
abstract class EmbeddedViewRef extends ViewRef {
  /**
   * Sets `value` of local variable called `variableName` in this View.
   */
  void setLocal(String variableName, dynamic value);
  /**
   * Checks whether this view has a local variable called `variableName`.
   */
  bool hasLocal(String variableName);
  List<dynamic> get rootNodes;

  /**
   * Destroys the view and all of the data structures associated with it.
   */
  destroy();
}

class ViewRef_ implements EmbeddedViewRef, ChangeDetectorRef {
  AppView<dynamic> _view;
  ViewRef_(this._view) {
    this._view = _view;
  }
  AppView<dynamic> get internalView {
    return this._view;
  }

  List<dynamic> get rootNodes {
    return this._view.flatRootNodes;
  }

  ChangeDetectorRef get changeDetectorRef {
    return this;
  }

  void setLocal(String variableName, dynamic value) {
    this._view.setLocal(variableName, value);
  }

  bool hasLocal(String variableName) {
    return this._view.hasLocal(variableName);
  }

  bool get destroyed {
    return this._view.destroyed;
  }

  void markForCheck() {
    this._view.markPathToRootAsCheckOnce();
  }

  void detach() {
    this._view.cdMode = ChangeDetectionStrategy.Detached;
  }

  void detectChanges() {
    this._view.detectChanges(false);
  }

  void checkNoChanges() {
    this._view.detectChanges(true);
  }

  void reattach() {
    this._view.cdMode = ChangeDetectionStrategy.CheckAlways;
    this.markForCheck();
  }

  onDestroy(Function callback) {
    this._view.disposables.add(callback);
  }

  destroy() {
    this._view.destroy();
  }
}
