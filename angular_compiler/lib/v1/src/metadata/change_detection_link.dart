import 'package:meta/meta.dart';

/// Used to annotate an "OnPush" component that may load "Default" components.
///
/// This can only be used to annotate a component that uses the "OnPush" change
/// detection strategy.
///
/// It should only be used for "OnPush" components that imperatively load
/// another component from a user provided `ComponentFactory`, which could use
/// the "Default" change detection strategy.
///
/// It should also only be used for common components that will be used in both
/// "Default" and "OnPush" contexts. If the component is only used in a single
/// app, consider migrating the components it loads to "OnPush" instead.
///
/// An annotated component serves as a link between a "Default" parent and any
/// imperatively loaded "Default" children during change detection. This link
/// allows the "Default" children to be change detected even when the annotated
/// component is skipped, thus honoring both of their change detection
/// contracts. A link may span multiple "OnPush" components, so long as each one
/// is annotated.
///
/// The following example demonstrates how this annotation may be used.
///
/// ```
/// @changeDetectionLink
/// @Component(
///   selector: 'example',
///   template: '<template #container></template>',
///   changeDetection: ChangeDetectionStrategy.OnPush,
/// )
/// class ExampleComponent {
///   @Input()
///   set componentFactory(ComponentFactory<Object> value) {
///     container.createComponent(value);
///   }
///
///   @ViewChild('container', read: ViewContainerRef)
///   ViewContainerRef container;
/// }
/// ```
///
/// This annotated component may be used by a "Default" component to
/// imperatively load another "Default" component via the `componentFactory`
/// input. Without this annotation, the imperatively loaded component would not
/// get updated during change detection when the annotated component is skipped
/// due to "OnPush" semantics.
@experimental
const changeDetectionLink = _ChangeDetectionLink();

class _ChangeDetectionLink {
  const _ChangeDetectionLink();
}
