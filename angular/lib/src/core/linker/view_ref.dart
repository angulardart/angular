import 'dart:html';

/// An Angular view that can be created and destroyed dynamically.
///
/// A view is the fundamental building block of an Angular app. It's the
/// smallest grouping of HTML elements that are created and destroyed together.
///
/// The properties of elements in a view can change, but their structure (order
/// and number) can't. Changing the structure of elements can only be done by
/// inserting, moving, or removing instances of [ViewRef] in a view container
/// via `ViewContainerRef`. A view may contain any number of view containers.
///
/// This is the public interface which all dynamic views implement.
abstract class ViewRef {
  /// Whether this view has been destroyed.
  bool get destroyed;

  /// Registers a [callback] to invoke when this view is destroyed.
  void onDestroy(void Function() callback);
}

/// An embedded Angular view that can be created and destroyed dynamically.
///
/// An embedded view is instantiated from a `TemplateRef`, and can be inserted
/// into a `ViewContainerRef`.
///
/// This is the public interface which only generated embedded views implement.
/// It adds additional functionality to [ViewRef] that is specific to embedded
/// views, such as manipulating template local variables.
///
/// ### Example
///
/// Consider the following template:
///
/// ```
/// <ul>
///   <li *ngFor="let item of items">{{item}}</li>
/// </ul>
/// ```
///
/// Note the `*`-binding is just sugar for the following:
///
/// ```
/// <ul>
///   <template ngFor let-item [ngForOf]="items">
///     <!-- TemplateRef -->
///     <li>{{item}}</li>
///   </template>
/// </ul>
/// ```
///
/// In this example, `item` is a template input variable that is local to each
/// embedded view created from this template.
///
/// Given `items = ['First', 'Second']`, this example would render:
///
/// ```
/// <ul>
///   <!-- EmbeddedViewRef -->
///   <li>First</li>
///   <!-- EmbeddedViewRef -->
///   <li>Second</li>
/// </ul>
/// ```
///
/// Note how `ngFor` has used the `TemplateRef` to create an `EmbeddedViewRef`
/// for each item.
abstract class EmbeddedViewRef implements ViewRef {
  /// Sets the [value] of local variable called [name] in this view.
  ///
  /// This local variable will be assignable by [name] to a template input
  /// variable created with the `let` keyword.
  void setLocal(String name, dynamic value);

  /// Checks whether this view has a local variable called [name].
  bool hasLocal(String name);

  /// This view's root DOM nodes.
  List<Node> get rootNodes;

  /// Detaches this view and destroys all of its associated state.
  void destroy();

  /// Marks this view to be change detected in an "OnPush" context.
  void markForCheck();
}
