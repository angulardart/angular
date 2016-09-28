import "package:angular2/src/core/di.dart" show OpaqueToken;

/// A token that can be provided when bootstraping an application to make an
/// array of directives available in every component of the application.
///
/// ### Example
///
/// ```dart
/// import 'package:angular2/core.dart' show PLATFORM_DIRECTIVES;
/// import './myDirectives' show OtherDirective;
///
/// @Component(
///     selector: 'my-component',
///     template: '''
///       <!-- can use other directive even though the component does not list it
///            in `directives` -->
///
///       <other-directive></other-directive>
///     ''')
/// class MyComponent {
///   ...
/// }
///
/// void main() {
///   bootstrap(MyComponent, [
///     provide(PLATFORM_DIRECTIVES, useValue: [OtherDirective], multi: true)
///   ]);
/// }
/// ```
///
const OpaqueToken PLATFORM_DIRECTIVES =
    const OpaqueToken("Platform Directives");

/// A token that can be provided when bootstraping an application to make an
/// array of pipes available in every component of the application.
///
/// ### Example
///
/// ```dart
/// import 'angular2/core' show PLATFORM_PIPES;
/// import './myPipe' show OtherPipe;
/// @Component(
///     selector: 'my-component',
///     template: '''
///     {{123 | other-pipe}}
///   ''')
/// class MyComponent {
///   ...
/// }
///
/// void main() {
///   bootstrap(MyComponent, [
///     provide(PLATFORM_PIPES, useValue: [OtherPipe], multi: true)
///   ]);
/// }
/// ```
///
const OpaqueToken PLATFORM_PIPES = const OpaqueToken("Platform Pipes");
