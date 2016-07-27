import "package:angular2/src/core/change_detection/constants.dart"
    show ChangeDetectionStrategy;
import "package:angular2/src/core/linker/view_utils.dart";

import "../change_detection/change_detector_ref.dart" show ChangeDetectorRef;
import "view.dart" show AppView;

abstract class ViewRef {
  bool get destroyed;

  onDestroy(Function callback);
}

/// Represents an Angular View.
///
/// A View is a fundamental building block of the application UI. It is the
/// smallest grouping of Elements which are created and destroyed together.
///
/// Properties of elements in a View can change, but the structure (number
/// and order) of elements in a View cannot. Changing the structure of Elements
/// can only be done by inserting, moving or removing nested Views via a
/// [ViewContainerRef]. Each View can contain many View Containers.
///
/// ### Example
///
/// Given this template...
///
///     Count: {{items.length}}
///     <ul>
///       <li///ngFor="let  item of items">{{item}}</li>
///     </ul>
///
///     ... we have two [ProtoViewRef]s:
///
///     Outer [ProtoViewRef]:
///     Count: {{items.length}}
///     <ul>
///       <template ngFor let-item [ngForOf]="items"></template>
///     </ul>
///
///     Inner [ProtoViewRef]:
///       <li>{{item}}</li>
///
/// Notice that the original template is broken down into two separate
/// [ProtoViewRef]s.
///
/// The outer/inner [ProtoViewRef]s are then assembled into views like so:
///
/// <!-- ViewRef: outer-0 -->
/// Count: 2
/// <ul>
///   <template view-container-ref></template>
///   <!-- ViewRef: inner-1 --><li>first</li><!-- /ViewRef: inner-1 -->
///   <!-- ViewRef: inner-2 --><li>second</li><!-- /ViewRef: inner-2 -->
/// </ul>
/// <!-- /ViewRef: outer-0 -->
///
abstract class EmbeddedViewRef extends ViewRef {
  /// Sets [value] of local variable called [variableName] in this View.
  void setLocal(String variableName, dynamic value);

  /// Checks whether this view has a local variable called [variableName].
  bool hasLocal(String variableName);

  List<dynamic> get rootNodes;

  /// Destroys the view and all of the data structures associated with it.
  destroy();
}

class ViewRef_ implements EmbeddedViewRef, ChangeDetectorRef {
  final AppView<dynamic> _view;

  ViewRef_(this._view);

  AppView<dynamic> get internalView => _view;

  List get rootNodes => _view.flatRootNodes;

  ChangeDetectorRef get changeDetectorRef => this;

  void setLocal(String variableName, dynamic value) {
    _view.setLocal(variableName, value);
  }

  bool hasLocal(String variableName) => _view.hasLocal(variableName);

  bool get destroyed => _view.destroyed;

  void markForCheck() {
    _view.markPathToRootAsCheckOnce();
  }

  void detach() {
    _view.cdMode = ChangeDetectionStrategy.Detached;
  }

  void detectChanges() {
    _view.detectChanges();
  }

  void checkNoChanges() {
    ViewUtils.enterThrowOnChanges();
    _view.detectChanges();
    ViewUtils.exitThrowOnChanges();
  }

  void reattach() {
    _view.cdMode = ChangeDetectionStrategy.CheckAlways;
    markForCheck();
  }

  onDestroy(Function callback) {
    _view.disposables.add(callback);
  }

  destroy() {
    _view.destroy();
  }
}
