import 'view_container.dart';
import 'views/render_view.dart';

/// Represents a reference to an `<ng-content>` element.
///
/// This can be used to query whether an `<ng-content>` has any projected nodes.
///
/// ```
/// <ng-content #projectedContent></ng-content>
/// <div *ngIf="projectedContent.isEmpty">
///   There was no projected content. Here is some default content!
/// </div>
/// ```

class NgContentRef {
  final RenderView _renderView;
  final int _index;

  NgContentRef(this._renderView, this._index);

  /// Returns whether this has any projected nodes.
  // TODO(b/152626836): Update type of ProjectedNode into List<List<Object>>.
  bool get hasContent {
    final nodesToProject = (_renderView.projectedNodes[_index]) as List;
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
