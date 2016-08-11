import "directives.dart" show CORE_DIRECTIVES;
import "forms.dart" show FORM_DIRECTIVES;

/// A collection of Angular core directives that are likely to be used in each
/// and every Angular application. This includes core directives
/// (e.g., NgIf and NgFor), and forms directives (e.g., NgModel).
///
/// This collection can be used to quickly enumerate all the built-in directives
/// in the `directives` property of the `@Component` annotation.
///
/// ### Example
///
/// Instead of writing:
///
/// ```dart
/// import 'package:angular2/common.dart'
///     show
///         NgClass,
///         NgIf,
///         NgFor,
///         NgSwitch,
///         NgSwitchWhen,
///         NgSwitchDefault,
///         NgModel,
///         NgForm;
/// import 'my_directives.dart' show OtherDirective;
///
/// @Component(
///     selector: 'my-component',
///     templateUrl: 'my_component.html',
///     directives: const [
///       NgClass,
///       NgIf,
///       NgFor,
///       NgSwitch,
///       NgSwitchWhen,
///       NgSwitchDefault,
///       NgModel,
///       NgForm,
///       OtherDirective
///     ])
/// class MyComponent {
///   ...
/// }
/// ```
///
/// One could import all the core directives at once:
///
/// ```dart
/// import 'angular2/common.dart' show COMMON_DIRECTIVES;
/// import 'my_directives.dart' show OtherDirective;
///
/// @Component(
///     selector: 'my-component',
///     templateUrl: 'my_component.html',
///     directives: const [COMMON_DIRECTIVES, OtherDirective])
/// class MyComponent {
///   ...
/// }
/// ```
const List<List<Type>> COMMON_DIRECTIVES = const [
  CORE_DIRECTIVES,
  FORM_DIRECTIVES
];
