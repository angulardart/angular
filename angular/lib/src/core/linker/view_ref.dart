import 'dart:html';

import 'package:angular/src/core/change_detection/constants.dart'
    show ChangeDetectionStrategy;

import '../change_detection/change_detector_ref.dart' show ChangeDetectorRef;
import 'app_view.dart' show AppView;
import 'app_view_utils.dart';

abstract class ViewRef {
  bool get destroyed;

  void onDestroy(OnDestroyCallback callback);
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

  List<Node> get rootNodes;

  /// Destroys the view and all of the data structures associated with it.
  void destroy();

  /// Marks the node for change detection.
  void markForCheck();
}

class ViewRefImpl implements EmbeddedViewRef, ChangeDetectorRef {
  final AppView appView;

  ViewRefImpl(this.appView);

  @Deprecated('Use appView instead')
  AppView<dynamic> get internalView => appView;

  List<Node> get rootNodes => appView.flatRootNodes;

  ChangeDetectorRef get changeDetectorRef => this;

  void setLocal(String variableName, dynamic value) {
    appView.setLocal(variableName, value);
  }

  bool hasLocal(String variableName) => appView.hasLocal(variableName);

  bool get destroyed => appView.viewData.destroyed;

  @override
  void markForCheck() {
    appView.markPathToRootAsCheckOnce();
  }

  void detach() {
    appView.cdMode = ChangeDetectionStrategy.Detached;
  }

  void detectChanges() {
    appView.detectChanges();
  }

  void checkNoChanges() {
    AppViewUtils.enterThrowOnChanges();
    appView.detectChanges();
    AppViewUtils.exitThrowOnChanges();
  }

  void reattach() {
    appView.cdMode = ChangeDetectionStrategy.CheckAlways;
    markForCheck();
  }

  @override
  void onDestroy(OnDestroyCallback callback) {
    appView.addOnDestroyCallback(callback);
  }

  void destroy() {
    appView.detachAndDestroy();
  }
}
