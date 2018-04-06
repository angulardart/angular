/// An error thrown if application changes model breaking the top-down data flow.
///
/// This exception is only thrown in dev mode.
///
/// <!-- TODO: Add a link once the dev mode option is configurable -->
///
/// ### Example
///
/// ```typescript
/// @Component({
///   selector: 'parent',
///   template: `
///     <child [prop]="parentProp"></child>
///   `,
///   directives: [forwardRef(() => Child)]
/// })
/// class Parent {
///   parentProp = "init";
/// }
///
/// @Directive({selector: 'child', inputs: ['prop']})
/// class Child {
///   constructor(public parent: Parent) {}
///
///   set prop(v) {
///     // this updates the parent property, which is disallowed during change detection
///     // this will result in ExpressionChangedAfterItHasBeenCheckedException
///     this.parent.parentProp = "updated";
///   }
/// }
/// ```
class ExpressionChangedAfterItHasBeenCheckedException implements Exception {
  final String _message;

  ExpressionChangedAfterItHasBeenCheckedException(
      dynamic oldValue, dynamic currValue, dynamic context)
      : _message = "Expression has changed after it was checked. "
            "Previous value: '$oldValue'. Current value: '$currValue'";

  @override
  String toString() => _message;
}
