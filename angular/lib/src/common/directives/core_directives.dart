import 'ng_class.dart' show NgClass;
import 'ng_for.dart' show NgFor;
import 'ng_if.dart' show NgIf;
import 'ng_style.dart' show NgStyle;
import 'ng_switch.dart' show NgSwitch, NgSwitchWhen, NgSwitchDefault;
import 'ng_template_outlet.dart' show NgTemplateOutlet;

/// A collection of Angular core directives that are likely to be used in each
/// and every Angular application.
///
/// This collection can be used to quickly enumerate all the built-in directives
/// in the `directives` property of the `@Component` annotation.
///
/// ### Example
///
/// Instead of writing:
///
/// ```dart
/// import 'package:angular/common.dart'
///     show
///         NgClass,
///         NgIf,
///         NgFor,
///         NgSwitch,
///         NgSwitchWhen,
///         NgSwitchDefault;
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
/// import 'angular/common.dart' show CORE_DIRECTIVES;
/// import 'my_directives.dart' show OtherDirective;
///
/// @Component(
///     selector: 'my-component',
///     templateUrl: 'my_component.html',
///     directives: const [CORE_DIRECTIVES, OtherDirective])
/// class MyComponent {
///   ...
/// }
/// ```
const List<Type> CORE_DIRECTIVES = const [
  NgClass,
  NgFor,
  NgIf,
  NgTemplateOutlet,
  NgStyle,
  NgSwitch,
  NgSwitchWhen,
  NgSwitchDefault,
];
