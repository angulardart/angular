import 'view_container.dart';
import 'views/render_view.dart';

/// Represents a reference to an `<ng-content>` element.
///
/// This can be used to query whether an `<ng-content>` has any projected nodes.
/// Users can access this class via a direct reference in the template, or a
/// view query.
///
/// ```
/// @Component(
///   selector: 'comp',
///   template: '''
///     <ng-content #projectedContent></ng-content>
///     <div *ngIf="!projectedContent.hasContent">
///       There was no projected content. Here is some default content!
///     </div>
///   ''',
/// )
/// class FooComponent {
///   @ViewChild(NgContentRef)
///   NgContentRef child;
/// }
class NgContentRef {
  final RenderView _renderView;
  final int _index;

  NgContentRef(this._renderView, this._index);

  /// Returns whether this has any projected nodes.
  bool get hasContent {
    final nodesToProject = _renderView.projectedNodes[_index];
    for (var i = 0; i < nodesToProject.length; i++) {
      final node = nodesToProject[i];
      // Check for views inserted dynamically by a directive (such as *ngIf or
      // *ngFor).
      if (node is ViewContainer) {
        final nestedViews = node.nestedViews;
        if (nestedViews != null && nestedViews.isNotEmpty) {
          return true;
        }
      } else {
        return true;
      }
    }
    return false;
  }
}
